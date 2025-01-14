//
//  File.swift
//  
//
//  Created by Yusuf Tör on 13/12/2022.
//

import Foundation
import StoreKit

/// The protocol that handles Superwall's subscription-related logic.
///
/// By default, the Superwall SDK handles all subscription-related logic. However, if you'd like more
/// control, you can return a ``PurchaseController`` when configuring the SDK via
/// ``Superwall/configure(apiKey:purchaseController:options:completion:)-52tke``.
///
/// When implementing this, you also need to set the entitlements using
/// `Superwall.shared.entitlements.set(_:)`.
///
/// To learn how to implement the ``PurchaseController`` in your app
/// and best practices, see [Purchases and Entitlements](https://docs.superwall.com/docs/advanced-configuration).
public protocol PurchaseController: AnyObject {
  /// Called when the user initiates purchasing of a product.
  ///
  /// Add your purchase logic here and return its result. You can use Apple's StoreKit APIs,
  /// or if you use RevenueCat, you can call [`Purchases.shared.purchase(product:)`](https://revenuecat.github.io/purchases-ios-docs/4.13.4/documentation/revenuecat/purchases/purchase(product:completion:)).
  /// - Parameters:
  ///   - product: The ``StoreProduct`` the user would like to purchase.
  ///
  /// - Returns: A``PurchaseResult`` object, which is the result of your purchase logic.
  /// **Note**: Make sure you handle all cases of ``PurchaseResult``.
  @MainActor
  func purchase(product: StoreProduct) async -> PurchaseResult

  /// Called when the user initiates a restore.
  ///
  /// Add your restore logic here, making sure that the user's entitlements are updated after restore,
  /// and return its result.
  ///
  /// - Returns: A ``RestorationResult`` that's `.restored` if the user's purchases were restored or `.failed(Error?)` if they weren't.
  /// **Note**: `restored` does not imply the user has an active subscription, it just mean the restore had no errors.
  @MainActor
  func restorePurchases() async -> RestorationResult
}
