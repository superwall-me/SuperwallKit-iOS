//
//  File.swift
//  
//
//  Created by Yusuf Tör on 11/05/2023.
//

import Foundation
import Combine

extension Superwall {
  /// Switches over the trigger result. Continues if a paywall will show.
  /// Otherwise, if applicable, it sends a `skipped` state to the paywall state publisher and returns.
  ///
  /// - Parameters:
  ///   - request: The `PresentationRequest`.
  ///   - audienceOutcome: The output from evaluating the audience filters.
  ///   - debugInfo: Information to help with debugging.
  ///   - paywallStatePublisher: A `PassthroughSubject` that gets sent ``PaywallState`` objects.
  ///
  /// - Returns: A struct that contains info for the next operation.
  func getExperiment(
    request: PresentationRequest,
    audienceOutcome: AudienceFilterEvaluationOutcome,
    debugInfo: [String: Any],
    paywallStatePublisher: PassthroughSubject<PaywallState, Never>? = nil,
    storage: Storage
  ) async throws -> Experiment {
    let errorType: PresentationPipelineError

    switch audienceOutcome.triggerResult {
    case .paywall(let experiment):
      return experiment
    case .holdout(let experiment):
      await attemptTriggerFire(request: request, audienceOutcome: audienceOutcome)
      if let unsavedOccurrence = audienceOutcome.unsavedOccurrence {
        storage.coreDataManager.save(triggerAudienceOccurrence: unsavedOccurrence)
      }
      errorType = .holdout(experiment)
      paywallStatePublisher?.send(.skipped(.holdout(experiment)))
    case .noAudienceMatch:
      await attemptTriggerFire(request: request, audienceOutcome: audienceOutcome)
      errorType = .noAudienceMatch
      paywallStatePublisher?.send(.skipped(.noAudienceMatch))
    case .placementNotFound:
      errorType = .placementNotFound
      paywallStatePublisher?.send(.skipped(.placementNotFound))
    case let .error(error):
      if request.flags.type.isGettingPresentationResult {
        Logger.debug(
          logLevel: .error,
          scope: .paywallPresentation,
          message: "Error Getting Paywall View Controller",
          info: debugInfo,
          error: error
        )
      }
      errorType = .noPaywallViewController
      paywallStatePublisher?.send(.presentationError(error))
    }

    paywallStatePublisher?.send(completion: .finished)
    throw errorType
  }

  private func attemptTriggerFire(
    request: PresentationRequest,
    audienceOutcome: AudienceFilterEvaluationOutcome
  ) async {
    guard request.flags.type.shouldConfirmAssignments else {
      return
    }

    await attemptTriggerFire(
      for: request,
      triggerResult: audienceOutcome.triggerResult
    )
  }
}
