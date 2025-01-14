//
//  File.swift
//  
//
//  Created by Yusuf Tör on 14/08/2024.
//

import Foundation

struct ExpressionLogic {
  unowned let storage: Storage

  func tryToMatchOccurrence(
    from audience: TriggerRule,
    expressionMatched: Bool
  ) async -> TriggerAudienceOutcome {
    if expressionMatched {
      guard let occurrence = audience.occurrence else {
        Logger.debug(
          logLevel: .debug,
          scope: .paywallPresentation,
          message: "No occurrence parameter found for trigger rule."
        )

        return .match(audience: audience)
      }

      let count = await storage
        .coreDataManager
        .countAudienceOccurrences(
          for: occurrence
        ) + 1
      let shouldFire = count <= occurrence.maxCount
      var unsavedOccurrence: TriggerAudienceOccurrence?

      if shouldFire {
        unsavedOccurrence = occurrence
        return .match(audience: audience, unsavedOccurrence: unsavedOccurrence)
      } else {
        return .noMatch(source: .occurrence, experimentId: audience.experiment.id)
      }
    }

    return .noMatch(source: .expression, experimentId: audience.experiment.id)
  }
}
