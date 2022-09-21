//
//  File.swift
//  
//
//  Created by Yusuf Tör on 12/08/2022.
//

import Combine




class TriggerDelayManager {
  static let shared = TriggerDelayManager()
  /// Returns `true` if config doesn't exist yet.
  var hasDelay: Bool {
    let configUnavailable = ConfigManager.shared.config == nil
    var blockingAssignmentWaiting = false
    if let preConfigAssignmentCall = preConfigAssignmentCall {
      blockingAssignmentWaiting = preConfigAssignmentCall.isBlocking
    }
    return configUnavailable || blockingAssignmentWaiting
  }
  private(set) var triggersFiredPreConfig: [PreConfigTrigger] = []

  private var cancellable: AnyCancellable?


  init() {
    waitToFireDelayedTriggers()
  }

  func waitToFireDelayedTriggers() {
    cancellable = ConfigManager.shared.$config
      .zip(IdentityManager.shared.identityPublisher)
      .sink { completion in
        if completion == .finished {
          self.fireDelayedTriggers()
        }
      } receiveValue: { _ in }
  }

  func handleDelayedContent(
    storage: Storage = .shared,
    configManager: ConfigManager = .shared
  ) async {
    // If the user has called identify with a diff ID, we call reset.
    // Then we wait until config has returned before identifying again.
    //if let appUserIdAfterReset = appUserIdAfterReset {
      //TODO: FIGURE THIS OUT
      //    storage.identify(with: appUserIdAfterReset)
    //}
  }

  func fireDelayedTriggers(
    storage: Storage = .shared,
    paywall: Paywall = .shared
  ) {
    triggersFiredPreConfig.forEach { trigger in
      switch trigger.presentationInfo.triggerType {
      case .implicit:
        guard let eventData = trigger.presentationInfo.eventData else {
          return
        }
        paywall.handleImplicitTrigger(forEvent: eventData)
      case .explicit:
        Paywall.internallyPresent(
          trigger.presentationInfo,
          paywallOverrides: trigger.paywallOverrides,
          paywallState: trigger.paywallState
        )
      }
    }
    clearPreConfigTriggers()
  }

  func cachePreConfigTrigger(_ trigger: PreConfigTrigger) {
    triggersFiredPreConfig.append(trigger)
  }

  func clearPreConfigTriggers() {
    triggersFiredPreConfig.removeAll()
  }
}
