//
//  File.swift
//  
//
//  Created by Yusuf Tör on 11/05/2023.
//

import Foundation

extension Superwall {
  /// Evaluates the audience filters from the campaign that the placement belongs to.
  ///
  /// - Parameter request: The presentation request
  /// - Returns: An `AudienceFilterEvaluationOutcome` object containing the trigger result,
  /// confirmable assignment, and unsaved occurrence.
  func evaluateAudienceFilter(
    from request: PresentationRequest
  ) async throws -> AudienceFilterEvaluationOutcome {
    if let placementData = request.presentationInfo.placementData {
      let audienceLogic = AudienceLogic(
        configManager: dependencyContainer.configManager,
        storage: dependencyContainer.storage,
        factory: dependencyContainer
      )
      return await audienceLogic.evaluateAudienceFilters(
        forPlacement: placementData,
        triggers: dependencyContainer.configManager.triggersByPlacementName
      )
    } else {
      // Called if the debugger is shown.
      guard let paywallId = request.presentationInfo.identifier else {
        // This error will never be thrown. Just preferring this
        // to force unwrapping.
        throw PresentationPipelineError.noPaywallViewController
      }
      return AudienceFilterEvaluationOutcome(
        triggerResult: .paywall(.presentById(paywallId))
      )
    }
  }
}
