//
//  File.swift
//  
//
//  Created by Yusuf Tör on 07/09/2022.
//

import Foundation

/// Override the default behavior and products of a paywall.
///
/// Provide an instance of this to ``Superwall/getPaywall(forPlacement:params:paywallOverrides:delegate:)``.
@objc(SWKPaywallOverrides)
@objcMembers
public final class PaywallOverrides: NSObject, Sendable {
  /// Defines the products to override on the paywall by product name.
  ///
  /// You can override one or more products of your choosing. For example, this is how you would override the first and third product on the paywall:
  ///
  /// ```
  ///  PaywallOverrides(
  ///    products: [
  ///      "primary": firstProduct,
  ///      "tertiary": thirdProduct
  ///    ]
  ///  )
  /// ```
  ///
  /// This assumes that your products have the names "primary" and "tertiary" in the Paywall Editor.
  public let productsByName: [String: StoreProduct]

  /// Sets a custom presentation style for the paywall.
  public let presentationStyle: PaywallPresentationStyle

  /// An internally used override. This overrides the feature gating behavior of the presented paywall.
  let featureGatingBehavior: FeatureGatingBehavior?

  /// Override the default behavior and products of a paywall.
  ///
  /// You can override one or more products of your choosing. For example, this is how you would override the first and third product on the paywall:
  ///
  /// ```
  ///  PaywallOverrides(
  ///    products: [
  ///      "primary": firstProduct,
  ///      "tertiary": thirdProduct
  ///    ]
  ///  )
  /// ```
  ///
  /// This assumes that your products have the names "primary" and "tertiary" in the Paywall Editor.
  ///
  /// Provide an instance of this to ``Superwall/getPaywall(forPlacement:params:paywallOverrides:delegate:)``.
  ///
  /// - parameters:
  ///   - productsByName: A dictionary mapping the name of the product to override on the paywall with a ``StoreProduct``.
  ///   - presentationStyleOverride: A ``PaywallPresentationStyle`` enum that specifies the presentation style for the paywall.
  public init(
    productsByName: [String: StoreProduct] = [:],
    presentationStyleOverride: PaywallPresentationStyle = .none
  ) {
    self.productsByName = productsByName
    self.presentationStyle = presentationStyleOverride
    self.featureGatingBehavior = nil
  }

  /// Internal init used for overriding the feature gating behavior for implicitly triggered paywalls.
  init(featureGatingBehavior: FeatureGatingBehavior) {
    self.productsByName = [:]
    self.presentationStyle = .none
    self.featureGatingBehavior = featureGatingBehavior
  }

  /// Override the default behavior and products of a paywall.
  ///
  /// You can override one or more products of your choosing. For example, this is how you would override the first and third product on the paywall:
  ///
  /// ```
  ///  PaywallOverrides(
  ///    products: [
  ///      "primary": firstProduct,
  ///      "tertiary": thirdProduct
  ///    ]
  ///  )
  /// ```
  ///
  /// This assumes that your products have the names "primary" and "tertiary" in the Paywall Editor.
  ///
  /// Provide an instance of this to ``Superwall/getPaywall(forPlacement:params:paywallOverrides:delegate:)``.
  ///
  /// - parameters:
  ///   - productsByName: A dictionary mapping the name of the product to override on the paywall with a ``StoreProduct``.
  public init(
    productsByName: [String: StoreProduct]
  ) {
    self.productsByName = productsByName
    self.presentationStyle = .none
    self.featureGatingBehavior = nil
  }
}
