//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SK1StoreProduct.swift
//
//  Created by Nacho Soto on 12/20/21.
//  Updated by Yusuf Tör from Superwall on 11/8/22.
//  swiftlint:disable type_body_length file_length

import Foundation
import StoreKit

struct SK1StoreProduct: StoreProductType {
  private let priceFormatterProvider = PriceFormatterProvider()
  let underlyingSK1Product: SK1Product

  let entitlements: Set<Entitlement>

  var productIdentifier: String {
    return underlyingSK1Product.productIdentifier
  }

  var subscriptionGroupIdentifier: String? {
    underlyingSK1Product.subscriptionGroupIdentifier
  }

  var swProduct: SWProduct {
    return SWProduct(product: underlyingSK1Product)
  }

  var price: Decimal {
    underlyingSK1Product.price as Decimal
  }

  var localizedPrice: String {
    return priceFormatter?.string(from: underlyingSK1Product.price) ?? ""
  }

  var priceFormatter: NumberFormatter? {
    priceFormatterProvider.priceFormatterForSK1(with: underlyingSK1Product.priceLocale)
  }

  var localizedSubscriptionPeriod: String {
    guard let subscriptionPeriod = underlyingSK1Product.subscriptionPeriod else {
      return ""
    }

    let dateComponents: DateComponents

    switch subscriptionPeriod.unit {
    case .day: dateComponents = DateComponents(day: subscriptionPeriod.numberOfUnits)
    case .week: dateComponents = DateComponents(weekOfMonth: subscriptionPeriod.numberOfUnits)
    case .month: dateComponents = DateComponents(month: subscriptionPeriod.numberOfUnits)
    case .year: dateComponents = DateComponents(year: subscriptionPeriod.numberOfUnits)
    @unknown default:
      dateComponents = DateComponents(month: subscriptionPeriod.numberOfUnits)
    }

    return DateComponentsFormatter.localizedString(from: dateComponents, unitsStyle: .short) ?? ""
  }

  var period: String {
    guard let subscriptionPeriod = underlyingSK1Product.subscriptionPeriod else {
      return ""
    }

    if subscriptionPeriod.unit == .day {
      if subscriptionPeriod.numberOfUnits == 7 {
        return "week"
      } else {
        return "day"
      }
    }

    if subscriptionPeriod.unit == .month {
      switch subscriptionPeriod.numberOfUnits {
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
    guard let subscriptionPeriod = underlyingSK1Product.subscriptionPeriod else {
      return ""
    }

    if subscriptionPeriod.unit == .month {
      switch subscriptionPeriod.numberOfUnits {
      case 2, 6:
        return "every \(period)"
      default:
        break
      }
    }

    return "\(period)ly"
  }

  var periodWeeks: Int {
    guard let subscriptionPeriod = underlyingSK1Product.subscriptionPeriod else {
      return 0
    }

    let numberOfUnits = subscriptionPeriod.numberOfUnits

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
    guard let subscriptionPeriod = underlyingSK1Product.subscriptionPeriod else {
      return 0
    }
    let numberOfUnits = subscriptionPeriod.numberOfUnits

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
    guard let subscriptionPeriod = underlyingSK1Product.subscriptionPeriod else {
      return 0
    }
    let numberOfUnits = subscriptionPeriod.numberOfUnits

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
    guard let subscriptionPeriod = underlyingSK1Product.subscriptionPeriod else {
      return 0
    }
    let numberOfUnits = subscriptionPeriod.numberOfUnits

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
    if underlyingSK1Product.price == NSDecimalNumber(decimal: 0.00) {
      return priceFormatter?.string(from: NSDecimalNumber(decimal: 0.00)) ?? "$0.00"
    }

    guard let subscriptionPeriod = self.subscriptionPeriod else {
      return "n/a"
    }

    let inputPrice = underlyingSK1Product.price as Decimal
    let pricePerDay = subscriptionPeriod.pricePerDay(withTotalPrice: inputPrice)

    return priceFormatter?.string(from: NSDecimalNumber(decimal: pricePerDay)) ?? "n/a"
  }

  var weeklyPrice: String {
    if underlyingSK1Product.price == NSDecimalNumber(decimal: 0.00) {
      return priceFormatter?.string(from: NSDecimalNumber(decimal: 0.00)) ?? "$0.00"
    }

    guard let subscriptionPeriod = self.subscriptionPeriod else {
      return "n/a"
    }

    let inputPrice = underlyingSK1Product.price as Decimal
    let pricePerWeek = subscriptionPeriod.pricePerWeek(withTotalPrice: inputPrice)

    return priceFormatter?.string(from: NSDecimalNumber(decimal: pricePerWeek)) ?? "n/a"
  }

  var monthlyPrice: String {
    if underlyingSK1Product.price == NSDecimalNumber(decimal: 0.00) {
      return priceFormatter?.string(from: NSDecimalNumber(decimal: 0.00)) ?? "$0.00"
    }

    guard let subscriptionPeriod = self.subscriptionPeriod else {
      return "n/a"
    }

    let inputPrice = underlyingSK1Product.price as Decimal
    let pricePerMonth = subscriptionPeriod.pricePerMonth(withTotalPrice: inputPrice)

    return priceFormatter?.string(from: NSDecimalNumber(decimal: pricePerMonth)) ?? "n/a"
  }

  var yearlyPrice: String {
    if underlyingSK1Product.price == NSDecimalNumber(decimal: 0.00) {
      return priceFormatter?.string(from: NSDecimalNumber(decimal: 0.00)) ?? "$0.00"
    }

    guard let subscriptionPeriod = self.subscriptionPeriod else {
      return "n/a"
    }

    let inputPrice = underlyingSK1Product.price as Decimal
    let pricePerYear = subscriptionPeriod.pricePerYear(withTotalPrice: inputPrice)

    return priceFormatter?.string(from: NSDecimalNumber(decimal: pricePerYear)) ?? "n/a"
  }

  var hasFreeTrial: Bool {
    return underlyingSK1Product.introductoryPrice != nil
  }

  var trialPeriodEndDate: Date? {
    guard let trialPeriod = underlyingSK1Product.introductoryPrice?.subscriptionPeriod else {
      return nil
    }
    let numberOfUnits = trialPeriod.numberOfUnits

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

  var localizedTrialPeriodPrice: String {
    guard let price = underlyingSK1Product.introductoryPrice?.price else {
      return ""
    }
    return priceFormatter?.string(from: price) ?? "$0.00"
  }

  var trialPeriodPrice: Decimal {
    guard let price = underlyingSK1Product.introductoryPrice?.price else {
      return 0.00
    }
    return price as Decimal
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

  var trialPeriodDays: Int {
    guard let trialPeriod = underlyingSK1Product.introductoryPrice?.subscriptionPeriod else {
      return 0
    }

    let numberOfUnits = trialPeriod.numberOfUnits

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
    guard let trialPeriod = underlyingSK1Product.introductoryPrice?.subscriptionPeriod else {
      return 0
    }
    let numberOfUnits = trialPeriod.numberOfUnits

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
    guard let trialPeriod = underlyingSK1Product.introductoryPrice?.subscriptionPeriod else {
      return 0
    }
    let numberOfUnits = trialPeriod.numberOfUnits

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
    guard let trialPeriod = underlyingSK1Product.introductoryPrice?.subscriptionPeriod else {
      return 0
    }
    let numberOfUnits = trialPeriod.numberOfUnits

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
    guard let trialPeriod = underlyingSK1Product.introductoryPrice?.subscriptionPeriod else {
      return ""
    }

    let units = trialPeriod.numberOfUnits

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
    underlyingSK1Product.priceLocale.identifier
  }

  var languageCode: String? {
    underlyingSK1Product.priceLocale.languageCode
  }

  var currencyCode: String? {
    underlyingSK1Product.priceLocale.currencyCode
  }

  var currencySymbol: String? {
    underlyingSK1Product.priceLocale.currencySymbol
  }

  var regionCode: String? {
    underlyingSK1Product.priceLocale.regionCode
  }

  var subscriptionPeriod: SubscriptionPeriod? {
    guard
      let skSubscriptionPeriod = underlyingSK1Product.subscriptionPeriod,
      skSubscriptionPeriod.numberOfUnits > 0
    else {
      return nil
    }
    return SubscriptionPeriod.from(sk1SubscriptionPeriod: skSubscriptionPeriod)
  }

  var introductoryDiscount: StoreProductDiscount? {
    return self.underlyingSK1Product.introductoryPrice
      .flatMap(StoreProductDiscount.init)
  }

  var discounts: [StoreProductDiscount] {
    return self.underlyingSK1Product.discounts
      .compactMap(StoreProductDiscount.init)
  }

  @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
  var isFamilyShareable: Bool {
    underlyingSK1Product.isFamilyShareable
  }

  init(
    sk1Product: SK1Product,
    entitlements: Set<Entitlement>
  ) {
    self.underlyingSK1Product = sk1Product
    self.entitlements = entitlements
  }
}
