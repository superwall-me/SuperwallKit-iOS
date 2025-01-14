//
// Copyright RevenueCat Inc. All Rights Reserved.
//
// Licensed under the MIT License (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// opensource.org/licenses/MIT
//
// StoreProduct.swift
//
// Created by Andrés Boedo on 7/16/21.
// Updated by Yusuf Tör from Superwall on 11/8/22.

import Foundation

/// Type that provides access to all of `StoreKit`'s product type's properties.
protocol StoreProductType: Sendable {
  /// The string that identifies the product to the Apple App Store.
  var productIdentifier: String { get }

  var entitlements: Set<Entitlement> { get }

  var price: Decimal { get }

  var subscriptionGroupIdentifier: String? { get }

  var swProduct: SWProduct { get }

  var localizedPrice: String { get }

  var localizedSubscriptionPeriod: String { get }

  var period: String { get }

  var periodly: String { get }

  var periodWeeks: Int { get }

  var periodWeeksString: String { get }

  var periodMonths: Int { get }

  var periodMonthsString: String { get }

  var periodYears: Int { get }

  var periodYearsString: String { get }

  var periodDays: Int { get }

  var periodDaysString: String { get }

  var dailyPrice: String { get }

  var weeklyPrice: String { get }

  var monthlyPrice: String { get }

  var yearlyPrice: String { get }

  var hasFreeTrial: Bool { get }

  var trialPeriodEndDate: Date? { get }

  var trialPeriodEndDateString: String { get }

  var localizedTrialPeriodPrice: String { get }

  var trialPeriodPrice: Decimal { get }

  func trialPeriodPricePerUnit(_ unit: SubscriptionPeriod.Unit) -> String

  var trialPeriodDays: Int { get }

  var trialPeriodDaysString: String { get }

  var trialPeriodWeeks: Int { get }

  var trialPeriodWeeksString: String { get }

  var trialPeriodMonths: Int { get }

  var trialPeriodMonthsString: String { get }

  var trialPeriodYears: Int { get }

  var trialPeriodYearsString: String { get }

  var trialPeriodText: String { get }

  var locale: String { get }

  var languageCode: String? { get }

  var currencyCode: String? { get }

  var currencySymbol: String? { get }

  var regionCode: String? { get }

  /// A Boolean value that indicates whether the product is available for family sharing in App Store Connect.
  /// Check the value of `isFamilyShareable` to learn whether an in-app purchase is sharable with the family group.
  ///
  /// When displaying in-app purchases in your app, indicate whether the product includes Family Sharing
  /// to help customers make a selection that best fits their needs.
  ///
  /// Configure your in-app purchases to allow Family Sharing in App Store Connect.
  /// For more information about setting up Family Sharing, see Turn-on Family Sharing for in-app purchases.
  ///
  /// #### Related Articles
  /// - https://support.apple.com/en-us/HT201079
  @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
  var isFamilyShareable: Bool { get }

  /// The period details for products that are subscriptions.
  /// - Returns: `nil` if the product is not a subscription.
  var subscriptionPeriod: SubscriptionPeriod? { get }

  /// The object containing introductory price information for the product.
  /// If you've set up introductory prices in App Store Connect, the introductory price property will be populated.
  /// This property is `nil` if the product has no introductory price.
  ///
  /// Before displaying UI that offers the introductory price,
  /// you must first determine if the user is eligible to receive it.
  /// #### Related Symbols
  /// - ``Purchases/checkTrialOrIntroDiscountEligibility(productIdentifiers:)`` to  determine eligibility.
  var introductoryDiscount: StoreProductDiscount? { get }

  /// An array of subscription offers available for the auto-renewable subscription.
  /// - Note: the current user may or may not be eligible for some of these.
  /// #### Related Symbols
  /// - ``Purchases/promotionalOffer(forProductDiscount:product:)``
  /// - ``Purchases/getPromotionalOffer(forProductDiscount:product:completion:)``
  /// - ``Purchases/eligiblePromotionalOffers(forProduct:)``
  /// - ``StoreProduct/eligiblePromotionalOffers()``
  var discounts: [StoreProductDiscount] { get }
}
