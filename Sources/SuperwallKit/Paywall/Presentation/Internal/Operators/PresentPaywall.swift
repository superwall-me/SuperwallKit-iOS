//
//  File.swift
//  
//
//  Created by Yusuf Tör on 11/05/2023.
//

import UIKit
import Combine

extension Superwall {
  /// Presents the paywall view controller, stores the presentation request for future use,
  /// and sends back a `presented` state to the paywall state publisher.
  ///
  /// - Parameters:
  ///   - paywallStatePublisher: A `PassthroughSubject` that gets sent ``PaywallState`` objects.
  ///   - presenter: The view controller to present that paywall on.
  ///   - unsavedOccurrence: The audience occurrence to save, if available.
  ///   - debugInfo: Information to help with debugging.
  ///   - request: The request to present the paywall.
  ///   - paywallStatePublisher: A `PassthroughSubject` that gets sent ``PaywallState`` objects.
  ///
  /// - Returns: A publisher that contains info for the next pipeline operator.
  @MainActor
  func presentPaywallViewController(
    _ paywallViewController: PaywallViewController,
    on presenter: UIViewController,
    unsavedOccurrence: TriggerAudienceOccurrence?,
    debugInfo: [String: Any],
    request: PresentationRequest,
    paywallStatePublisher: PassthroughSubject<PaywallState, Never>
  ) async throws {
    let presentationRequest = InternalSuperwallPlacement.PresentationRequest(
      placementData: request.presentationInfo.placementData,
      type: request.flags.type,
      status: .presentation,
      statusReason: nil,
      factory: self.dependencyContainer
    )
    await self.track(presentationRequest)

    try await withCheckedThrowingContinuation { continuation in
      paywallViewController.present(
        on: presenter,
        request: request,
        unsavedOccurrence: unsavedOccurrence,
        presentationStyleOverride: request.paywallOverrides?.presentationStyle,
        paywallStatePublisher: paywallStatePublisher
      ) { isPresented in
        if isPresented {
          let state: PaywallState = .presented(paywallViewController.info)
          paywallStatePublisher.send(state)
          continuation.resume()
        } else {
          Logger.debug(
            logLevel: .info,
            scope: .paywallPresentation,
            message: "Paywall Already Presented",
            info: debugInfo
          )
          let error = InternalPresentationLogic.presentationError(
            domain: "SWKPresentationError",
            code: 102,
            title: "Paywall Already Presented",
            value: "Trying to present paywall while another paywall is presented."
          )
          paywallStatePublisher.send(.presentationError(error))
          paywallStatePublisher.send(completion: .finished)
          continuation.resume(with: .failure(PresentationPipelineError.paywallAlreadyPresented))
        }
      }
    }
  }
}
