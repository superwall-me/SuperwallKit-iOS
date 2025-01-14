//
//  File.swift
//  
//
//  Created by Yusuf Tör on 03/03/2023.
//

import Foundation

enum GetPresentationResultLogic {
  /// Converts a ``TriggerResult`` to a ``PresentationResult``
  static func convertTriggerResult(_ triggerResult: InternalTriggerResult) -> PresentationResult {
    switch triggerResult {
    case .placementNotFound:
      return .placementNotFound
    case .holdout(let experiment):
      return .holdout(experiment)
    case .error:
      return .paywallNotAvailable
    case .noAudienceMatch:
      return .noAudienceMatch
    case .paywall(let experiment):
      return .paywall(experiment)
    }
  }
}
