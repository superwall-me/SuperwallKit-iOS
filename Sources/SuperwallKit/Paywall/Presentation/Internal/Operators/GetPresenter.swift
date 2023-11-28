//
//  File.swift
//  
//
//  Created by Yusuf Tör on 11/05/2023.
//
// swiftlint:disable strict_fileprivate function_body_length

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
  ///   - rulesOutput: The output from evaluating rules.
  ///   - request: The presentation request.
  ///   - debugInfo: Info used to print debug logs.
  ///   - paywallStatePublisher: A `PassthroughSubject` that gets sent ``PaywallState`` objects.
  ///
  /// - Returns: A `UIViewController`to present on.
  @discardableResult
  func getPresenterIfNecessary(
    for paywallViewController: PaywallViewController,
    rulesOutcome: RuleEvaluationOutcome,
    request: PresentationRequest,
    debugInfo: [String: Any],
    paywallStatePublisher: PassthroughSubject<PaywallState, Never>? = nil
  ) async throws -> UIViewController? {
    let subscriptionStatus = try await request.flags.subscriptionStatus.throwableAsync()
    if await InternalPresentationLogic.userSubscribedAndNotOverridden(
      isUserSubscribed: subscriptionStatus == .active,
      overrides: .init(
        isDebuggerLaunched: request.flags.isDebuggerLaunched,
        shouldIgnoreSubscriptionStatus: request.paywallOverrides?.ignoreSubscriptionStatus,
        presentationCondition: paywallViewController.paywall.presentation.condition
      )
    ) {
      let state: PaywallState = .skipped(.userIsSubscribed)
      paywallStatePublisher?.send(state)
      paywallStatePublisher?.send(completion: .finished)
      throw PresentationPipelineError.userIsSubscribed
    }

    switch request.flags.type {
    case .getPaywall:
      let sessionId = await activateSession(
        for: request,
        paywall: paywallViewController.paywall,
        triggerResult: rulesOutcome.triggerResult
      )
      await MainActor.run {
        paywallViewController.paywall.triggerSessionId = sessionId
      }
      return nil
    case .getImplicitPresentationResult,
      .getPresentationResult:
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
        info: debugInfo,
        error: nil
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

    let sessionId = await activateSession(
      for: request,
      paywall: paywallViewController.paywall,
      triggerResult: rulesOutcome.triggerResult
    )

    await MainActor.run {
      paywallViewController.paywall.triggerSessionId = sessionId
    }

    return presenter
  }

  private func activateSession(
    for request: PresentationRequest,
    paywall: Paywall,
    triggerResult: InternalTriggerResult
  ) async -> String? {
    let sessionEventsManager = dependencyContainer.sessionEventsManager
    return await sessionEventsManager.triggerSession.activateSession(
      for: request.presentationInfo,
      on: request.presenter,
      paywall: paywall,
      triggerResult: triggerResult
    )
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
    presentationItems.window = nil
  }
}
