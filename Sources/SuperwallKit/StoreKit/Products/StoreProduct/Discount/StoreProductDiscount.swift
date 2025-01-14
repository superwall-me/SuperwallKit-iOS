//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreProductDiscount.swift
//
//  Created by Joshua Liebowitz on 7/2/21.
//  Updated by Yusuf Tör from Superwall on 11/8/22.
// swiftlint:disable strict_fileprivate

import StoreKit

/// TypeAlias to StoreKit 1's Discount type, called `SKProductDiscount`
public typealias SK1ProductDiscount = SKProductDiscount

/// TypeAlias to StoreKit 2's Discount type, called `StoreKit.Product.SubscriptionOffer`
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public typealias SK2ProductDiscount = StoreKit.Product.SubscriptionOffer

/// Type that wraps `StoreKit.Product.SubscriptionOffer` and `SKProductDiscount`
/// and provides access to their properties.
/// Information about a subscription offer that you configured in App Store Connect.
@objc(SWKStoreProductDiscount)
@objcMembers
public final class StoreProductDiscount: NSObject, StoreProductDiscountType {
  /// The payment mode for a `StoreProductDiscount`
  /// Indicates how the product discount price is charged.
  @objc(SWKPaymentMode)
  public enum PaymentMode: Int, Sendable {
    /// Price is charged one or more times
    case payAsYouGo = 0
    /// Price is charged once in advance
    case payUpFront = 1
    /// No initial charge
    case freeTrial = 2
  }

  /// The discount type for a `StoreProductDiscount`
  /// Wraps `SKProductDiscount.Type` if this `StoreProductDiscount` represents a `SKProductDiscount`.
  /// Wraps  `Product.SubscriptionOffer.OfferType` if this `StoreProductDiscount` represents
  /// a `Product.SubscriptionOffer`.
  @objc(SWKDiscountType)
  public enum DiscountType: Int, Codable, Sendable {
    /// Introductory offer
    case introductory = 0
    /// Promotional offer for subscriptions
    case promotional = 1
  }

  private let discount: StoreProductDiscountType

  init(_ discount: StoreProductDiscountType) {
    self.discount = discount
  }

  public var offerIdentifier: String? { self.discount.offerIdentifier }
  public var currencyCode: String? { self.discount.currencyCode }
  @nonobjc public var price: Decimal { self.discount.price }

  /// The discount price of the product in the local currency.
  @objc(price)
  @available(swift, obsoleted: 1.0)
  public var objcPrice: NSDecimalNumber {
    return price as NSDecimalNumber
  }

  public var localizedPriceString: String { self.discount.localizedPriceString }
  public var paymentMode: PaymentMode { self.discount.paymentMode }
  public var subscriptionPeriod: SubscriptionPeriod { self.discount.subscriptionPeriod }
  public var numberOfPeriods: Int { self.discount.numberOfPeriods }
  public var type: DiscountType { self.discount.type }

  /// Creates an instance from any `StoreProductDiscountType`.
  /// If `discount` is already a wrapped `StoreProductDiscount` then this returns it instead.
  static func from(discount: StoreProductDiscountType) -> StoreProductDiscount {
    return discount as? StoreProductDiscount
    ?? StoreProductDiscount(discount)
  }

  public override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? StoreProductDiscountType else { return false }

    return Data(discount: self) == Data(discount: other)
  }

  public override var hash: Int {
    return id.hashValue
  }
}

extension StoreProductDiscount {
  func pricePerUnit(_ unit: SubscriptionPeriod.Unit) -> Decimal {
    switch paymentMode {
    case .freeTrial:
      return 0.00
    case .payAsYouGo,
      .payUpFront:
      /// The total cost that you'll pay
      let introCost = price * Decimal(numberOfPeriods)

      /// The number of total units normalised to the unit you want.
      let introPeriods = periodsPerUnit(unit) * Decimal(numberOfPeriods) * Decimal(subscriptionPeriod.value)

      let introPayment: Decimal
      if introPeriods < 1 {
        // If less than 1, it means the intro period doesn't exceed a full unit, therefore you'd pay the
        // full intro cost within the unit. E.g. if the unit is month, but the intro discount is 3 weeks at 0.99,
        // the introPeriods would be < 1 and the cost for the month would be 3 * 0.99 = 2.97.
        introPayment = introCost
      } else {
        // Otherwise, divide the total cost by the normalised intro periods.
        introPayment = (introCost as NSDecimalNumber)
          .dividing(
            by: introPeriods as NSDecimalNumber,
            withBehavior: SubscriptionPeriod.roundingBehavior
          ) as Decimal
      }

      return introPayment
    }
  }

  func periodsPerUnit(_ unit: SubscriptionPeriod.Unit) -> Decimal {
    switch unit {
    case .day:
      switch subscriptionPeriod.unit {
      case .day: return 1
      case .week: return 7
      case .month: return 30
      case .year: return 365
      }
    case .week:
      switch subscriptionPeriod.unit {
      case .day: return 1 / 7
      case .week: return 1
      case .month: return 4
      case .year: return 52
      }
    case .month:
      switch subscriptionPeriod.unit {
      case .day: return 1 / 30
      case .week: return 1 / 4
      case .month: return 1
      case .year: return 12
      }
    case .year:
      switch subscriptionPeriod.unit {
      case .day: return 1 / 365
      case .week: return 1 / 52
      case .month: return 1 / 12
      case .year: return 1
      }
    }
  }
}

extension StoreProductDiscount {
  /// Used to represent ``id``.
  public struct Data: Hashable {
    private var offerIdentifier: String?
    private var currencyCode: String?
    private var price: Decimal
    private var localizedPriceString: String
    private var paymentMode: StoreProductDiscount.PaymentMode
    private var subscriptionPeriod: SubscriptionPeriod
    private var numberOfPeriods: Int
    private var type: StoreProductDiscount.DiscountType

    fileprivate init(discount: StoreProductDiscountType) {
      self.offerIdentifier = discount.offerIdentifier
      self.currencyCode = discount.currencyCode
      self.price = discount.price
      self.localizedPriceString = discount.localizedPriceString
      self.paymentMode = discount.paymentMode
      self.subscriptionPeriod = discount.subscriptionPeriod
      self.numberOfPeriods = discount.numberOfPeriods
      self.type = discount.type
    }
  }
}

// MARK: - Wrapper constructors / getters

extension StoreProductDiscount {
  convenience init?(sk1Discount: SK1ProductDiscount) {
    guard let discount = SK1StoreProductDiscount(sk1Discount: sk1Discount) else {
      return nil
    }
    self.init(discount)
  }

  @available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  convenience init?(sk2Discount: SK2ProductDiscount, currencyCode: String?) {
    guard
      let discount = SK2StoreProductDiscount(
        sk2Discount: sk2Discount,
        currencyCode: currencyCode
      )
    else {
      return nil
    }
    self.init(discount)
  }

  /// Returns the `SK1ProductDiscount` if this `StoreProductDiscount` represents a `SKProductDiscount`.
  public var sk1Discount: SK1ProductDiscount? {
    return (self.discount as? SK1StoreProductDiscount)?.underlyingSK1Discount
  }

  /// Returns the `SK2ProductDiscount` if this `StoreProductDiscount` represents a `Product.SubscriptionOffer`.
  @available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  public var sk2Discount: SK2ProductDiscount? {
    return (self.discount as? SK2StoreProductDiscount)?.underlyingSK2Discount
  }
}

extension StoreProductDiscount.DiscountType {
  static func from(sk1Discount: SK1ProductDiscount) -> Self? {
    switch sk1Discount.type {
    case .introductory:
      return .introductory
    case .subscription:
      return .promotional
    @unknown default:
      return nil
    }
  }

  @available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  static func from(sk2Discount: SK2ProductDiscount) -> Self? {
    switch sk2Discount.type {
    case SK2ProductDiscount.OfferType.introductory:
      return .introductory
    case SK2ProductDiscount.OfferType.promotional:
      return .promotional
    default:
      return nil
    }
  }
}

// MARK: - Identifiable
extension StoreProductDiscount: Identifiable {
  /// The stable identity of the entity associated with this instance.
  public var id: Data { return Data(discount: self) }
}

extension SK1ProductDiscount {
  // See https://github.com/RevenueCat/purchases-ios/issues/1521
  // Despite `SKProductDiscount.priceLocale` being non-optional, StoreKit might return `nil` `NSLocale`s.
  // This works around that to make sure the SDK doesn't crash when bridging to `Locale`.
  var optionalLocale: Locale? {
    guard let locale = priceLocale as NSLocale? else {
      return nil
    }

    return locale as Locale
  }
}
