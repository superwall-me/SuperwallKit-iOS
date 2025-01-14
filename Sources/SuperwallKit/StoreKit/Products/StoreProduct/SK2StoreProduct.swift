//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SK2StoreProduct.swift
//
//  Created by Nacho Soto on 12/20/21.
//  Updated by Yusuf Tör from Superwall on 11/8/22.
//  swiftlint:disable type_body_length file_length

import Foundation
import StoreKit

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct SK2StoreProduct: StoreProductType {
  private let priceFormatterProvider = PriceFormatterProvider()
  let entitlements: Set<Entitlement>

  init(
    sk2Product: SK2Product,
    entitlements: Set<Entitlement>
  ) {
    #if swift(<5.7)
    self._underlyingSK2Product = sk2Product
    #else
    self.underlyingSK2Product = sk2Product
    #endif
    self.entitlements = entitlements
  }

  #if swift(<5.7)
  // We can't directly store instances of StoreKit.Product, since that causes
  // linking issues in iOS < 15, even with @available checks correctly in place.
  // So instead, we store the underlying product as Any and wrap it with casting.
  private let _underlyingSK2Product: Any
  var underlyingSK2Product: SK2Product {
    // swiftlint:disable:next force_cast
    _underlyingSK2Product as! SK2Product
  }
  #else
  let underlyingSK2Product: SK2Product
  #endif

  var productIdentifier: String {
    underlyingSK2Product.id
  }

  var subscriptionGroupIdentifier: String? {
    underlyingSK2Product.subscription?.subscriptionGroupID
  }

  var swProduct: SWProduct {
    return SWProduct(product: underlyingSK2Product)
  }

  var localizedPrice: String {
    return priceFormatter(locale: underlyingSK2Product.priceFormatStyle.locale)
      .string(from: underlyingSK2Product.price as NSDecimalNumber) ?? "?"
  }

  var priceFormatter: NumberFormatter? {
    guard let currencyCode = self.currencyCode else {
      return nil
    }
    return priceFormatterProvider.priceFormatterForSK2(
      withCurrencyCode: currencyCode,
      locale: underlyingSK2Product.priceFormatStyle.locale
    )
  }

  private func priceFormatter(locale: Locale) -> NumberFormatter {
    let formatter = NumberFormatter()
    formatter.locale = underlyingSK2Product.priceFormatStyle.locale
    formatter.numberStyle = .currency
    return formatter
  }

  var localizedSubscriptionPeriod: String {
    guard let subscriptionPeriod = underlyingSK2Product.subscription?.subscriptionPeriod else {
      return ""
    }

    let dateComponents: DateComponents

    switch subscriptionPeriod.unit {
    case .day: dateComponents = DateComponents(day: subscriptionPeriod.value)
    case .week: dateComponents = DateComponents(weekOfMonth: subscriptionPeriod.value)
    case .month: dateComponents = DateComponents(month: subscriptionPeriod.value)
    case .year: dateComponents = DateComponents(year: subscriptionPeriod.value)
    @unknown default:
      dateComponents = DateComponents(month: subscriptionPeriod.value)
    }

    return DateComponentsFormatter.localizedString(from: dateComponents, unitsStyle: .short) ?? ""
  }

  var period: String {
    guard let subscriptionPeriod = underlyingSK2Product.subscription?.subscriptionPeriod else {
      return ""
    }

    if subscriptionPeriod.unit == .day {
      if subscriptionPeriod.value == 7 {
        return "week"
      } else {
        return "day"
      }
    }

    if subscriptionPeriod.unit == .month {
      switch subscriptionPeriod.value {
      case 2:
        return "2 months"
      case 3:
        return "quarter"
      case 6:
        return "6 months"
      default:
        return "month"
      }
    }

    if subscriptionPeriod.unit == .week {
      return "week"
    }

    if subscriptionPeriod.unit == .year {
      return "year"
    }

    return ""
  }

  var periodly: String {
    guard let subscriptionPeriod = underlyingSK2Product.subscription?.subscriptionPeriod else {
      return ""
    }

    if subscriptionPeriod.unit == .month {
      switch subscriptionPeriod.value {
      case 2, 6:
        return "every \(period)"
      default:
        break
      }
    }

    return "\(period)ly"
  }

  var periodWeeks: Int {
    guard let subscriptionPeriod = underlyingSK2Product.subscription?.subscriptionPeriod else {
      return 0
    }

    let numberOfUnits = subscriptionPeriod.value

    if subscriptionPeriod.unit == .day {
      return (1 * numberOfUnits) / 7
    }

    if subscriptionPeriod.unit == .week {
      return numberOfUnits
    }

    if subscriptionPeriod.unit == .month {
      return 4 * numberOfUnits
    }

    if subscriptionPeriod.unit == .year {
      return 52 * numberOfUnits
    }

    return 0
  }

  var periodWeeksString: String {
    return "\(periodWeeks)"
  }

  var periodMonths: Int {
    guard let subscriptionPeriod = underlyingSK2Product.subscription?.subscriptionPeriod else {
      return 0
    }
    let numberOfUnits = subscriptionPeriod.value

    if subscriptionPeriod.unit == .day {
      return (1 * numberOfUnits) / 30
    }

    if subscriptionPeriod.unit == .week {
      return numberOfUnits / 4
    }

    if subscriptionPeriod.unit == .month {
      return numberOfUnits
    }

    if subscriptionPeriod.unit == .year {
      return 12 * numberOfUnits
    }

    return 0
  }

  var periodMonthsString: String {
    return "\(periodMonths)"
  }

  var periodYears: Int {
    guard let subscriptionPeriod = underlyingSK2Product.subscription?.subscriptionPeriod else {
      return 0
    }
    let numberOfUnits = subscriptionPeriod.value

    if subscriptionPeriod.unit == .day {
      return numberOfUnits / 365
    }

    if subscriptionPeriod.unit == .week {
      return numberOfUnits / 52
    }

    if subscriptionPeriod.unit == .month {
      return numberOfUnits / 12
    }

    if subscriptionPeriod.unit == .year {
      return numberOfUnits
    }

    return 0
  }

  var periodYearsString: String {
    return "\(periodYears)"
  }

  var periodDays: Int {
    guard let subscriptionPeriod = underlyingSK2Product.subscription?.subscriptionPeriod else {
      return 0
    }
    let numberOfUnits = subscriptionPeriod.value

    if subscriptionPeriod.unit == .day {
      return numberOfUnits
    }

    if subscriptionPeriod.unit == .week {
      return 7 * numberOfUnits
    }

    if subscriptionPeriod.unit == .month {
      return 30 * numberOfUnits
    }

    if subscriptionPeriod.unit == .year {
      return 365 * numberOfUnits
    }

    return 0
  }

  var periodDaysString: String {
    return "\(periodDays)"
  }

  var dailyPrice: String {
    if underlyingSK2Product.price == 0.00 {
      return "$0.00"
    }

    let numberFormatter = NumberFormatter()
    let locale = underlyingSK2Product.priceFormatStyle.locale
    numberFormatter.numberStyle = .currency
    numberFormatter.locale = locale

    guard let subscriptionPeriod = underlyingSK2Product.subscription?.subscriptionPeriod else {
      return "n/a"
    }
    let numberOfUnits = subscriptionPeriod.value
    var periods: Decimal = 1.0
    let inputPrice = underlyingSK2Product.price

    if subscriptionPeriod.unit == .year {
      periods = Decimal(365 * numberOfUnits)
    }

    if subscriptionPeriod.unit == .month {
      periods = Decimal(30 * numberOfUnits)
    }

    if subscriptionPeriod.unit == .week {
      periods = Decimal(numberOfUnits) / Decimal(7)
    }

    if subscriptionPeriod.unit == .day {
      periods = Decimal(numberOfUnits) / Decimal(1)
    }

    return numberFormatter.string(from: NSDecimalNumber(decimal: inputPrice / periods)) ?? "n/a"
  }

  var weeklyPrice: String {
    if underlyingSK2Product.price == 0.00 {
      return "$0.00"
    }

    let numberFormatter = NumberFormatter()
    let locale = underlyingSK2Product.priceFormatStyle.locale
    numberFormatter.numberStyle = .currency
    numberFormatter.locale = locale

    guard let subscriptionPeriod = underlyingSK2Product.subscription?.subscriptionPeriod else {
      return "n/a"
    }
    let numberOfUnits = subscriptionPeriod.value
    var periods: Decimal = 1.0
    let inputPrice = underlyingSK2Product.price

    if subscriptionPeriod.unit == .year {
      periods = Decimal(52 * numberOfUnits)
    }

    if subscriptionPeriod.unit == .month {
      periods = Decimal(4 * numberOfUnits)
    }

    if subscriptionPeriod.unit == .week {
      periods = Decimal(numberOfUnits) / Decimal(1)
    }

    if subscriptionPeriod.unit == .day {
      periods = Decimal(numberOfUnits) / Decimal(7)
    }

    return numberFormatter.string(from: NSDecimalNumber(decimal: inputPrice / periods)) ?? "n/a"
  }

  var monthlyPrice: String {
    if underlyingSK2Product.price == 0.00 {
      return "$0.00"
    }

    let numberFormatter = NumberFormatter()
    let locale = underlyingSK2Product.priceFormatStyle.locale
    numberFormatter.numberStyle = .currency
    numberFormatter.locale = locale

    guard let subscriptionPeriod = underlyingSK2Product.subscription?.subscriptionPeriod else {
      return "n/a"
    }

    let numberOfUnits = subscriptionPeriod.value
    var periods: Decimal = 1.0
    let inputPrice = underlyingSK2Product.price

    if subscriptionPeriod.unit == .year {
      periods = Decimal(12 * numberOfUnits)
    }

    if subscriptionPeriod.unit == .month {
      periods = Decimal(1 * numberOfUnits)
    }

    if subscriptionPeriod.unit == .week {
      periods = Decimal(numberOfUnits) / Decimal(4)
    }

    if subscriptionPeriod.unit == .day {
      periods = Decimal(numberOfUnits) / Decimal(30)
    }

    return numberFormatter.string(from: NSDecimalNumber(decimal: inputPrice / periods)) ?? "n/a"
  }

  var yearlyPrice: String {
    if underlyingSK2Product.price == 0.00 {
      return "$0.00"
    }

    let numberFormatter = NumberFormatter()
    let locale = underlyingSK2Product.priceFormatStyle.locale
    numberFormatter.numberStyle = .currency
    numberFormatter.locale = locale

    guard let subscriptionPeriod = underlyingSK2Product.subscription?.subscriptionPeriod else {
      return "n/a"
    }

    let numberOfUnits = subscriptionPeriod.value
    var periods: Decimal = 1.0
    let inputPrice = underlyingSK2Product.price

    if subscriptionPeriod.unit == .year {
      periods = Decimal(numberOfUnits)
    }

    if subscriptionPeriod.unit == .month {
      periods = Decimal(numberOfUnits) / Decimal(12)
    }

    if subscriptionPeriod.unit == .week {
      periods = Decimal(numberOfUnits) / Decimal(52)
    }

    if subscriptionPeriod.unit == .day {
      periods = Decimal(numberOfUnits) / Decimal(365)
    }

    return numberFormatter.string(from: NSDecimalNumber(decimal: inputPrice / periods)) ?? "n/a"
  }

  var hasFreeTrial: Bool {
    return underlyingSK2Product.subscription?.introductoryOffer != nil
  }

  var trialPeriodEndDate: Date? {
    guard let trialPeriod = underlyingSK2Product.subscription?.introductoryOffer?.period else {
      return nil
    }
    let numberOfUnits = trialPeriod.value

    let currentDate = Date()
    var dateComponent = DateComponents()

    switch trialPeriod.unit {
    case .day:
      dateComponent.day = numberOfUnits
    case .week:
      dateComponent.day = 7 * numberOfUnits
    case .month:
      dateComponent.month = numberOfUnits
    case .year:
      dateComponent.year = numberOfUnits
    @unknown default:
      return nil
    }

    guard let futureDate = Calendar.current.date(
      byAdding: dateComponent,
      to: currentDate
    ) else {
      return nil
    }

    return futureDate
  }

  var trialPeriodEndDateString: String {
    if let trialPeriodEndDate = trialPeriodEndDate {
      let dateFormatter = DateFormatter()
      dateFormatter.dateStyle = .medium
      dateFormatter.timeStyle = .none
      dateFormatter.locale = .autoupdatingCurrent

      return dateFormatter.string(from: trialPeriodEndDate)
    }
    return ""
  }

  var trialPeriodDays: Int {
    guard let trialPeriod = underlyingSK2Product.subscription?.introductoryOffer?.period else {
      return 0
    }

    let numberOfUnits = trialPeriod.value

    if trialPeriod.unit == .day {
      return Int(1 * numberOfUnits)
    }

    if trialPeriod.unit == .month {
      return Int(30 * numberOfUnits)
    }

    if trialPeriod.unit == .week {
      return Int(7 * numberOfUnits)
    }

    if trialPeriod.unit == .year {
      return Int(365 * numberOfUnits)
    }

    return 0
  }

  var trialPeriodDaysString: String {
    return "\(trialPeriodDays)"
  }

  var trialPeriodWeeks: Int {
    guard let trialPeriod = underlyingSK2Product.subscription?.introductoryOffer?.period else {
      return 0
    }
    let numberOfUnits = trialPeriod.value

    if trialPeriod.unit == .day {
      return Int(numberOfUnits / 7)
    }

    if trialPeriod.unit == .month {
      return 4 * numberOfUnits
    }

    if trialPeriod.unit == .week {
      return 1 * numberOfUnits
    }

    if trialPeriod.unit == .year {
      return 52 * numberOfUnits
    }

    return 0
  }

  var trialPeriodWeeksString: String {
    return "\(trialPeriodWeeks)"
  }

  var trialPeriodMonths: Int {
    guard let trialPeriod = underlyingSK2Product.subscription?.introductoryOffer?.period else {
      return 0
    }
    let numberOfUnits = trialPeriod.value

    if trialPeriod.unit == .day {
      return Int(numberOfUnits / 30)
    }

    if trialPeriod.unit == .month {
      return numberOfUnits * 1
    }

    if trialPeriod.unit == .week {
      return Int(numberOfUnits / 4)
    }

    if trialPeriod.unit == .year {
      return numberOfUnits * 12
    }

    return 0
  }

  var trialPeriodMonthsString: String {
    return "\(trialPeriodMonths)"
  }

  var trialPeriodYears: Int {
    guard let trialPeriod = underlyingSK2Product.subscription?.introductoryOffer?.period else {
      return 0
    }
    let numberOfUnits = trialPeriod.value

    if trialPeriod.unit == .day {
      return Int(numberOfUnits / 365)
    }

    if trialPeriod.unit == .month {
      return Int(numberOfUnits / 12)
    }

    if trialPeriod.unit == .week {
      return Int(numberOfUnits / 52)
    }

    if trialPeriod.unit == .year {
      return numberOfUnits
    }

    return 0
  }

  var trialPeriodYearsString: String {
    return "\(trialPeriodYears)"
  }

  var trialPeriodText: String {
    guard let trialPeriod = underlyingSK2Product.subscription?.introductoryOffer?.period else {
      return ""
    }

    let units = trialPeriod.value

    if trialPeriod.unit == .day {
      return "\(units)-day"
    }

    if trialPeriod.unit == .month {
      return "\(units * 30)-day"
    }

    if trialPeriod.unit == .week {
      return "\(units * 7)-day"
    }

    if trialPeriod.unit == .year {
      return "\(units * 365)-day"
    }

    return ""
  }

  var locale: String {
    underlyingSK2Product.priceFormatStyle.locale.identifier
  }

  var languageCode: String? {
    underlyingSK2Product.priceFormatStyle.locale.languageCode
  }

  var currencyCode: String? {
    underlyingSK2Product.priceFormatStyle.locale.currencyCode
  }

  var currencySymbol: String? {
    underlyingSK2Product.priceFormatStyle.locale.currencySymbol
  }

  var regionCode: String? {
    underlyingSK2Product.priceFormatStyle.locale.regionCode
  }

  var price: Decimal {
    underlyingSK2Product.price
  }

  var isFamilyShareable: Bool {
    underlyingSK2Product.isFamilyShareable
  }

  var subscriptionPeriod: SubscriptionPeriod? {
    guard let skSubscriptionPeriod = underlyingSK2Product.subscription?.subscriptionPeriod else {
      return nil
    }
    return SubscriptionPeriod.from(sk2SubscriptionPeriod: skSubscriptionPeriod)
  }

  var introductoryDiscount: StoreProductDiscount? {
    underlyingSK2Product.subscription?.introductoryOffer
      .flatMap { StoreProductDiscount(sk2Discount: $0, currencyCode: currencyCode) }
  }

  var discounts: [StoreProductDiscount] {
    (underlyingSK2Product.subscription?.promotionalOffers ?? [])
      .compactMap { StoreProductDiscount(sk2Discount: $0, currencyCode: currencyCode) }
  }

  var trialPeriodPrice: Decimal {
    underlyingSK2Product.subscription?.introductoryOffer?.price ?? 0.00
  }

  func trialPeriodPricePerUnit(_ unit: SubscriptionPeriod.Unit) -> String {
    guard let introductoryDiscount = introductoryDiscount else {
      return priceFormatter?.string(from: 0.00) ?? "$0.00"
    }
    if introductoryDiscount.price == 0.00 {
      return priceFormatter?.string(from: 0.00) ?? "$0.00"
    }

    let introMonthlyPrice = introductoryDiscount.pricePerUnit(unit)

    return priceFormatter?.string(from: NSDecimalNumber(decimal: introMonthlyPrice)) ?? "$0.00"
  }

  var localizedTrialPeriodPrice: String {
    guard let price = underlyingSK2Product.subscription?.introductoryOffer?.price else {
      return priceFormatter?.string(from: 0.00) ?? "$0.00"
    }
    return priceFormatter?.string(from: price as NSDecimalNumber) ?? "$0.00"
  }
}

// MARK: - Hashable
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension SK2StoreProduct: Hashable {
  static func == (lhs: SK2StoreProduct, rhs: SK2StoreProduct) -> Bool {
    return lhs.underlyingSK2Product == rhs.underlyingSK2Product
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.underlyingSK2Product)
  }
}
