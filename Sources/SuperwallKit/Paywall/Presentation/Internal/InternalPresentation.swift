//
//  InternalPaywallPresentation.swift
//  Superwall
//
//  Created by Yusuf Tör on 04/03/2022.
//

import UIKit
import Combine

/// A CurrentValueSubject that emits `PresentationRequest` objects.
typealias PresentationSubject = CurrentValueSubject<PresentationRequest, Error>

/// A publisher that emits ``PaywallState`` objects.
public typealias PaywallStatePublisher = AnyPublisher<PaywallState, Never>
typealias PresentablePipelineOutputPublisher = AnyPublisher<PresentablePipelineOutput, Error>

extension Superwall {
  /// Runs a background task to present a paywall, publishing ``PaywallState`` objects that provide updates on the lifecycle of the paywall.
  ///
  /// - Parameters:
  ///   - request: A presentation request of type `PresentationRequest` to feed into a presentation pipeline.
  ///   - paywallStatePublisher: A publisher fed into the pipeline that sends state updates.
  func internallyPresent(
    _ request: PresentationRequest,
    _ publisher: PassthroughSubject<PaywallState, Never>
  ) async {
    do {
      try await checkNoPaywallAlreadyPresented(request, publisher)

      let paywallComponents = try await getPaywallComponents(request, publisher)

      guard let presenter = paywallComponents.presenter else {
        // Will never get here as an error would have already been thrown.
        return
      }

      try await presentPaywallViewController(
        paywallComponents.viewController,
        on: presenter,
        unsavedOccurrence: paywallComponents.audienceOutcome.unsavedOccurrence,
        debugInfo: paywallComponents.debugInfo,
        request: request,
        paywallStatePublisher: publisher
      )
    } catch {
      logErrors(from: request, error)
    }
  }

  @MainActor
  func dismiss(
    _ paywallViewController: PaywallViewController,
    result: PaywallResult,
    closeReason: PaywallCloseReason = .systemLogic,
    completion: (() -> Void)? = nil
  ) {
    paywallViewController.dismiss(
      result: result,
      closeReason: closeReason
    ) {
      completion?()
    }
  }
}
