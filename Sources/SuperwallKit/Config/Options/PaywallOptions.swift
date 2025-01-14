//
//  File.swift
//  
//
//  Created by Yusuf Tör on 03/10/2022.
//

import Foundation

/// Options for configuring the appearance and behavior of paywalls.
@objc(SWKPaywallOptions)
@objcMembers
public final class PaywallOptions: NSObject, Encodable {
  /// Determines whether the paywall should use haptic feedback. Defaults to true.
  ///
  /// Haptic feedback occurs when a user purchases or restores a product, opens a URL
  /// from the paywall, or closes the paywall.
  public var isHapticFeedbackEnabled = true

  /// Defines the messaging of the alert presented to the user when restoring a transaction fails.

  @objc(SWKRestoreFailed)
  @objcMembers
  public final class RestoreFailed: NSObject, Encodable {
    /// The title of the alert presented to the user when restoring a transaction fails. Defaults to
    /// `No Subscription Found`.
    public var title = "No Subscription Found"

    /// Defines the message of the alert presented to the user when restoring a transaction fails.
    /// Defaults to `We couldn't find an active subscription for your account.`
    public var message = "We couldn't find an active subscription for your account."

    /// Defines the title of the close button in the alert presented to the user when restoring a
    /// transaction fails. Defaults to `Okay`.
    public var closeButtonTitle = "Okay"

    private enum CodingKeys: CodingKey {
      case restoreTitle
      case restoreMessage
      case restoreCloseButtonTitle
    }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(title, forKey: .restoreTitle)
      try container.encode(message, forKey: .restoreMessage)
      try container.encode(closeButtonTitle, forKey: .restoreCloseButtonTitle)
    }
  }
  /// Defines the messaging of the alert presented to the user when restoring a transaction fails.
  public var restoreFailed = RestoreFailed()

  @objc(SWKNotificationPermissionsDenied)
  @objcMembers
  public final class NotificationPermissionsDenied: NSObject, Encodable {
    /// The title of the alert presented to the user when notification permissions are denied. Defaults to
    /// `Notification Permissions Denied`.
    public var title = "Notification Permissions Denied"

    /// Defines the message of the alert presented to the user when notification permissions are denied.
    /// Defaults to `Please enable notification permissions from the Settings app so we can notify you when your free trial ends.`
    public var message = "Please enable notification permissions from "
      + "the Settings app so we can notify you when your free trial ends."

    /// Defines the title of the action button in the alert presented to the user when notification permissions are denied. Defaults to `Open Settings`.
    public var actionButtonTitle = "Open Settings"

    /// Defines the title of the close button in the alert presented to the user when notification permissions are denied. Defaults to `Not now`.
    public var closeButtonTitle = "Not now"

    private enum CodingKeys: CodingKey {
      case deniedTitle
      case deniedMessage
      case deniedCloseButtonTitle
    }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(title, forKey: .deniedTitle)
      try container.encode(message, forKey: .deniedMessage)
      try container.encode(closeButtonTitle, forKey: .deniedCloseButtonTitle)
    }
  }
  /// Defines the messaging of the alert presented to the user when notification permissions are denied.
  public var notificationPermissionsDenied: NotificationPermissionsDenied?

  /// Shows an alert after a purchase fails. Defaults to `true`.
  ///
  /// Set this to `false` if you're using a `PurchaseController` and want to show
  /// your own alert after the purchase fails.
  public var shouldShowPurchaseFailureAlert = true

  /// Pre-loads and caches trigger paywalls and products when you initialize the SDK via ``Superwall/configure(apiKey:purchaseController:options:completion:)-52tke``. Defaults to `true`.
  ///
  /// Set this to `false` to load and cache paywalls and products in a just-in-time fashion.
  ///
  /// If you want to preload them at a later date, you can call ``Superwall/preloadAllPaywalls()``
  /// or ``Superwall/preloadPaywalls(forPlacements:)``
  public var shouldPreload = true

  /// Automatically dismisses the paywall when a product is purchased or restored. Defaults to `true`.
  ///
  /// Set this to `false` to prevent the paywall from dismissing on purchase/restore.
  public var automaticallyDismiss = true

  /// Defines the different types of views that can appear behind Apple's payment sheet during a transaction.
  @objc(SWKTransactionBackgroundView)
  public enum TransactionBackgroundView: Int, Encodable, CustomStringConvertible, Sendable {
    /// This shows your paywall background color overlayed with an activity indicator.
    case spinner

    /// Removes the background view during a transaction.
    case none

    public var description: String {
      switch self {
      case .spinner:
        return "spinner"
      case .none:
        return "none"
      }
    }

    private enum CodingKeys: CodingKey {
      case transactionBackgroundView
    }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(description, forKey: .transactionBackgroundView)
    }
  }
  /// The view that appears behind Apple's payment sheet during a transaction. Defaults to `.spinner`.
  ///
  /// Set this to `.none` to remove the background view during a transaction.
  ///
  /// **Note:** This feature is still in development and could change.
  public var transactionBackgroundView: TransactionBackgroundView = .spinner

  private enum CodingKeys: String, CodingKey {
    case isHapticFeedbackEnabled
    case shouldShowPurchaseFailureAlert
    case shouldPreload
    case automaticallyDismiss
    case transactionBackgroundView
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try transactionBackgroundView.encode(to: encoder)
    try restoreFailed.encode(to: encoder)
    try container.encode(isHapticFeedbackEnabled, forKey: .isHapticFeedbackEnabled)
    try container.encode(shouldShowPurchaseFailureAlert, forKey: .shouldShowPurchaseFailureAlert)
    try container.encode(shouldPreload, forKey: .shouldPreload)
    try container.encode(automaticallyDismiss, forKey: .automaticallyDismiss)
  }
}
