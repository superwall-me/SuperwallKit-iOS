//
//  File.swift
//
//
//  Created by Jake Mor on 10/9/21.
//

import Combine
import Foundation
import UIKit

extension Superwall {
  // MARK: - Dismiss
  /// Dismisses the presented paywall.
  ///
  /// - Parameter completion: An optional completion block that gets called after the paywall is dismissed.
  /// Defaults to `nil`.
  @objc public func dismiss(completion: (() -> Void)? = nil) {
    Task { [weak self] in
      await self?.dismiss()
      completion?()
    }
  }

  /// Objective-C-only method. Dismisses the presented paywall.
  @available(swift, obsoleted: 1.0)
  @objc public func dismiss() {
    Task { [weak self] in
      await self?.dismiss()
    }
  }

  /// Dismisses the presented paywall, if one exists.
  @MainActor
  @nonobjc
  public func dismiss() async {
    guard let paywallViewController = paywallViewController else {
      return
    }
    await withCheckedContinuation { continuation in
      dismiss(
        paywallViewController,
        result: .declined
      ) {
        continuation.resume()
      }
    }
  }

  /// Dismisses the presented paywall, if it exists, in order to present a different one.
  @MainActor
  func dismissForNextPaywall() async {
    guard let paywallViewController = paywallViewController else {
      return
    }

    await withCheckedContinuation { continuation in
      dismiss(
        paywallViewController,
        result: .declined,
        closeReason: .forNextPaywall
      ) {
        continuation.resume()
      }
    }
  }

  // MARK: - Register

  /// Registers a placement to access a feature. When the placement is added to a campaign on the Superwall dashboard, it can show a paywall.
  ///
  /// This shows a paywall to the user when: A placement you provide is added to a campaign on the [Superwall Dashboard](https://superwall.com/dashboard); the user matches an audience filter in the campaign; and the user doesn't have an active subscription.
  ///
  /// Before using this method, you'll first need to create a campaign and add the placement to the campaign on the [Superwall Dashboard](https://superwall.com/dashboard).
  ///
  /// The paywall shown to the user is determined by the audience filters defined in the campaign. When a user is assigned a paywall within an audience, they will continue to see that paywall unless you remove the paywall from the audience or reset assignments to the paywall.
  ///
  /// - Parameters:
  ///   -  placement: The name of the placement you wish to register.
  ///   - params: Optional parameters you'd like to pass with your placement. These can be referenced within the audience filters of your campaign. Keys beginning with `$` are reserved for Superwall and will be dropped. Values can be any JSON encodable value, URLs or Dates. Arrays and dictionaries as values are not supported at this time, and will be dropped. Defaults to `nil`.
  ///   - handler: An optional handler whose functions provide status updates for a paywall. Defaults to `nil`.
  ///   - feature: A completion block containing a feature that you wish to paywall. Access to this block is remotely configurable via the [Superwall Dashboard](https://superwall.com/dashboard). If the paywall is set to _Non Gated_, this will be called when the paywall is dismissed or if the user is already paying. If the paywall is _Gated_, this will be called only if the user is already paying or if they begin paying. If no paywall is configured, this gets called immediately. This will not be called in the event of an error, which you can detect via the `handler`.
  public func register(
    placement: String,
    params: [String: Any]? = nil,
    handler: PaywallPresentationHandler? = nil,
    feature: @escaping () -> Void
  ) {
    internallyRegister(
      placement: placement,
      params: params,
      handler: handler,
      feature: feature
    )
  }

  /// Registers an placement which, when added to a campaign on the Superwall dashboard, can show a paywall.
  ///
  /// This shows a paywall to the user when: A placement you provide is added to a campaign on the [Superwall Dashboard](https://superwall.com/dashboard); the user matches an audience filter in the campaign; and the user doesn't have an active subscription.
  ///
  /// Before using this method, you'll first need to create a campaign and add the placement to the campaign on the [Superwall Dashboard](https://superwall.com/dashboard).
  ///
  /// The paywall shown to the user is determined by the audience filters defined in the campaign. When a user is assigned a paywall within an audience, they will continue to see that paywall unless you remove the paywall from the audience or reset assignments to the paywall.
  ///
  /// - Parameters:
  ///   -  placement: The name of the placement you wish to register.
  ///   - params: Optional parameters you'd like to pass with your placement. These can be referenced within the audience filters of your campaign. Keys beginning with `$` are reserved for Superwall and will be dropped. Values can be any JSON encodable value, URLs or Dates. Arrays and dictionaries as values are not supported at this time, and will be dropped. Defaults to `nil`.
  ///   - handler: An optional handler whose functions provide status updates for a paywall. Defaults to `nil`.
  public func register(
    placement: String,
    params: [String: Any]? = nil,
    handler: PaywallPresentationHandler? = nil
  ) {
    internallyRegister(placement: placement, params: params, handler: handler)
  }

  private func internallyRegister(
    placement: String,
    params: [String: Any]? = nil,
    handler: PaywallPresentationHandler? = nil,
    feature completion: (() -> Void)? = nil
  ) {
    let publisher = PassthroughSubject<PaywallState, Never>()

    publisher
      .receive(on: DispatchQueue.main)
      .subscribe(
        Subscribers.Sink(
          receiveCompletion: { _ in },
          receiveValue: { state in
            switch state {
            case .presented(let paywallInfo):
              handler?.onPresentHandler?(paywallInfo)
            case let .dismissed(paywallInfo, paywallResult):
              if let handler = handler?.onDismissHandler {
                handler(paywallInfo, paywallResult)
              } else {
                handler?.onDismissHandlerObjc?(
                  paywallInfo, paywallResult.convertForObjc(), paywallResult.product)
              }

              switch paywallResult {
              case .purchased,
                .restored:
                completion?()
              case .declined:
                let closeReason = paywallInfo.closeReason
                let featureGating = paywallInfo.featureGatingBehavior
                if closeReason != .forNextPaywall && featureGating == .nonGated {
                  completion?()
                }
                if closeReason == .webViewFailedToLoad && featureGating == .gated {
                  let error = InternalPresentationLogic.presentationError(
                    domain: "SWKPresentationError",
                    code: 106,
                    title: "Webview Failed",
                    value: "Trying to present gated paywall but the webview could not load."
                  )
                  handler?.onErrorHandler?(error)
                }
              }
            case .skipped(let reason):
              if let handler = handler?.onSkipHandler {
                handler(reason)
              } else {
                handler?.onSkipHandlerObjc?(reason.toObjc())
              }
              completion?()
            case .presentationError(let error):
              handler?.onErrorHandler?(error)  // otherwise turning internet off would give unlimited access
            }
          }
        ))

    // Assign the current register task while capturing the previous one.
    previousRegisterTask = Task { [weak self, previousRegisterTask] in
      // Wait until the previous task is finished before continuing.
      await previousRegisterTask?.value

      await self?.trackAndPresentPaywall(
        forPlacement: placement,
        params: params,
        paywallOverrides: nil,
        isFeatureGatable: completion != nil,
        publisher: publisher
      )
    }
  }

  /// Objective-C-only convenience method. Registers a placement which, when added to a campaign on the Superwall dashboard, can show a paywall.
  ///
  /// This shows a paywall to the user when: A placement you provide is added to a campaign on the [Superwall Dashboard](https://superwall.com/dashboard); the user matches an audience in the campaign; and the user doesn't have an active subscription.
  ///
  /// Before using this method, you'll first need to create a campaign and add the placement to the campaign on the [Superwall Dashboard](https://superwall.com/dashboard).
  ///
  /// The paywall shown to the user is determined by the audience filters defined in the campaign. When a user is assigned a paywall within an audience, they will continue to see that paywall unless you remove the paywall from the audience or reset assignments to the paywall.
  ///
  /// - Parameters:
  ///   -  placement: The name of the placement you wish to register.
  @available(swift, obsoleted: 1.0)
  @objc public func register(placement: String) {
    internallyRegister(placement: placement)
  }

  /// Objective-C-only convenience method. Registers a placement which, when added to a campaign on the Superwall dashboard, can show a paywall.
  ///
  /// This shows a paywall to the user when: A placement you provide is added to a campaign on the [Superwall Dashboard](https://superwall.com/dashboard); the user matches an audience in the campaign; and the user doesn't have an active subscription.
  ///
  /// Before using this method, you'll first need to create a campaign and add the placement to the campaign on the [Superwall Dashboard](https://superwall.com/dashboard).
  ///
  /// The paywall shown to the user is determined by the audience filters defined in the campaign. When a user is assigned a paywall within an audience, they will continue to see that paywall unless you remove the paywall from the audience or reset assignments to the paywall.
  ///
  /// - Parameters:
  ///   -  placement: The name of the placement you wish to register.
  ///   - params: Optional parameters you'd like to pass with your placement. These can be referenced within the audience filters of your campaign. Keys beginning with `$` are reserved for Superwall and will be dropped. Values can be any JSON encodable value, URLs or Dates. Arrays and dictionaries as values are not supported at this time, and will be dropped. Defaults to `nil`.
  @available(swift, obsoleted: 1.0)
  @objc public func register(
    placement: String,
    params: [String: Any]?
  ) {
    internallyRegister(placement: placement, params: params)
  }

  private func trackAndPresentPaywall(
    forPlacement placement: String,
    params: [String: Any]? = nil,
    paywallOverrides: PaywallOverrides? = nil,
    isFeatureGatable: Bool,
    publisher: PassthroughSubject<PaywallState, Never>
  ) async {
    do {
      try TrackingLogic.checkNotSuperwallPlacement(placement)
    } catch {
      return
    }

    let trackableEvent = UserInitiatedPlacement.Track(
      rawName: placement,
      canImplicitlyTriggerPaywall: false,
      audienceFilterParams: params ?? [:],
      isFeatureGatable: isFeatureGatable
    )
    let trackResult = await track(trackableEvent)

    let presentationRequest = dependencyContainer.makePresentationRequest(
      .explicitTrigger(trackResult.data),
      paywallOverrides: paywallOverrides,
      isPaywallPresented: isPaywallPresented,
      type: .presentation
    )
    await internallyPresent(presentationRequest, publisher)
  }
}
