//
//  File.swift
//  
//
//  Created by brian on 8/16/21.
//

import UIKit
import Combine

/// Sends n analytical events to the Superwall servers every 20 seconds, where n is defined by `maxEventCount`.
///
/// **Note**: this currently has a limit of 500 events per flush.
actor PlacementsQueue {
  private let maxEventCount = 50
  private var elements: [JSON] = []
  private var timer: Timer?
  private unowned let network: Network
  private unowned let configManager: ConfigManager

  @MainActor
  private var resignActiveObserver: AnyCancellable?

  deinit {
    timer?.invalidate()
    timer = nil
  }

  init(
    network: Network,
    configManager: ConfigManager
  ) {
    self.network = network
    self.configManager = configManager
    Task { [weak self] in
      await self?.setupTimer()
      await self?.addObserver()
    }
  }

  private func setupTimer() {
    let timeInterval: Double
    switch configManager.options.networkEnvironment {
    case .release:
      timeInterval = 20.0
    default:
      timeInterval = 1.0
    }
    let timer = Timer(
      timeInterval: timeInterval,
      repeats: true
    ) { [weak self] _ in
      guard let self = self else {
        return
      }
      Task {
        await self.flushInternal()
      }
    }
    self.timer = timer
    RunLoop.main.add(timer, forMode: .default)
  }

  @MainActor
  private func addObserver() async {
    resignActiveObserver = NotificationCenter.default
      .publisher(for: UIApplication.willResignActiveNotification)
      .sink { [weak self] _ in
        Task {
          await self?.flushInternal()
        }
      }
  }

  func enqueue(
    data: JSON,
    from placement: Trackable
  ) {
    guard externalDataCollectionAllowed(from: placement) else {
      return
    }
    elements.append(data)
  }

  private func externalDataCollectionAllowed(from placement: Trackable) -> Bool {
    if Superwall.shared.options.isExternalDataCollectionEnabled {
      return true
    }
    if placement is InternalSuperwallPlacement.TriggerFire
      || placement is InternalSuperwallPlacement.Attributes
      || placement is UserInitiatedPlacement.Track {
      return false
    }
    return true
  }

  func flushInternal(depth: Int = 10) {
    var eventsToSend: [JSON] = []

    var i = 0
    while i < maxEventCount && !elements.isEmpty {
      eventsToSend.append(elements.removeFirst())
      i += 1
    }

    if !eventsToSend.isEmpty {
      // Send to network
      let events = EventsRequest(events: eventsToSend)
      Task { await network.sendEvents(events: events) }
    }

    if !elements.isEmpty && depth > 0 {
      return flushInternal(depth: depth - 1)
    }
  }
}
