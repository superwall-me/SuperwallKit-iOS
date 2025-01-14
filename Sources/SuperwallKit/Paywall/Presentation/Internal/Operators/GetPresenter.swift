//
//  File.swift
//  
//
//  Created by Yusuf Tör on 11/05/2023.
//
// swiftlint:disable strict_fileprivate

import UIKit
import Combine

struct PresentablePipelineOutput {
  let debugInfo: [String: Any]
  let paywallViewController: PaywallViewController
  let presenter: UIViewController
  let confirmableAssignment: ConfirmableAssignment?
}

extension Superwall {
  /// Checks conditions for whether the paywall can present before accessing a window on
  /// which the paywall can present.
  ///
  /// - Parameters:
  ///   - paywallViewController: The ``PaywallViewController`` to present.
  ///   - audienceOutcome: The output from evaluating audience filters.
  ///   - request: The presentation request.
  ///   - debugInfo: Info used to print debug logs.
  ///   - paywallStatePublisher: A `PassthroughSubject` that gets sent ``PaywallState`` objects.
  ///
  /// - Returns: A `UIViewController`to present on.
  @discardableResult
  func getPresenterIfNecessary(
    for paywallViewController: PaywallViewController,
    audienceOutcome: AudienceFilterEvaluationOutcome,
    request: PresentationRequest,
    debugInfo: [String: Any],
    paywallStatePublisher: PassthroughSubject<PaywallState, Never>? = nil
  ) async throws -> UIViewController? {
    switch request.flags.type {
    case .getPaywall:
      await attemptTriggerFire(
        for: request,
        triggerResult: audienceOutcome.triggerResult
      )
      return nil
    case .handleImplicitTrigger,
      .paywallDeclineCheck,
      .getPresentationResult,
      .confirmAllAssignments:
      // We do not track trigger fire for these events (which would result in .paywall)
      return nil
    case .presentation:
      break
    }

    if request.presenter == nil {
      await createPresentingWindowIfNeeded()
    }

    // Make sure there's a presenter. If there isn't throw an error if no paywall is being presented
    let providedViewController = request.presenter
    let rootViewController = await Superwall.shared.presentationItems.window?.rootViewController

    guard let presenter = (providedViewController ?? rootViewController) else {
      Logger.debug(
        logLevel: .error,
        scope: .paywallPresentation,
        message: "No Presenter To Present Paywall",
        info: debugInfo
      )

      let error = InternalPresentationLogic.presentationError(
        domain: "SWKPresentationError",
        code: 103,
        title: "No UIViewController to present paywall on",
        value: "This usually happens when you call this method before a window was made key and visible."
      )
      let state: PaywallState = .presentationError(error)
      paywallStatePublisher?.send(state)
      paywallStatePublisher?.send(completion: .finished)
      throw PresentationPipelineError.noPresenter
    }

    await attemptTriggerFire(
      for: request,
      triggerResult: audienceOutcome.triggerResult
    )

    return presenter
  }

  func attemptTriggerFire(
    for request: PresentationRequest,
    triggerResult: InternalTriggerResult
  ) async {
    guard let placementName = request.presentationInfo.placementName else {
      // The paywall is being presented by identifier, which is what the debugger uses and that's not supported.
      return
    }
    switch request.presentationInfo {
    case .implicitTrigger,
      .explicitTrigger:
      switch triggerResult {
      case .error,
        .placementNotFound:
        return
      default:
        break
      }
    case .fromIdentifier:
      break
    }

    let triggerFire = InternalSuperwallPlacement.TriggerFire(
      triggerResult: triggerResult,
      triggerName: placementName
    )
    await Superwall.shared.track(triggerFire)
  }

  @MainActor
  fileprivate func createPresentingWindowIfNeeded() {
    guard presentationItems.window == nil else {
      return
    }
    let activeWindow = UIApplication.shared.activeWindow
    var presentingWindow: UIWindow?

    if let windowScene = activeWindow?.windowScene {
      presentingWindow = UIWindow(windowScene: windowScene)
    }

    presentingWindow?.rootViewController = UIViewController()
    presentationItems.window = presentingWindow
  }

  @MainActor
  func destroyPresentingWindow() {
    presentationItems.window?.windowScene = nil
    presentationItems.window = nil
  }
}
