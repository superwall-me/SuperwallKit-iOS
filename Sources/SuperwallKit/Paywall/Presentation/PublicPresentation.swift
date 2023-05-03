//
//  File.swift
//  
//
//  Created by Jake Mor on 10/9/21.
//
// swiftlint:disable line_length file_length function_body_length

import Foundation
import Combine
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

  /// Dismisses the presented paywall.
  @MainActor
  @nonobjc
  public func dismiss() async {
    guard let paywallViewController = paywallViewController else {
      return
    }
    await withCheckedContinuation { continuation in
      dismiss(
        paywallViewController,
        result: .closed
      ) {
        continuation.resume()
      }
    }
  }

  @MainActor
  func dismissForNextPaywall() async {
    guard let paywallViewController = paywallViewController else {
      return
    }

    await withCheckedContinuation { continuation in
      dismiss(
        paywallViewController,
        result: .closed,
        shouldCompleteStatePublisher: false,
        closeReason: .forNextPaywall
      ) {
        continuation.resume()
      }
    }
  }

  // MARK: - Objective-C-only Track
  /// An Objective-C-only method that shows a paywall to the user when: An event you provide is tied to an
  /// active trigger inside a campaign on the [Superwall Dashboard](https://superwall.com/dashboard);
  /// and the user matches a rule in the campaign. **Note**: Please use ``Superwall/setUserAttributes(_:)-1wql2``
  /// if you’re using Swift.
  ///
  /// Triggers enable you to retroactively decide where or when to show a specific paywall in your app. Use this method
  /// when you want to remotely control paywall presentation in response to your own analytics event and utilize
  /// completion handlers associated with the paywall presentation state.
  ///
  /// Before using this method, you'll first need to create a campaign and add a trigger associated with the event name
  /// on the [Superwall Dashboard](https://superwall.com/dashboard).
  ///
  /// The paywall shown to the user is determined by the rules defined in the campaign. Paywalls are sticky, in that when
  /// a user is assigned a paywall within a rule, they will continue to see that paywall unless you remove the paywall from the rule.
  ///
  /// - Parameters:
  ///   -  event: The name of the event you wish to track.
  ///   - params: Optional parameters you'd like to pass with your event. These can be referenced within the rules of your campaign.
  ///   Keys beginning with `$` are reserved for Superwall and will be dropped. Values can be any JSON encodable value, URLs or Dates.
  ///   Arrays and dictionaries as values are not supported at this time, and will be dropped.
  ///   - products: An optional ``PaywallProducts`` object whose products replace the remotely defined paywall products. Defaults
  ///   to `nil`.
  ///   - ignoreSubscriptionStatus: Presents the paywall regardless of subscription status if `true`. Defaults to `false`.
  ///   - presentationStyleOverride: A `PaywallPresentationStyle` object that overrides the presentation style of the paywall
  ///   set on the dashboard. Defaults to `.none`.
  ///   - onPresent: A completion block that gets called immediately after the paywall is presented. Defaults to `nil`.  Accepts a
  ///   ``PaywallInfo`` object containing information about the paywall.
  ///   - onDismiss: A completion block that gets called when the paywall is dismissed by the user, by way of purchasing, restoring or manually
  ///   dismissing. Defaults to `nil`. Accepts a `Bool` that is `true` if the user purchased a product and `false` if not, a `String?` equal
  ///   to the product id of the purchased product (if any) and a ``PaywallInfo`` object containing information about the paywall.
  ///   - onSkip: A completion block that gets called when the paywall's presentation is skipped. Defaults to `nil`.  Accepts a
  ///   ``PaywallSkippedReasonObjc`` object and an `NSError` with more details.
  @available(swift, obsoleted: 1.0)
  @objc private func track(
    event: String,
    params: [String: Any]? = nil,
    products: PaywallProducts? = nil,
    ignoreSubscriptionStatus: Bool = false,
    presentationStyleOverride: PaywallPresentationStyle = .none,
    onSkip: ((PaywallSkippedReasonObjc, NSError) -> Void)? = nil,
    onPresent: ((PaywallInfo) -> Void)? = nil,
    onDismiss: ((PaywallResultObjc, String?, PaywallInfo) -> Void)? = nil
  ) {
    objcTrack(
      event: event,
      params: params,
      products: products,
      ignoreSubscriptionStatus: ignoreSubscriptionStatus,
      presentationStyleOverride: presentationStyleOverride,
      onSkip: onSkip,
      onPresent: onPresent,
      onDismiss: onDismiss
    )
  }

  private func objcTrack(
    event: String,
    params: [String: Any]? = nil,
    products: PaywallProducts? = nil,
    ignoreSubscriptionStatus: Bool = false,
    presentationStyleOverride: PaywallPresentationStyle = .none,
    onSkip: ((PaywallSkippedReasonObjc, NSError) -> Void)? = nil,
    onPresent: ((PaywallInfo) -> Void)? = nil,
    onDismiss: ((PaywallResultObjc, String?, PaywallInfo) -> Void)? = nil
  ) {
    let overrides = PaywallOverrides(
      products: products,
      ignoreSubscriptionStatus: ignoreSubscriptionStatus,
      presentationStyleOverride: presentationStyleOverride
    )

    track(
      event: event,
      params: params,
      paywallOverrides: overrides
    ) { [weak self] state in
      switch state {
      case .presented(let paywallInfo):
        onPresent?(paywallInfo)
      case let .dismissed(paywallInfo, state):
        if let onDismiss = onDismiss {
          self?.onDismissConverter(
            paywallInfo: paywallInfo,
            state: state,
            completion: onDismiss
          )
        }
      case .skipped(let reason):
        self?.onSkipConverter(reason: reason, completion: onSkip)
      case .presentationError(let error):
        self?.onSkipConverter(error: error, completion: onSkip)
      }
    }
  }

  private func onSkipConverter(
    reason: PaywallSkippedReason? = nil,
    error: Error? = nil,
    completion: ((PaywallSkippedReasonObjc, NSError) -> Void)?
  ) {

    if let reason = reason {
      switch reason {
      case .holdout(let experiment):
        let userInfo: [String: Any] = [
          "experimentId": experiment.id,
          "variantId": experiment.variant.id,
          "groupId": experiment.groupId,
          NSLocalizedDescriptionKey: NSLocalizedString(
            "Holdout",
            value: "This user was assigned to a holdout. This means the paywall will not show.",
            comment: "ExperimentId: \(experiment.id), VariantId: \(experiment.variant.id), GroupId: \(experiment.groupId)"
          )
        ]
        let error = NSError(
          domain: "com.superwall",
          code: 4001,
          userInfo: userInfo
        )
        completion?(.holdout, error)
      case .noRuleMatch:
        let userInfo: [String: Any] = [
          NSLocalizedDescriptionKey: NSLocalizedString(
            "No rule match",
            value: "The user did not match any rules configured for this trigger",
            comment: ""
          )
        ]
        let error = NSError(
          domain: "com.superwall",
          code: 4000,
          userInfo: userInfo
        )
        completion?(.noRuleMatch, error)
      case .eventNotFound:
        let userInfo: [String: Any] = [
          NSLocalizedDescriptionKey: NSLocalizedString(
            "Event Not Found",
            value: "The specified event could not be found in a campaign",
            comment: ""
          )
        ]
        let error = NSError(
          domain: "com.superwall",
          code: 404,
          userInfo: userInfo
        )
        completion?(.eventNotFound, error)
      case .userIsSubscribed:
        let userInfo: [String: Any] = [
          NSLocalizedDescriptionKey: NSLocalizedString(
            "User Is Subscribed",
            value: "The user subscription status is \"active\". By default, paywalls do not show to users who are already subscribed. You can override this behavior in the paywall editor.",
            comment: ""
          )
        ]
        let error = NSError(
          domain: "com.superwall",
          code: 4002,
          userInfo: userInfo
        )
        completion?(.userIsSubscribed, error)
      }
    }

    if let error = error {
      completion?(.error, error as NSError)
    }

  }

  /// An Objective-C-only method that shows a paywall to the user when: An event you provide is tied to an
  /// active trigger inside a campaign on the [Superwall Dashboard](https://superwall.com/dashboard);
  /// and the user matches a rule in the campaign. **Note**: Please use ``Superwall/setUserAttributes(_:)-1wql2``
  /// if you’re using Swift.
  ///
  /// Triggers enable you to retroactively decide where or when to show a specific paywall in your app. Use this method
  ///  when you want to remotely control paywall presentation in response to your own analytics event and utilize
  ///   completion handlers associated with the paywall presentation state.
  ///
  /// Before using this method, you'll first need to create a campaign and add a trigger associated with the event name
  ///  on the [Superwall Dashboard](https://superwall.com/dashboard).
  ///
  /// The paywall shown to the user is determined by the rules defined in the campaign. Paywalls are sticky, in that when
  ///  a user is assigned a paywall within a rule, they will continue to see that paywall unless you remove the paywall from the rule.
  ///
  /// - Parameters:
  ///   -  event: The name of the event you wish to track.
  @available(swift, obsoleted: 1.0)
  @objc private func track(event: String) {
    objcTrack(event: event)
  }

  /// An Objective-C-only method that shows a paywall to the user when: An event you provide is tied to an
  /// active trigger inside a campaign on the [Superwall Dashboard](https://superwall.com/dashboard);
  /// and the user matches a rule in the campaign. **Note**: Please use ``Superwall/setUserAttributes(_:)-1wql2``
  /// if you’re using Swift.
  ///
  /// Triggers enable you to retroactively decide where or when to show a specific paywall in your app. Use this method
  /// when you want to remotely control paywall presentation in response to your own analytics event and utilize
  /// completion handlers associated with the paywall presentation state.
  ///
  /// Before using this method, you'll first need to create a campaign and add a trigger associated with the event name
  /// on the [Superwall Dashboard](https://superwall.com/dashboard).
  ///
  /// The paywall shown to the user is determined by the rules defined in the campaign. Paywalls are sticky, in that when
  /// a user is assigned a paywall within a rule, they will continue to see that paywall unless you remove the paywall from the rule.
  ///
  /// - Parameters:
  ///   -  event: The name of the event you wish to track.
  ///   - params: Optional parameters you'd like to pass with your event. These can be referenced within the rules of your campaign.
  ///   Keys beginning with `$` are reserved for Superwall and will be dropped. Values can be any JSON encodable value, URLs or Dates.
  ///   Arrays and dictionaries as values are not supported at this time, and will be dropped.
  @available(swift, obsoleted: 1.0)
  @objc private func track(
    event: String,
    params: [String: Any]? = nil
  ) {
    objcTrack(event: event, params: params)
  }

  /// An Objective-C-only method that shows a paywall to the user when: An event you provide is tied to an
  /// active trigger inside a campaign on the [Superwall Dashboard](https://superwall.com/dashboard);
  /// and the user matches a rule in the campaign. **Note**: Please use ``Superwall/setUserAttributes(_:)-1wql2``
  /// if you’re using Swift.
  ///
  /// Triggers enable you to retroactively decide where or when to show a specific paywall in your app. Use this method
  /// when you want to remotely control paywall presentation in response to your own analytics event and utilize
  /// completion handlers associated with the paywall presentation state.
  ///
  /// Before using this method, you'll first need to create a campaign and add a trigger associated with the event name
  /// on the [Superwall Dashboard](https://superwall.com/dashboard).
  ///
  /// The paywall shown to the user is determined by the rules defined in the campaign. Paywalls are sticky, in that when
  /// a user is assigned a paywall within a rule, they will continue to see that paywall unless you remove the paywall from the rule.
  ///
  /// - Parameters:
  ///   -  event: The name of the event you wish to track.
  ///   - onPresent: A completion block that gets called immediately after the paywall is presented. Defaults to `nil`.  Accepts a
  ///   ``PaywallInfo`` object containing information about the paywall.
  ///   - onDismiss: A completion block that gets called when the paywall is dismissed by the user, by way of purchasing, restoring or manually
  ///    dismissing. Defaults to `nil`. Accepts a `Bool` that is `true` if the user purchased a product and `false` if not, a `String?` equal
  ///     to the product id of the purchased product (if any) and a ``PaywallInfo`` object containing information about the paywall.
  ///   - onSkip: A completion block that gets called when the paywall's presentation is skipped. Defaults to `nil`.  Accepts a
  ///   ``PaywallSkippedReasonObjc`` object and an `NSError` with more details.
  @available(swift, obsoleted: 1.0)
  @objc private func track(
    event: String,
    onSkip: ((PaywallSkippedReasonObjc, NSError) -> Void)? = nil,
    onPresent: ((PaywallInfo) -> Void)? = nil,
    onDismiss: ((PaywallResultObjc, String?, PaywallInfo) -> Void)? = nil
  ) {
    objcTrack(
      event: event,
      onSkip: onSkip,
      onPresent: onPresent,
      onDismiss: onDismiss
    )
  }

  /// An Objective-C-only method that shows a paywall to the user when: An event you provide is tied to an
  /// active trigger inside a campaign on the [Superwall Dashboard](https://superwall.com/dashboard);
  /// and the user matches a rule in the campaign. **Note**: Please use ``Superwall/setUserAttributes(_:)-1wql2``
  /// if you’re using Swift.
  ///
  /// Triggers enable you to retroactively decide where or when to show a specific paywall in your app. Use this method
  /// when you want to remotely control paywall presentation in response to your own analytics event and utilize
  /// completion handlers associated with the paywall presentation state.
  ///
  /// Before using this method, you'll first need to create a campaign and add a trigger associated with the event name
  /// on the [Superwall Dashboard](https://superwall.com/dashboard).
  ///
  /// The paywall shown to the user is determined by the rules defined in the campaign. Paywalls are sticky, in that when
  /// a user is assigned a paywall within a rule, they will continue to see that paywall unless you remove the paywall from the rule.
  ///
  /// - Parameters:
  ///   -  event: The name of the event you wish to track.
  ///   - params: Optional parameters you'd like to pass with your event. These can be referenced within the rules of your campaign.
  ///   - onPresent: A completion block that gets called immediately after the paywall is presented. Defaults to `nil`.  Accepts a
  ///   ``PaywallInfo`` object containing information about the paywall.
  ///   - onDismiss: A completion block that gets called when the paywall is dismissed by the user, by way of purchasing, restoring or manually
  ///    dismissing. Defaults to `nil`. Accepts a `Bool` that is `true` if the user purchased a product and `false` if not, a `String?` equal
  ///     to the product id of the purchased product (if any) and a ``PaywallInfo`` object containing information about the paywall.
  ///   - onSkip: A completion block that gets called when the paywall's presentation is skipped. Defaults to `nil`.  Accepts a
  ///   ``PaywallSkippedReasonObjc`` object and an `NSError` with more details.
  @available(swift, obsoleted: 1.0)
  @objc private func track(
    event: String,
    params: [String: Any]? = nil,
    onSkip: ((PaywallSkippedReasonObjc, NSError) -> Void)? = nil,
    onPresent: ((PaywallInfo) -> Void)? = nil,
    onDismiss: ((PaywallResultObjc, String?, PaywallInfo) -> Void)? = nil
  ) {
    objcTrack(
      event: event,
      params: params,
      onSkip: onSkip,
      onPresent: onPresent,
      onDismiss: onDismiss
    )
  }

  // MARK: - Swift Track

  /// Tracks an event which, when added to a campaign on the Superwall dashboard, can show a paywall.
  ///
  /// This shows a paywall to the user when: An event you provide is added to a campaign on the [Superwall Dashboard](https://superwall.com/dashboard); the user matches a rule in the campaign; and the user doesn't have an active subscription.
  ///
  /// Before using this method, you'll first need to create a campaign and add the event to the campaign on the [Superwall Dashboard](https://superwall.com/dashboard).
  ///
  /// The paywall shown to the user is determined by the rules defined in the campaign. When a user is assigned a paywall within a rule, they will continue to see that paywall unless you remove the paywall from the rule or reset assignments to the paywall.
  ///
  /// - Parameters:
  ///   -  event: The name of the event you wish to track.
  ///   - params: Optional parameters you'd like to pass with your event. These can be referenced within the rules of your campaign. Keys beginning with `$` are reserved for Superwall and will be dropped. Values can be any JSON encodable value, URLs or Dates. Arrays and dictionaries as values are not supported at this time, and will be dropped.
  ///   - paywallOverrides: An optional ``PaywallOverrides`` object whose parameters override the paywall defaults. Use this to override products, presentation style, and whether it ignores the subscription status. Defaults to `nil`.
  ///   - paywallHandler: An optional callback that provides updates on the state of the paywall via a ``PaywallState`` object.
  private func track(
    event: String,
    params: [String: Any]? = nil,
    paywallOverrides: PaywallOverrides? = nil,
    paywallHandler: ((PaywallState) -> Void)? = nil
  ) {
    publisher(
      forEvent: event,
      params: params,
      paywallOverrides: paywallOverrides,
      isFeatureGatable: false
    )
    .subscribe(Subscribers.Sink(
      receiveCompletion: { _ in },
      receiveValue: { state in
        paywallHandler?(state)
      }
    ))
  }

  /// Registers an event to access a feature. When the event is added to a campaign on the Superwall dashboard, it can show a paywall.
  ///
  /// This shows a paywall to the user when: An event you provide is added to a campaign on the [Superwall Dashboard](https://superwall.com/dashboard); the user matches a rule in the campaign; and the user doesn't have an active subscription.
  ///
  /// Before using this method, you'll first need to create a campaign and add the event to the campaign on the [Superwall Dashboard](https://superwall.com/dashboard).
  ///
  /// The paywall shown to the user is determined by the rules defined in the campaign. When a user is assigned a paywall within a rule, they will continue to see that paywall unless you remove the paywall from the rule or reset assignments to the paywall.
  ///
  /// - Parameters:
  ///   -  event: The name of the event you wish to register.
  ///   - params: Optional parameters you'd like to pass with your event. These can be referenced within the rules of your campaign. Keys beginning with `$` are reserved for Superwall and will be dropped. Values can be any JSON encodable value, URLs or Dates. Arrays and dictionaries as values are not supported at this time, and will be dropped.
  ///   - handler: An optional handler whose variables provide status updates for a paywall. Defaults to `nil`.
  ///   - feature: A completion block containing a feature that you wish to paywall. Access to this block is remotely configurable via the [Superwall Dashboard](https://superwall.com/dashboard). If the paywall is set to _Non Gated_, this will be called when the paywall is dismissed or if the user is already paying. If the paywall is _Gated_, this will be called only if the user is already paying or if they begin paying. If no paywall is configured, this gets called immediately. This will not be called in the event of an error, which you can detect via the `handler`.
  public func register(
    event: String,
    params: [String: Any]? = nil,
    handler: PaywallPresentationHandler? = nil,
    feature: @escaping () -> Void
  ) {
    internallyRegister(event: event, params: params, handler: handler, feature: feature)
  }

  /// Registers an event which, when added to a campaign on the Superwall dashboard, can show a paywall.
  ///
  /// This shows a paywall to the user when: An event you provide is added to a campaign on the [Superwall Dashboard](https://superwall.com/dashboard); the user matches a rule in the campaign; and the user doesn't have an active subscription.
  ///
  /// Before using this method, you'll first need to create a campaign and add the event to the campaign on the [Superwall Dashboard](https://superwall.com/dashboard).
  ///
  /// The paywall shown to the user is determined by the rules defined in the campaign. When a user is assigned a paywall within a rule, they will continue to see that paywall unless you remove the paywall from the rule or reset assignments to the paywall.
  ///
  /// - Parameters:
  ///   -  event: The name of the event you wish to register.
  ///   - params: Optional parameters you'd like to pass with your event. These can be referenced within the rules of your campaign. Keys beginning with `$` are reserved for Superwall and will be dropped. Values can be any JSON encodable value, URLs or Dates. Arrays and dictionaries as values are not supported at this time, and will be dropped.
  ///   - handler: An optional handler whose variables provide status updates for a paywall. Defaults to `nil`.
  public func register(
    event: String,
    params: [String: Any]? = nil,
    handler: PaywallPresentationHandler? = nil
  ) {
    internallyRegister(event: event, params: params, handler: handler)
  }

  private func internallyRegister(
    event: String,
    params: [String: Any]? = nil,
    handler: PaywallPresentationHandler? = nil,
    feature completion: (() -> Void)? = nil
  ) {
    publisher(
      forEvent: event,
      params: params,
      paywallOverrides: nil,
      isFeatureGatable: completion != nil
    )
    .subscribe(Subscribers.Sink(
      receiveCompletion: { _ in },
      receiveValue: { state in
        switch state {
        case .presented(let paywallInfo):
          DispatchQueue.main.async {
            handler?.onPresentHandler?(paywallInfo)
          }
        case let .dismissed(paywallInfo, state):
          DispatchQueue.main.async {
            handler?.onDismissHandler?(paywallInfo)
          }
          switch state {
          case .purchased,
            .restored:
            DispatchQueue.main.async {
              completion?()
            }
          case .closed:
            let closeReason = paywallInfo.closeReason
            let featureGating = paywallInfo.featureGatingBehavior
            if closeReason != .forNextPaywall && featureGating == .nonGated {
              DispatchQueue.main.async {
                completion?()
              }
            }
          }
        case .skipped(let reason):
          DispatchQueue.main.async {
            handler?.onSkipHandler?(reason)
            completion?()
          }
        case .presentationError(let error):
          DispatchQueue.main.async {
            handler?.onErrorHandler?(error) // otherwise turning internet off would give unlimited access
          }
        }

      }
    ))
  }

  /// Returns a publisher that tracks an event which, when added to a campaign on the Superwall dashboard, can show a paywall.
  ///
  /// This shows a paywall to the user when: An event you provide is added to a campaign on the [Superwall Dashboard](https://superwall.com/dashboard); the user matches a rule in the campaign; and the user doesn't have an active subscription.
  ///
  /// Before using this method, you'll first need to create a campaign and add the event to the campaign on the [Superwall Dashboard](https://superwall.com/dashboard).
  ///
  /// The paywall shown to the user is determined by the rules defined in the campaign. When a user is assigned a paywall within a rule, they will continue to see that paywall unless you remove the paywall from the rule or reset assignments to the paywall.
  ///
  /// - Parameters:
  ///   -  event: The name of the event you wish to track.
  ///   - params: Optional parameters you'd like to pass with your event. These can be referenced within the rules of your campaign. Keys beginning with `$` are reserved for Superwall and will be dropped. Values can be any JSON encodable value, URLs or Dates. Arrays and dictionaries as values are not supported at this time, and will be dropped.
  ///   - paywallOverrides: An optional ``PaywallOverrides`` object whose parameters override the paywall defaults. Use this to override products, presentation style, and whether it ignores the subscription status. Defaults to `nil`.
  ///
  /// - Returns: A publisher that provides updates on the state of the paywall via a ``PaywallState`` object.
  public func publisher(
    forEvent event: String,
    params: [String: Any]? = nil,
    paywallOverrides: PaywallOverrides? = nil,
    isFeatureGatable: Bool
  ) -> PaywallStatePublisher {
    do {
      try TrackingLogic.checkNotSuperwallEvent(event)
    } catch {
      return Just(.presentationError(error)).eraseToAnyPublisher()
    }

    return Future {
      let trackableEvent = UserInitiatedEvent.Track(
        rawName: event,
        canImplicitlyTriggerPaywall: false,
        customParameters: params ?? [:],
        isFeatureGatable: isFeatureGatable
      )
      let trackResult = await self.track(trackableEvent)
      return (trackResult, self.isPaywallPresented)
    }
    .flatMap { trackResult, isPaywallPresented in
      let presentationRequest = self.dependencyContainer.makePresentationRequest(
        .explicitTrigger(trackResult.data),
        paywallOverrides: paywallOverrides,
        isPaywallPresented: isPaywallPresented,
        type: .presentation
      )
      return self.internallyPresent(presentationRequest)
    }
    .eraseToAnyPublisher()
  }


  /// Converts dismissal result from enums with associated values, to old objective-c compatible way
  ///
  /// - Parameters:
  ///   - result: The dismissal result
  ///   - completion: A completion block that gets called when the paywall is dismissed by the user, by way of purchasing, restoring or manually dismissing. Accepts a `Bool` that is `true` if the user purchased a product and `false` if not, a `String?` equal to the product id of the purchased product (if any) and a ``PaywallInfo`` object containing information about the paywall.
  private func onDismissConverter(
    paywallInfo: PaywallInfo,
    state: PaywallResult,
    completion: (PaywallResultObjc, String?, PaywallInfo) -> Void
  ) {
    switch state {
    case .closed:
      completion(.closed, nil, paywallInfo)
    case .purchased(productId: let productId):
      completion(.purchased, productId, paywallInfo)
    case .restored:
      completion(.restored, nil, paywallInfo)
    }
  }
}
