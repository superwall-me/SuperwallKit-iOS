//
//  File.swift
//  
//
//  Created by Yusuf Tör on 06/08/2024.
//

import Foundation
import Combine

/// A class that handles the `Set` of ``Entitlement`` objects retrieved from
/// the Superwall dashboard.
@objc(SWKEntitlementsInfo)
@objcMembers
public final class EntitlementsInfo: NSObject, ObservableObject, @unchecked Sendable {
  // MARK: - Public vars
  /// All entitlements, regardless of whether they're active or not.
  public private(set) var all: Set<Entitlement> {
    get {
      return queue.sync {
        return backingAll
      }
    }
    set {
      queue.async {
        self.backingAll = newValue
      }
    }
  }

  /// The inactive entitlements.
  public var inactive: Set<Entitlement> {
    return queue.sync {
      return backingAll.subtracting(backingActive)
    }
  }

  /// The active entitlements.
  public var active: Set<Entitlement> {
    return queue.sync {
      return backingActive
    }
  }

  /// A published property that indicates the entitlement status of the user. If you're using a
  /// `PurchaseController`, you must set this.
  ///
  /// If you're using Combine or SwiftUI, you can subscribe or bind to it to get
  /// notified whenever it changes.
  ///
  /// Otherwise, you can check the delegate function
  /// ``SuperwallDelegate/entitlementStatusDidChange(from:to:)``
  /// to receive a callback every time it changes.
  @Published public var status: EntitlementStatus = .unknown {
    didSet {
      if case let .active(entitlements) = status {
        if entitlements.isEmpty {
          status = .inactive
          return
        }
      }
      queue.async { [weak self] in
        guard let self = self else {
          return
        }
        switch self.status {
        case .active(let entitlements):
          self.backingActive = entitlements
        default:
          self.backingActive = []
        }
      }
    }
  }

  // MARK: - Internal vars
  /// The entitlements that belong to each product ID.
  var entitlementsByProductId: [String: Set<Entitlement>] = [:] {
    didSet {
      storage.save(entitlementsByProductId, forType: EntitlementsByProductId.self)
      self.all = Set(entitlementsByProductId.values.joined())
    }
  }

  // MARK: - Private vats
  /// The backing variable for ``EntitlementsInfo/active``.
  private var backingActive: Set<Entitlement> = []

  /// The backing variable for ``EntitlementsInfo/all``.
  private var backingAll: Set<Entitlement> = []

  private unowned let storage: Storage
  private unowned let delegateAdapter: SuperwallDelegateAdapter
  private let queue = DispatchQueue(label: "com.superwall.entitlementsinfo.queue")

  init(
    storage: Storage,
    delegateAdapter: SuperwallDelegateAdapter,
    isTesting: Bool = false
  ) {
    self.storage = storage
    self.delegateAdapter = delegateAdapter
    super.init()
    if isTesting {
      return
    }

    let storedStatus = self.storage.get(EntitlementStatusKey.self) ?? .unknown
    self.status = storedStatus

    DispatchQueue.main.async {
      self.listenToEntitlementStatus()
    }

    queue.sync { [weak self] in
      guard let self = self else {
        return
      }
      entitlementsByProductId = self.storage.get(EntitlementsByProductId.self) ?? [:]

      if case let .active(activeEntitlements) = storedStatus {
        backingActive = activeEntitlements
      } else {
        backingActive = []
      }

      backingAll = Set(entitlementsByProductId.values.joined())
    }
  }

  // MARK: - Public API

  /// Returns a `Set` of ``Entitlement``s belonging to a given `productId`.
  ///
  /// - Parameter productId: A `String` representing a `productId`
  /// - Returns: A `Set` of ``Entitlement``s
  public func byProductId(_ productId: String) -> Set<Entitlement> {
    return queue.sync {
      entitlementsByProductId[productId] ?? []
    }
  }

  // MARK: - Objc API

  /// Returns the entitlement status of the user.
  ///
  /// Check the delegate function
  /// ``SuperwallDelegateObjc/entitlementStatusDidChange(from:to:)``
  /// to receive a callback every time it changes.
  @available(swift, obsoleted: 1.0)
  public func getStatus() -> EntitlementStatusObjc {
    return status.toObjc()
  }

  /// Sets ``EntitlementsInfo/status`` to an`unknown` state.
  @available(swift, obsoleted: 1.0)
  public func setUnknownStatus() {
    status = .unknown
  }

  /// Sets ``EntitlementsInfo/status`` to an`inactive` state.
  @available(swift, obsoleted: 1.0)
  public func setInactiveStatus() {
    status = .inactive
  }

  /// Sets ``EntitlementsInfo/status`` to an`active` state with the
  /// specified entitlements.
  @available(swift, obsoleted: 1.0)
  public func setActiveStatus(with entitlements: Set<Entitlement>) {
    status = .active(entitlements)
  }

  // MARK: - Private API

  func setEntitlementsFromConfig(_ entitlementsByProductId: [String: Set<Entitlement>]) {
    queue.async { [weak self] in
      guard let self = self else {
        return
      }
      self.entitlementsByProductId = entitlementsByProductId
    }
  }

  private func listenToEntitlementStatus() {
    $status
      .removeDuplicates()
      .dropFirst()
      .scan((previous: status, current: status)) { previousPair, newStatus in
        // Shift the current value to previous, and set the new status as the current value
        (previous: previousPair.current, current: newStatus)
      }
      .receive(on: DispatchQueue.main)
      .subscribe(Subscribers.Sink(
        receiveCompletion: { _ in },
        receiveValue: { [weak self] statusPair in
          guard let self = self else {
            return
          }
          let oldStatus = statusPair.previous
          let newStatus = statusPair.current

          self.storage.save(newStatus, forType: EntitlementStatusKey.self)

          Task {
            await self.delegateAdapter.entitlementStatusDidChange(from: oldStatus, to: newStatus)
            let event = InternalSuperwallPlacement.EntitlementStatusDidChange(status: newStatus)
            await Superwall.shared.track(event)
          }
        }
      ))
  }
}
