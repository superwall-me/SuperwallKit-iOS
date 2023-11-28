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
actor EventsQueue {
  private let maxEventCount = 50
  private var elements: [JSON] = []
  private var timer: Timer?

  private let factory: DependencyContainer

  private var network: Network {
    return factory.network
  }

  private var configManager: ConfigManager {
    return factory.configManager
  }

  @MainActor
  private var resignActiveObserver: AnyCancellable?

  deinit {
    timer?.invalidate()
    timer = nil
  }

  init(factory: DependencyContainer) {
    self.factory = factory
    Task { [weak self] in
      await self?.setupTimer()
      await self?.addObserver()
    }
  }

  private func setupTimer() {
    let timeInterval = configManager.options.networkEnvironment == .release ? 20.0 : 1.0
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

  func enqueue(event: JSON) {
    elements.append(event)
  }

  private func externalDataCollectionAllowed(from event: Trackable) -> Bool {
    if Superwall.shared.options.isExternalDataCollectionEnabled {
      return true
    }
    if event is InternalSuperwallEvent.TriggerFire
      || event is InternalSuperwallEvent.Attributes
      || event is UserInitiatedEvent.Track {
      return false
    }
    return true
  }

  private func flushInternal(depth: Int = 10) {
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
