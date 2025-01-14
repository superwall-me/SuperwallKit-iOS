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
import StoreKit

/// TypeAlias to StoreKit 1's Product type, called `StoreKit/SKProduct`
public typealias SK1Product = SKProduct

/// TypeAlias to StoreKit 2's Product type, called `StoreKit.Product`
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public typealias SK2Product = StoreKit.Product

/// A convenience wrapper around a StoreKit 1 or StoreKit 2 product.
@objc(SWKStoreProduct)
@objcMembers
public final class StoreProduct: NSObject, StoreProductType, Sendable {
  let product: StoreProductType

  /// A `Set` of ``Entitlements`` associated with the product.
  public var entitlements: Set<Entitlement> {
    product.entitlements
  }

  /// Returns the `SKProduct` if this `StoreProduct` represents a `StoreKit.SKProduct`.
  public var sk1Product: SK1Product? {
    return (product as? SK1StoreProduct)?.underlyingSK1Product
  }

  /// Returns the `Product` if this `StoreProduct` represents a `StoreKit.Product`.
  @available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  public var sk2Product: SK2Product? {
    return (product as? SK2StoreProduct)?.underlyingSK2Product
  }

  /// The product identifier
  public var productIdentifier: String {
    product.productIdentifier
  }

  /// The product's subscription group id
  public var subscriptionGroupIdentifier: String? {
    return product.subscriptionGroupIdentifier
  }

  /// All the attributes that can be referenced in audience filters.
  ///
  /// Note that `isSubscribed` is added to the attributes right before a paywall is displayed.
  public var attributes: [String: String] {
    return [
      "rawPrice": "\(price)",
      "price": localizedPrice,
      "periodAlt": localizedSubscriptionPeriod,
      "localizedPeriod": localizedSubscriptionPeriod,
      "period": period,
      "periodly": periodly,
      "weeklyPrice": weeklyPrice,
      "dailyPrice": dailyPrice,
      "monthlyPrice": monthlyPrice,
      "yearlyPrice": yearlyPrice,
      "rawTrialPeriodPrice": "\(trialPeriodPrice)",
      "trialPeriodPrice": "\(localizedTrialPeriodPrice)",
      "trialPeriodDailyPrice": trialPeriodPricePerUnit(.day),
      "trialPeriodWeeklyPrice": trialPeriodPricePerUnit(.week),
      "trialPeriodMonthlyPrice": trialPeriodPricePerUnit(.month),
      "trialPeriodYearlyPrice": trialPeriodPricePerUnit(.year),
      "trialPeriodDays": trialPeriodDaysString,
      "trialPeriodWeeks": trialPeriodWeeksString,
      "trialPeriodMonths": trialPeriodMonthsString,
      "trialPeriodYears": trialPeriodYearsString,
      "trialPeriodText": trialPeriodText,
      "trialPeriodEndDate": trialPeriodEndDateString,
      "periodDays": periodDaysString,
      "periodWeeks": periodWeeksString,
      "periodMonths": periodMonthsString,
      "periodYears": periodYearsString,
      "locale": locale,
      "languageCode": languageCode ?? "n/a",
      "currencyCode": currencyCode ?? "n/a",
      "currencySymbol": currencySymbol ?? "n/a",
      "identifier": productIdentifier
    ]
  }

  /// The JSON representation of ``attributes``
  var attributesJson: JSON {
    return JSON(attributes)
  }

  /// An internally used Superwall representation of the product.
  var swProduct: SWProduct {
    product.swProduct
  }

  /// The localized price.
  public var localizedPrice: String {
    product.localizedPrice
  }

  /// The localized subscription period.
  public var localizedSubscriptionPeriod: String {
    product.localizedSubscriptionPeriod
  }

  /// The subscription period unit, e.g. week.
  ///
  /// This returns week, day, month, 2 months, quarter, 6 months and year
  /// depending on the number of units.
  public var period: String {
    product.period
  }

  public var periodly: String {
    product.periodly
  }

  /// The number of weeks in the product's subscription period.
  public var periodWeeks: Int {
    product.periodWeeks
  }

  /// The string value of the number of weeks in the product's subscription period.
  public var periodWeeksString: String {
    product.periodWeeksString
  }

  /// The number of months in the product's subscription period.
  public var periodMonths: Int {
    product.periodMonths
  }

  /// The string value of the number of months in the product's subscription period.
  public var periodMonthsString: String {
    product.periodMonthsString
  }

  /// The number of years in the product's subscription period.
  public var periodYears: Int {
    product.periodYears
  }

  /// The string value of the number of years in the product's subscription period.
  public var periodYearsString: String {
    product.periodYearsString
  }

  /// The number of days in the product's subscription period.
  public var periodDays: Int {
    product.periodDays
  }

  /// The string value of the number of days in the product's subscription period.
  public var periodDaysString: String {
    product.periodDaysString
  }

  /// The product's localized daily price.
  public var dailyPrice: String {
    product.dailyPrice
  }

  /// The product's localized weekly price.
  public var weeklyPrice: String {
    product.weeklyPrice
  }

  /// The product's localized monthly price.
  public var monthlyPrice: String {
    product.monthlyPrice
  }

  /// The product's localized yearly price.
  public var yearlyPrice: String {
    product.yearlyPrice
  }

  /// A boolean indicating whether the product has an introductory price.
  public var hasFreeTrial: Bool {
    product.hasFreeTrial
  }

  /// The product's trial period end date.
  public var trialPeriodEndDate: Date? {
    product.trialPeriodEndDate
  }

  /// The product's trial period end date formatted using `DateFormatter.Style.medium`
  public var trialPeriodEndDateString: String {
    product.trialPeriodEndDateString
  }

  /// The product's introductory price duration in days.
  public var localizedTrialPeriodPrice: String {
    product.localizedTrialPeriodPrice
  }

  /// The product's introductory price duration in days.
  public var trialPeriodPrice: Decimal {
    product.trialPeriodPrice
  }

  /// The product's localized introductory price for a given unit.
  func trialPeriodPricePerUnit(_ unit: SubscriptionPeriod.Unit) -> String {
    return product.trialPeriodPricePerUnit(unit)
  }

  /// The product's introductory price duration in days.
  public var trialPeriodDays: Int {
    product.trialPeriodDays
  }

  /// The product's string value of the introductory price duration in days.
  public var trialPeriodDaysString: String {
    product.trialPeriodDaysString
  }

  /// The product's introductory price duration in weeks.
  public var trialPeriodWeeks: Int {
    product.trialPeriodWeeks
  }

  /// The product's string value of the introductory price duration in weeks.
  public var trialPeriodWeeksString: String {
    product.trialPeriodWeeksString
  }

  /// The product's introductory price duration in months.
  public var trialPeriodMonths: Int {
    product.trialPeriodMonths
  }

  /// The product's string value of the introductory price duration in months.
  public var trialPeriodMonthsString: String {
    product.trialPeriodMonthsString
  }

  /// The product's introductory price duration in years.
  public var trialPeriodYears: Int {
    product.trialPeriodYears
  }

  /// The product's string value of the introductory price duration in years.
  public var trialPeriodYearsString: String {
    product.trialPeriodYearsString
  }

  /// The product's introductory price duration in days, e.g. 7-day.
  public var trialPeriodText: String {
    product.trialPeriodText
  }

  /// The product's locale.
  public var locale: String {
    product.locale
  }

  /// The language code of the product's locale.
  public var languageCode: String? {
    product.languageCode
  }

  /// The currency code of the product's locale.
  public var currencyCode: String? {
    product.currencyCode
  }

  /// The currency symbol of the product's locale.
  public var currencySymbol: String? {
    product.currencySymbol
  }

  /// A boolean that indicates whether the product is family shareable.
  @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
  public var isFamilyShareable: Bool {
    product.isFamilyShareable
  }

  /// The region code of the product's price locale.
  public var regionCode: String? {
    product.regionCode
  }

  /// The price of the product in the local currency.
  @objc(price)
  @available(swift, obsoleted: 1.0)
  public var objcPrice: NSDecimalNumber {
    return product.price as NSDecimalNumber
  }

  /// The price of the product in the local currency.
  @nonobjc public var price: Decimal {
    product.price
  }

  /// The product's subscription period.
  public var subscriptionPeriod: SubscriptionPeriod? {
    product.subscriptionPeriod
  }

  /// The product's introductory discount.
  public var introductoryDiscount: StoreProductDiscount? {
    product.introductoryDiscount
  }

  /// The discounts associated with the product.
  public var discounts: [StoreProductDiscount] {
    product.discounts
  }

  public override func isEqual(_ object: Any?) -> Bool {
    return productIdentifier == (object as? StoreProductType)?.productIdentifier
  }

  /// Designated initializer.
  private init(_ product: StoreProductType) {
    self.product = product
  }

  public override var hash: Int {
    var hasher = Hasher()
    hasher.combine(productIdentifier)
    return hasher.finalize()
  }

  /// Creates an instance from any `StoreProductType`.
  /// If `product` is already a wrapped `StoreProduct` then this returns it instead.
  static func from(product: StoreProductType) -> StoreProduct {
    return product as? StoreProduct ?? StoreProduct(product)
  }

  public convenience init(
    sk1Product: SK1Product
  ) {
    self.init(sk1Product: sk1Product, entitlements: [])
  }

  convenience init(
    sk1Product: SK1Product,
    entitlements: Set<Entitlement>
  ) {
    self.init(SK1StoreProduct(sk1Product: sk1Product, entitlements: entitlements))
  }

  @available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  public convenience init(
    sk2Product: SK2Product
  ) {
    self.init(sk2Product: sk2Product, entitlements: [])
  }

  @available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  convenience init(
    sk2Product: SK2Product,
    entitlements: Set<Entitlement>
  ) {
    self.init(SK2StoreProduct(sk2Product: sk2Product, entitlements: entitlements))
  }
}
