//
//  GetPaywallView.swift
//  SuperwallKit
//
//  Created by Yusuf Tör on 17/10/2024.
//

import SwiftUI

/// A SwiftUI paywall view that you can embed into your app.
///
/// This uses ``Superwall/getPaywall(forEvent:params:paywallOverrides:delegate:)`` under the hood.
///
/// - Warning: You're responsible for the deallocation of this view. If you have a `PaywallView` presented somewhere
/// and you try to present the same `PaywallView` elsewhere, you will get a crash.
@available(iOS 14.0, *)
public struct PaywallView<
  OnErrorView: View,
  OnSkippedView: View
>: View {
  @State private var hasLoaded = false
  @Environment(\.presentationMode) private var presentationMode

  /// The name of the event, as you have defined on the Superwall dashboard.
  private let event: String

  /// Optional parameters you'd like to pass with your event. Defaults to `nil`.
  ///
  /// These can be referenced within the rules
  /// of your campaign. Keys beginning with `$` are reserved for Superwall and will be dropped. Values can be any
  /// JSON encodable value, URLs or Dates. Arrays and dictionaries as values are not supported at this time, and will
  /// be dropped.
  private var params: [String: Any]?

  /// An optional ``PaywallOverrides`` object whose parameters override the paywall defaults. Use this to override
  /// products, presentation style, and whether it ignores the subscription status. Defaults to `nil`.
  private var paywallOverrides: PaywallOverrides?

  /// An optional completion block that gets called when the paywall should dismiss. This defaults to `nil` and the SDK
  /// will call `presentationMode.wrappedValue.dismiss()` by default. Otherwise you must perform the dismissal of the paywall.
  private var onRequestDismiss: ((PaywallInfo, PaywallResult) -> Void)?

  /// A completion block that accepts a ``PaywallSkippedReason`` and returns an `View`.
  ///
  /// This will show when the requested paywall is skipped.
  private var onSkippedView: ((PaywallSkippedReason) -> OnSkippedView)?

  /// A completion block that accepts an ``Error`` and returns a `View`. This will show when the requested paywall request
  /// throws an error.
  private var onErrorView: ((Error) -> OnErrorView)?

  /// A completion block containing a feature that you wish to paywall. Access to this block is remotely configurable
  /// via the [Superwall Dashboard](https://superwall.com/dashboard). If the paywall is set to _Non Gated_,
  /// this will be called when the paywall is dismissed or if the user is already paying. If the paywall is _Gated_, this will be
  /// called only if the user is already paying or if they begin paying. If no paywall is configured, this gets called immediately.
  /// This will not be called in the event of an error.
  private var feature: (() -> Void)?

  @StateObject private var manager = GetPaywallManager()

  /// A SwiftUI paywall view that you can embed into your app.
  ///
  /// This uses ``Superwall/getPaywall(forEvent:params:paywallOverrides:delegate:)`` under the hood.
  ///
  /// - Parameters:
  ///   -  event: The name of the event, as you have defined on the Superwall dashboard.
  ///   - params: Optional parameters you'd like to pass with your event. These can be referenced within the rules
  ///   of your campaign. Keys beginning with `$` are reserved for Superwall and will be dropped. Values can be any
  ///   JSON encodable value, URLs or Dates. Arrays and dictionaries as values are not supported at this time, and will
  ///   be dropped.
  ///   - paywallOverrides: An optional ``PaywallOverrides`` object whose parameters override the paywall defaults. Use this
  ///   to override products and whether it ignores the subscription status. Defaults to `nil`.
  ///   - onRequestDismiss: An optional completion block that gets called when the paywall should dismiss. This defaults to `nil` and the SDK
  ///   will call `presentationMode.wrappedValue.dismiss()` by default. Otherwise you must perform the dismissal of the paywall.
  ///   - onSkippedView: A completion block that accepts a ``PaywallSkippedReason`` and returns an `View`. This will show
  ///   when the requested paywall is skipped. Defaults to `EmptyView()`.
  ///   - onErrorView: A completion block that accepts an ``Error`` and returns a `View`. This will show when the requested
  ///   paywall is skipped. Defaults to `EmptyView()`.
  ///   - feature: A completion block containing a feature that you wish to paywall. Access to this block is remotely configurable via the
  ///   [Superwall Dashboard](https://superwall.com/dashboard). If the paywall is set to _Non Gated_, this will be called when
  ///   the paywall is dismissed or if the user is already paying. If the paywall is _Gated_, this will be called only if the user is already paying
  ///   or if they begin paying. If no paywall is configured, this gets called immediately. This will not be called in the event of an error.
  ///
  /// - Warning: You're responsible for the deallocation of this view. If you have a `PaywallView` presented somewhere
  /// and you try to present the same `PaywallView` elsewhere, you will get a crash.
  public init(
    event: String,
    params: [String: Any]? = nil,
    paywallOverrides: PaywallOverrides? = nil,
    onRequestDismiss: ((PaywallInfo, PaywallResult) -> Void)? = nil,
    onSkippedView: ((PaywallSkippedReason) -> OnSkippedView)? = nil,
    onErrorView: ((Error) -> OnErrorView)? = nil,
    feature: (() -> Void)? = nil
  ) {
    self.event = event
    self.params = params
    self.paywallOverrides = paywallOverrides
    self.onRequestDismiss = onRequestDismiss
    self.onSkippedView = onSkippedView
    self.onErrorView = onErrorView
    self.feature = feature
  }

  public var body: some View {
    VStack {
      switch manager.state {
      case .loading:
        EmptyView()
      case .retrieved(let paywallViewController):
        PaywallViewControllerWrapper(paywallViewController: paywallViewController)
      case .skipped(let reason):
        if let onSkippedView = onSkippedView {
          onSkippedView(reason)
        } else {
          EmptyView()
        }
      case .error(let error):
        if let onErrorView = onErrorView {
          onErrorView(error)
        } else {
          EmptyView()
        }
      }
    }
    .onChange(of: manager.dismissState) { newValue in
      switch newValue {
      case let .dismiss(info, result):
        onRequestDismiss?(info, result) ?? presentationMode.wrappedValue.dismiss()
      case .none:
        break
      }
    }
    .onChange(of: manager.userHasAccess) { newValue in
      if newValue {
        feature?()
      }
    }
    .onAppear {
      if !hasLoaded {
        hasLoaded = true
        Task {
          await manager.getPaywall(
            forPlacement: event,
            params: params,
            paywallOverrides: paywallOverrides
          )
        }
      }
    }
  }
}

@available(iOS 14.0, *)
extension PaywallView where OnSkippedView == Never, OnErrorView == Never {
  /// A SwiftUI paywall view that you can embed into your app.
  ///
  /// This uses ``Superwall/getPaywall(forEvent:params:paywallOverrides:delegate:)`` under the hood.
  ///
  /// - Parameters:
  ///   -  event: The name of the event, as you have defined on the Superwall dashboard.
  ///   - params: Optional parameters you'd like to pass with your event. These can be referenced within the rules
  ///   of your campaign. Keys beginning with `$` are reserved for Superwall and will be dropped. Values can be any
  ///   JSON encodable value, URLs or Dates. Arrays and dictionaries as values are not supported at this time, and will
  ///   be dropped.
  ///   - paywallOverrides: An optional ``PaywallOverrides`` object whose parameters override the paywall defaults. Use this
  ///   to override products and whether it ignores the subscription status. Defaults to `nil`.
  ///   - onRequestDismiss: An optional completion block that gets called when the paywall should dismiss. This defaults to `nil` and the SDK
  ///   will call `presentationMode.wrappedValue.dismiss()` by default. Otherwise you must perform the dismissal of the paywall.
  ///   - feature: A completion block containing a feature that you wish to paywall. Access to this block is remotely configurable via the
  ///   [Superwall Dashboard](https://superwall.com/dashboard). If the paywall is set to _Non Gated_, this will be called when
  ///   the paywall is dismissed or if the user is already paying. If the paywall is _Gated_, this will be called only if the user is already paying
  ///   or if they begin paying. If no paywall is configured, this gets called immediately. This will not be called in the event of an error.
  ///
  /// - Warning: You're responsible for the deallocation of this view. If you have a `PaywallView` presented somewhere
  /// and you try to present the same `PaywallView` elsewhere, you will get a crash.
  public init(
    event: String,
    params: [String: Any]? = nil,
    paywallOverrides: PaywallOverrides? = nil,
    onRequestDismiss: ((PaywallInfo, PaywallResult) -> Void)? = nil,
    feature: (() -> Void)? = nil
  ) {
    self.event = event
    self.params = params
    self.paywallOverrides = paywallOverrides
    self.onErrorView = nil
    self.onSkippedView = nil
    self.onRequestDismiss = onRequestDismiss
    self.feature = feature
  }
}

@available(iOS 14.0, *)
extension PaywallView where OnSkippedView == Never {
  /// A SwiftUI paywall view that you can embed into your app.
  ///
  /// This uses ``Superwall/getPaywall(forEvent:params:paywallOverrides:delegate:)`` under the hood.
  ///
  /// - Parameters:
  ///   -  event: The name of the event, as you have defined on the Superwall dashboard.
  ///   - params: Optional parameters you'd like to pass with your event. These can be referenced within the rules
  ///   of your campaign. Keys beginning with `$` are reserved for Superwall and will be dropped. Values can be any
  ///   JSON encodable value, URLs or Dates. Arrays and dictionaries as values are not supported at this time, and will
  ///   be dropped.
  ///   - paywallOverrides: An optional ``PaywallOverrides`` object whose parameters override the paywall defaults. Use this
  ///   to override products and whether it ignores the subscription status. Defaults to `nil`.
  ///   - onRequestDismiss: An optional completion block that gets called when the paywall should dismiss. This defaults to `nil` and the SDK
  ///   will call `presentationMode.wrappedValue.dismiss()` by default. Otherwise you must perform the dismissal of the paywall.
  ///   - onErrorView: A completion block that accepts an ``Error`` and returns a `View`. This will show when the requested
  ///   paywall is skipped. Defaults to `EmptyView()`.
  ///   - feature: A completion block containing a feature that you wish to paywall. Access to this block is remotely configurable via the
  ///   [Superwall Dashboard](https://superwall.com/dashboard). If the paywall is set to _Non Gated_, this will be called when
  ///   the paywall is dismissed or if the user is already paying. If the paywall is _Gated_, this will be called only if the user is already paying
  ///   or if they begin paying. If no paywall is configured, this gets called immediately. This will not be called in the event of an error.
  ///
  /// - Warning: You're responsible for the deallocation of this view. If you have a `PaywallView` presented somewhere
  /// and you try to present the same `PaywallView` elsewhere, you will get a crash.
  public init(
    event: String,
    params: [String: Any]? = nil,
    paywallOverrides: PaywallOverrides? = nil,
    onRequestDismiss: ((PaywallInfo, PaywallResult) -> Void)? = nil,
    onErrorView: @escaping (Error) -> OnErrorView,
    feature: (() -> Void)? = nil
  ) {
    self.event = event
    self.params = params
    self.paywallOverrides = paywallOverrides
    self.onRequestDismiss = onRequestDismiss
    self.onErrorView = onErrorView
    self.onSkippedView = nil
    self.feature = feature
  }
}

@available(iOS 14.0, *)
extension PaywallView where OnErrorView == Never {
  /// A SwiftUI paywall view that you can embed into your app.
  ///
  /// This uses ``Superwall/getPaywall(forEvent:params:paywallOverrides:delegate:)`` under the hood.
  ///
  /// - Parameters:
  ///   -  event: The name of the event, as you have defined on the Superwall dashboard.
  ///   - params: Optional parameters you'd like to pass with your event. These can be referenced within the rules
  ///   of your campaign. Keys beginning with `$` are reserved for Superwall and will be dropped. Values can be any
  ///   JSON encodable value, URLs or Dates. Arrays and dictionaries as values are not supported at this time, and will
  ///   be dropped.
  ///   - paywallOverrides: An optional ``PaywallOverrides`` object whose parameters override the paywall defaults. Use this
  ///   to override products and whether it ignores the subscription status. Defaults to `nil`.
  ///   - onRequestDismiss: An optional completion block that gets called when the paywall should dismiss. This defaults to `nil` and the SDK
  ///   will call `presentationMode.wrappedValue.dismiss()` by default. Otherwise you must perform the dismissal of the paywall.
  ///   - onSkippedView: A completion block that accepts a ``PaywallSkippedReason`` and returns an `View`. This will show
  ///   when the requested paywall is skipped. Defaults to `EmptyView()`.
  ///   - onErrorView: A completion block that accepts an ``Error`` and returns a `View`. This will show when the requested
  ///   paywall is skipped.
  ///   - feature: A completion block containing a feature that you wish to paywall. Access to this block is remotely configurable via the
  ///   [Superwall Dashboard](https://superwall.com/dashboard). If the paywall is set to _Non Gated_, this will be called when
  ///   the paywall is dismissed or if the user is already paying. If the paywall is _Gated_, this will be called only if the user is already paying
  ///   or if they begin paying. If no paywall is configured, this gets called immediately. This will not be called in the event of an error.
  ///
  /// - Warning: You're responsible for the deallocation of this view. If you have a `PaywallView` presented somewhere
  /// and you try to present the same `PaywallView` elsewhere, you will get a crash. 
  public init(
    event: String,
    params: [String: Any]? = nil,
    paywallOverrides: PaywallOverrides? = nil,
    onRequestDismiss: ((PaywallInfo, PaywallResult) -> Void)? = nil,
    onSkippedView: @escaping (PaywallSkippedReason) -> OnSkippedView,
    feature: (() -> Void)? = nil
  ) {
    self.event = event
    self.params = params
    self.paywallOverrides = paywallOverrides
    self.onErrorView = nil
    self.onSkippedView = onSkippedView
    self.feature = feature
    self.onRequestDismiss = onRequestDismiss
  }
}
