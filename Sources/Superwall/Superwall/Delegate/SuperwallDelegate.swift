//
//  File.swift
//  
//
//  Created by Jake Mor on 10/5/21.
//

import Foundation
import StoreKit

/// The delegate protocol that handles Superwall lifecycle events.
///
/// The delegate methods receive callbacks from the SDK in response to certain events that happen on the paywall.
/// It contains some required and some optional methods. To learn how to conform to the delegate in your app
/// and best practices, see <doc:GettingStarted>.
@MainActor
public protocol SuperwallDelegate: AnyObject {
  /// Called when the user initiates purchasing of a product.
  ///
  /// Add your purchase logic here and return its result. You can use Apple's StoreKit APIs,
  /// or if you use RevenueCat, you can call [`Purchases.shared.purchase(product:)`](https://revenuecat.github.io/purchases-ios-docs/4.13.4/documentation/revenuecat/purchases/purchase(product:completion:)).
	/// - Parameters:
  ///   - product: The `SKProduct` the user would like to purchase.
  ///
  /// - Returns: A``PurchaseResult`` object, which is the result of your purchase logic. **Note**: Make sure you handle all cases of ``PurchaseResult``.
  func purchase(product: SKProduct) async -> PurchaseResult

	/// Called when the user initiates a restore.
  ///
  /// Add your restore logic here and return its result.
  ///
  /// - Returns: A boolean that's `true` if the user's purchases were restored or `false` if they weren't.
	func restorePurchases() async -> Bool

	/// Decides whether a paywall should be presented based on the user's subscription status.
  ///
  /// A paywall will never show if this function returns `true`.
  ///
  /// - Returns: A boolean that indicates whether or not the user has an active subscription.
  func isUserSubscribed() -> Bool

	/// Called when the user taps a button on your paywall that has a `data-pw-custom` tag attached.
  ///
  /// To learn more about using this function, see <doc:CustomPaywallButtons>. To learn about the types of tags that can
  /// be attached to elements on your paywall, see [Data Tags](https://docs.superwall.com/docs/data-tags).
  ///
	///  - Parameter name: The value of the `data-pw-custom` tag in your HTML element that the user selected.
	func handleCustomPaywallAction(withName name: String)

	/// Called right before the paywall is dismissed.
	func willDismissPaywall()

	/// Called right before the paywall is presented.
	func willPresentPaywall()

	/// Called right after the paywall is dismissed.
	func didDismissPaywall()

	/// Called right after the paywall is presented.
  func didPresentPaywall()

	/// Called when the user opens a URL by selecting an element on your paywall that has a `data-pw-open-url` tag.
  ///
  /// - Parameter url: The URL to open
  func willOpenURL(url: URL)

	/// Called when the user taps a deep link in your paywall.
  ///
  /// - Parameter url: The deep link URL to open
	func willOpenDeepLink(url: URL)

	/// Called whenever an internal analytics event is tracked. See <doc:AutomaticallyTrackedEvents> for more.
  ///
  /// Use this method when you want to track internal analytics events in your own analytics.
  ///
  /// If you want the event's name as an enum, do this:
  ///
  /// ```swift
  /// let event = SuperwallEvent(
  ///   rawValue: name
  /// )
  /// ```
	///
	/// Possible Values:
	///  ```swift
	/// // App Lifecycle Events
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "app_install",
  ///   params: nil
  /// )
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "app_open",
  ///   params: nil
  /// )
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "app_close",
  ///   params: nil
  /// )
	///
	/// // Superwall Events
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "paywall_open",
  ///   params: ['paywall_id': 'someid']
  /// )
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "paywall_close",
  ///   params: ['paywall_id': 'someid']
  /// )
	///
	/// // Transaction Events
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "transaction_start",
  ///   params: ['paywall_id': 'someid', 'product_id': 'someskid']
  /// )
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "transaction_fail",
  ///   params: ['paywall_id': 'someid', 'product_id': 'someskid']
  /// )
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "transaction_abandon",
  ///   params: ['paywall_id': 'someid', 'product_id': 'someskid']
  /// )
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "transaction_complete",
  ///   params: ['paywall_id': 'someid', 'product_id': 'someskid']
  /// )
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "transaction_restore",
  ///   params: ['paywall_id': 'someid', 'product_id': 'someskid']
  /// )
	///
	/// // Purchase Events
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "subscription_start",
  ///   params: ['paywall_id': 'someid', 'product_id': 'someskid']
  /// )
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "freeTrial_start",
  ///   params: ['paywall_id': 'someid', 'product_id': 'someskid']
  /// )
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "nonRecurringProduct_purchase",
  ///   params: ['paywall_id': 'someid', 'product_id': 'someskid']
  /// )
	///
	/// // Superwall API Request Events
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "paywallResponseLoad_start",
  ///   params: ['paywall_id': 'someid']
  /// )
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "paywallResponseLoad_fail",
  ///   params: ['paywall_id': 'someid']
  /// )
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "paywallResponseLoad_complete",
  ///   params: ['paywall_id': 'someid']
  /// )
	///
	/// // Webview Reqeuest Events
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "paywallWebviewLoad_start",
  ///   params: ['paywall_id': 'someid']
  /// )
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "paywallWebviewLoad_fail",
  ///   params: ['paywall_id': 'someid']
  /// )
	/// Superwall.delegate.trackAnalyticsEvent(
  ///   name: "paywallWebviewLoad_complete",
  ///   params: ['paywall_id': 'someid']
  /// )
	/// ```
	func trackAnalyticsEvent(
    withName name: String,
    params: [String: Any]
  )

  /// Receive all the log messages generated by the SDK.
  ///
  /// - Parameters:
  ///   - level: Specifies the detail of the logs returned from the SDK to the console.
  ///   Can be either `DEBUG`, `INFO`, `WARN`, or `ERROR`, as defined by ``LogLevel``.
  ///   - scope: The possible scope of logs to print to the console, as defined by ``LogScope``.
  ///   - message: The message associated with the log.
  ///   - info: A dictionary of information associated with the log.
  ///   - error: The error associated with the log.
  func handleLog(
    level: String,
    scope: String,
    message: String?,
    info: [String: Any]?,
    error: Swift.Error?
  )
}

public extension SuperwallDelegate {
  func handleCustomPaywallAction(withName name: String) {}

  func willDismissPaywall() {}

  func willPresentPaywall() {}

  func didDismissPaywall() {}

  func didPresentPaywall() {}

  func willOpenURL(url: URL) {}

  func willOpenDeepLink(url: URL) {}

  func trackAnalyticsEvent(
    withName name: String,
    params: [String: Any]
  ) {}

  func handleLog(
    level: String,
    scope: String,
    message: String?,
    info: [String: Any]?,
    error: Swift.Error?
  ) {}
}