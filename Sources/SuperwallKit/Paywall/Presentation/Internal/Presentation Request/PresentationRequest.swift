//
//  File.swift
//  
//
//  Created by Yusuf Tör on 23/09/2022.
//

import UIKit
import Combine

enum PresentationRequestType: Equatable, CustomStringConvertible {
  /// Presenting via ``Superwall/register(event:params:handler:feature:)``.
  case presentation

  /// Get the paywall view controller via
  /// ``Superwall/getPaywall(forEvent:params:paywallOverrides:delegate:)``.
  case getPaywall(PaywallViewControllerDelegateAdapter)

  /// Get the presentation result via ``Superwall/getPresentationResult(forEvent:)``
  case getPresentationResult

  /// Get the presentation result from an event that's used internally.
  case handleImplicitTrigger

  /// Get the presentation result for a `paywall_decline` event to decide whether to
  /// close the paywall view controller or not.
  case paywallDeclineCheck

  var isGettingPresentationResult: Bool {
    switch self {
    case .presentation,
      .getPaywall:
      return false
    case .getPresentationResult,
      .handleImplicitTrigger,
      .paywallDeclineCheck:
      return true
    }
  }

  var shouldConfirmAssignments: Bool {
    switch self {
    case .presentation,
      .getPaywall,
      .getPresentationResult,
      .handleImplicitTrigger:
      return true
    case .paywallDeclineCheck:
      return false
    }
  }

  var description: String {
    switch self {
    case .presentation:
      return "presentation"
    case .getPaywall:
      return "getPaywallViewController"
    case .getPresentationResult:
      return "getPresentationResult"
    case .handleImplicitTrigger,
      .paywallDeclineCheck:
      return "getImplicitPresentationResult"
    }
  }

  func getPaywallVcDelegateAdapter() -> PaywallViewControllerDelegateAdapter? {
    switch self {
    case .getPaywall(let adapter):
      return adapter
    default:
      return nil
    }
  }

  func hasObjcDelegate() -> Bool {
    switch self {
    case .getPaywall(let adapter):
      return adapter.hasObjcDelegate
    default:
      return false
    }
  }

  static func == (lhs: PresentationRequestType, rhs: PresentationRequestType) -> Bool {
    switch (lhs, rhs) {
    case (.handleImplicitTrigger, .handleImplicitTrigger),
      (.paywallDeclineCheck, .paywallDeclineCheck),
      (.getPresentationResult, .getPresentationResult),
      (.presentation, .presentation),
      (.getPaywall, .getPaywall):
      return true
    default:
      return false
    }
  }
}

/// Defines the information needed to request the presentation of a paywall.
struct PresentationRequest {
  /// The type of trigger (implicit/explicit/fromIdentifier), and associated data.
  let presentationInfo: PresentationInfo

  /// The view controller to present the paywall on, if any.
  var presenter: UIViewController?

  /// Overrides the default behavior and products of a paywall.
  var paywallOverrides: PaywallOverrides?

  /// The source function type that initiated the presentation request.
  var presentationSourceType: String? {
    switch presentationInfo {
    case .implicitTrigger:
      return "implicit"
    case .explicitTrigger,
      .fromIdentifier:
      switch flags.type {
      case .getPaywall:
        return "getPaywall"
      case .presentation:
        return "register"
      case .paywallDeclineCheck,
        .handleImplicitTrigger,
        .getPresentationResult:
        return nil
      }
    }
  }

  struct Flags {
    var isDebuggerLaunched: Bool
    // TODO: Check if we can just use entitlements  (as that contains didSetActiveEntitlements)
    var didSetActiveEntitlements: AnyPublisher<Bool, Never>
    var entitlements: EntitlementsInfo
    var isPaywallPresented: Bool
    var type: PresentationRequestType
  }
  var flags: Flags

  /// A `Just` publisher that that emits the request object once and finishes.
  var publisher: AnyPublisher<Self, Error> {
    Just(self)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
  }
}

extension PresentationRequest: Stubbable {
  // Note: If making a stub in a test and needing to change things like
  // configManager, this may not work because the original one will be
  // deallocated and cause a crash. You'll need to create the request yourself.
  static func stub() -> PresentationRequest {
    let dependencyContainer = DependencyContainer()
    return dependencyContainer.makePresentationRequest(
      .explicitTrigger(.stub()),
      paywallOverrides: nil,
      isDebuggerLaunched: false,
      isPaywallPresented: false,
      type: .presentation
    )
  }
}
