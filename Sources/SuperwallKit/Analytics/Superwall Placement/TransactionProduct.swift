//
//  File.swift
//  
//
//  Created by Yusuf Tör on 14/11/2022.
//

import Foundation
import StoreKit

/// The product involved in the transaction.
public struct TransactionProduct: Sendable {
  /// The product identifier.
  public let id: String

  public struct Price: Sendable {
    /// The raw price of the product.
    ///
    /// For example, "29.99".
    public let raw: Decimal

    /// The price localized to the currency of the device.
    ///
    /// For example, "£29.99".
    public let localized: String

    /// The daily cost of the product.
    ///
    /// For example, "£0.99".
    public let daily: String

    /// The weekly cost of the product.
    ///
    /// For example, "£1.99".
    public let weekly: String

    /// The monthly cost of the product.
    ///
    /// For example, "£2.99".
    public let monthly: String

    /// The yearly cost of the product.
    ///
    /// For example, "£29.99".
    public let yearly: String
  }

  /// Attributes associated with the price of the product.
  public let price: Price

  /// The trial period of the product
  public struct TrialPeriod: Sendable {
    /// The number of days the trial period lasts.
    public let days: Int

    /// The number of weeks the trial period lasts.
    public let weeks: Int

    /// The number of months the trial period lasts.
    public let months: Int

    /// The number of years the trial period lasts.
    public let years: Int

    /// The number of day the trial period lasts in the format "X-day".
    ///
    /// For example, for a seven day trial, it would be "7-day".
    public let text: String

    /// The end date of the trial period.
    public let endAt: Date?
  }

  /// The trial period of the product.
  public var trialPeriod: TrialPeriod?

  /// The subscription period of the product.
  public struct Period: Sendable {
    /// The shortened representation of the duration of the subscription.
    ///
    /// For example, "1 year".
    public let alt: String

    // swiftlint:disable identifier_name
    /// The subscription period with -ly added on the end.
    ///
    /// For example, "weekly".
    public let ly: String
    // swiftlint:enable identifier_name

    /// The value representing the duration of the product interval, from a day up to a year.
    ///
    /// For example, `.day`.
    public let unit: SubscriptionPeriod.Unit

    /// The number of days the subscription lasts.
    public let days: Int

    /// The number of weeks the subscription lasts.
    public let weeks: Int

    /// The number of months the subscription lasts.
    public let months: Int

    /// The number of years the subscription lasts.
    public let years: Int
  }

  /// The subscription period of the product.
  public var period: Period?

  /// The identifier of the locale of the product.
  public let locale: String

  /// The language code of the product locale, or nil if has none.
  ///
  /// For example, for the locale “zh-Hant-HK”, returns “zh”.
  public var languageCode: String?

  /// The currency of the product.
  public struct Currency: Sendable {
    /// The currency code of the product.
    ///
    /// For example, for “zh-Hant-HK”, returns “HKD”.
    public let code: String?

    /// The currency symbol of the product.
    ///
    /// For example, for “zh-Hant-HK”, returns “HK$”.
    public let symbol: String?
  }

  /// The currency of the product.
  public let currency: Currency

  init(product: StoreProduct) {
    id = product.productIdentifier
    price = Price(
      raw: product.price as Decimal,
      localized: product.localizedPrice,
      daily: product.dailyPrice,
      weekly: product.weeklyPrice,
      monthly: product.monthlyPrice,
      yearly: product.yearlyPrice
    )

    if let endAt = product.trialPeriodEndDate {
      trialPeriod = TrialPeriod(
        days: product.trialPeriodDays,
        weeks: product.trialPeriodWeeks,
        months: product.trialPeriodMonths,
        years: product.trialPeriodYears,
        text: product.trialPeriodText,
        endAt: endAt
      )
    }

    if let subscriptionPeriod = product.subscriptionPeriod {
      period = Period(
        alt: product.localizedSubscriptionPeriod,
        ly: "\(product.period)ly",
        unit: subscriptionPeriod.unit,
        days: product.periodDays,
        weeks: product.periodWeeks,
        months: product.periodMonths,
        years: product.periodYears
      )
    }

    locale = product.locale
    languageCode = product.languageCode

    currency = Currency(
      code: product.currencyCode,
      symbol: product.currencySymbol
    )
  }
}
