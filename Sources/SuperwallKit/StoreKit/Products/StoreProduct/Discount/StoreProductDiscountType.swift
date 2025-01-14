//
//  File.swift
//  
//
//  Created by Yusuf Tör on 05/01/2023.
//

import Foundation

/// The details of an introductory offer or a promotional offer for an auto-renewable subscription.
protocol StoreProductDiscountType {
  /// A string used to uniquely identify a discount offer for a product.
  var offerIdentifier: String? { get }

  /// The currency of the product's price.
  var currencyCode: String? { get }

  /// The discount price of the product in the local currency.
  var price: Decimal { get }

  /// The price of this product discount formatted for locale.
  var localizedPriceString: String { get }

  /// The payment mode for this product discount.
  var paymentMode: StoreProductDiscount.PaymentMode { get }

  /// The period for the product discount.
  var subscriptionPeriod: SubscriptionPeriod { get }

  /// The number of periods the product discount is available.
  /// This is `1` for ``StoreProductDiscount/PaymentMode-swift.enum/payUpFront``
  /// and ``StoreProductDiscount/PaymentMode-swift.enum/freeTrial``, but can be
  /// more than 1 for ``StoreProductDiscount/PaymentMode-swift.enum/payAsYouGo``.
  ///
  /// - Note:
  /// A product discount may be available for one or more periods.
  /// The period, defined in `subscriptionPeriod`, is a set number of days, weeks, months, or years.
  /// The total length of time that a product discount is available is calculated by
  /// multiplying the `numberOfPeriods` by the period.
  /// Note that the discount period is independent of the product subscription period.
  var numberOfPeriods: Int { get }

  /// The type of product discount.
  var type: StoreProductDiscount.DiscountType { get }
}
