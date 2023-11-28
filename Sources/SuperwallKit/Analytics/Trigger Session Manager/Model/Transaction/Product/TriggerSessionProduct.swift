//
//  File.swift
//  
//
//  Created by Yusuf Tör on 28/04/2022.
//
// swiftlint:disable line_length

import Foundation
import StoreKit

extension TriggerSession.Transaction {
  struct Product: Codable, Equatable {
    /// The index of the product, primary = 0, secondary = 1, tertiary = 2 etc.
    let index: Int

    /// Product identifier
    let identifier: String

    /// The language code of the transacted product, e.g. EN
    let language: String?

    /// The currency of the transacted product, e.g. GBP
    let currency: String?

    /// The region of the transacted product, e.g. UK
    let region: String?

    /// Info about the period of the product
    var period: Period?

    /// The price of the transacted product
    let price: Price

    /// The trial product, if it exists
    var trial: Trial?

    struct Discount: Equatable {
      let priceDescription: String

      /// Equivalent to SKProductDiscount.Type
      let type: StoreProductDiscount.DiscountType
    }
    var discount: Discount?

    let hasIntroductoryOffer: Bool
    let introductoryRedeemable: Bool

    init(
      from product: StoreProduct,
      index: Int
    ) async {
      self.index = index
      self.identifier = product.productIdentifier
      self.language = product.languageCode
      self.currency = product.currencySymbol
      self.region = product.regionCode
      self.price = .init(
        description: product.price.description,
        daily: product.dailyPrice,
        weekly: product.weeklyPrice,
        monthly: product.monthlyPrice,
        yearly: product.yearlyPrice
      )

      if let subscriptionPeriod = product.subscriptionPeriod {
        self.period = .init(
          unit: subscriptionPeriod.unit,
          count: subscriptionPeriod.value,
          days: Int(subscriptionPeriod.daysPerUnit)
        )
      }

      if let introductoryPrice = product.introductoryDiscount {
        let trialSubscriptionPeriod = introductoryPrice.subscriptionPeriod

        self.trial = .init(
          period: .init(
            unit: trialSubscriptionPeriod.unit,
            count: trialSubscriptionPeriod.value,
            days: Int(trialSubscriptionPeriod.daysPerUnit)
          ),
          dailyPrice: trialSubscriptionPeriod.pricePerDay(withTotalPrice: introductoryPrice.price).description,
          weeklyPrice: trialSubscriptionPeriod.pricePerWeek(withTotalPrice: introductoryPrice.price).description,
          monthlyPrice: trialSubscriptionPeriod.pricePerMonth(withTotalPrice: introductoryPrice.price).description,
          yearlyPrice: trialSubscriptionPeriod.pricePerYear(withTotalPrice: introductoryPrice.price).description
        )

        self.discount = .init(
          priceDescription: introductoryPrice.price.description,
          type: introductoryPrice.type
        )

        self.introductoryRedeemable = await Superwall.shared.dependencyContainer.receiptManager.isFreeTrialAvailable(for: product)
        self.hasIntroductoryOffer = true
      } else {
        self.hasIntroductoryOffer = false
        self.introductoryRedeemable = false
      }
    }

    init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      index = try values.decode(Int.self, forKey: .index)
      identifier = try values.decode(String.self, forKey: .identifier)
      language = try values.decodeIfPresent(String.self, forKey: .language)
      currency = try values.decodeIfPresent(String.self, forKey: .currency)
      region = try values.decodeIfPresent(String.self, forKey: .region)
      hasIntroductoryOffer = try values.decode(Bool.self, forKey: .hasIntroductoryOffer)
      introductoryRedeemable = try values.decode(Bool.self, forKey: .introductoryRedeemable)

      let unit = try values.decodeIfPresent(SubscriptionPeriod.Unit.self, forKey: .periodUnit)
      let count = try values.decodeIfPresent(Int.self, forKey: .periodCount)
      let days = try values.decodeIfPresent(Int.self, forKey: .periodDays)

      if let unit = unit,
        let count = count,
        let days = days {
        period = Period(unit: unit, count: count, days: days)
      }

      let discountPrice = try values.decodeIfPresent(String.self, forKey: .discountPrice)
      let discountType = try values.decodeIfPresent(StoreProductDiscount.DiscountType.self, forKey: .discountType)

      if let discountPrice = discountPrice,
        let discountType = discountType {
        discount = Discount(
          priceDescription: discountPrice,
          type: discountType
        )
      }

      price = try Price(from: decoder)
      trial = try? Trial(from: decoder)
    }

    enum CodingKeys: String, CodingKey {
      case index = "transaction_product_index"
      case identifier = "transacting_product_identifier"
      case language = "transacting_product_language"
      case currency = "transacting_product_currency"
      case region = "transacting_product_region"

      case periodUnit = "transacting_product_subscription_period_unit"
      case periodCount = "transacting_product_subscription_period_count"
      case periodDays = "transacting_product_subscription_period_days"

      case discountPrice = "transacting_product_discount_price_str"
      case discountType = "transacting_product_discount_type"

      case introductoryRedeemable = "transacting_product_introductory_redeemable"
      case hasIntroductoryOffer = "transacting_product_has_introductory_offer"
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)

      try price.encode(to: encoder)
      try trial?.encode(to: encoder)

      try container.encode(index, forKey: .index)
      try container.encode(identifier, forKey: .identifier)
      try container.encodeIfPresent(language, forKey: .language)
      try container.encodeIfPresent(currency, forKey: .currency)
      try container.encodeIfPresent(region, forKey: .region)

      try container.encodeIfPresent(period?.unit, forKey: .periodUnit)
      try container.encodeIfPresent(period?.count, forKey: .periodCount)
      try container.encodeIfPresent(period?.days, forKey: .periodDays)

      try container.encode(introductoryRedeemable, forKey: .introductoryRedeemable)
      try container.encode(hasIntroductoryOffer, forKey: .hasIntroductoryOffer)

      try container.encodeIfPresent(discount?.priceDescription, forKey: .discountPrice)
      try container.encodeIfPresent(discount?.type, forKey: .discountType)
    }
  }
}
