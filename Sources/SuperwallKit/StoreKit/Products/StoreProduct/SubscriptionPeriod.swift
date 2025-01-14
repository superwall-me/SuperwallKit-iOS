//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriptionPeriod.swift
//
//  Created by Andrés Boedo on 3/12/21.
//  Updated by Yusuf Tör from Superwall on 11/8/22.

import Foundation
import StoreKit

/// The duration of time between subscription renewals.
/// Use the value and the unit together to determine the subscription period.
/// For example, if the unit is  `.month`, and the value is `3`, the subscription period is three months.
@objc(SWKSubscriptionPeriod)
@objcMembers
public final class SubscriptionPeriod: NSObject, Sendable {
  /// The number of period units.
  public let value: Int
  /// The increment of time that a subscription period is specified in.
  public let unit: Unit

  /// Units of time used to describe subscription periods.
  @objc(SWKSubscriptionPeriodUnit)
  public enum Unit: Int, Codable, Sendable {
    /// A subscription period unit of a day.
    case day = 0
    /// A subscription period unit of a week.
    case week = 1
    /// A subscription period unit of a month.
    case month = 2
    /// A subscription period unit of a year.
    case year = 3
  }

  var daysPerUnit: Double {
    switch unit {
    case .day:
      return 1
    case .week:
      return 7
    case .month:
      return 30
    case .year:
      return 365
    }
  }

  public override var hash: Int {
    var hasher = Hasher()
    hasher.combine(value)
    hasher.combine(unit)
    return hasher.finalize()
  }

  /// Creates a new ``SubscriptionPeriod`` with the given value and unit.
  init(value: Int, unit: Unit) {
    self.value = value
    self.unit = unit
  }

  public override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? SubscriptionPeriod else {
      return false
    }

    return value == other.value && unit == other.unit
  }

  static func from(sk1SubscriptionPeriod: SKProductSubscriptionPeriod) -> SubscriptionPeriod? {
    guard let unit = SubscriptionPeriod.Unit.from(sk1PeriodUnit: sk1SubscriptionPeriod.unit) else {
      return nil
    }

    return .init(value: sk1SubscriptionPeriod.numberOfUnits, unit: unit)
      .normalized()
  }

  @available(iOS 15.0, tvOS 15.0, watchOS 8, *)
  static func from(sk2SubscriptionPeriod: StoreKit.Product.SubscriptionPeriod) -> SubscriptionPeriod? {
    guard let unit = SubscriptionPeriod.Unit.from(sk2PeriodUnit: sk2SubscriptionPeriod.unit) else {
      return nil
    }

    return .init(value: sk2SubscriptionPeriod.value, unit: unit)
      .normalized()
  }

  /// This function simplifies large numbers of days into months and large numbers
  /// of months into years if there are no leftover units after the conversion.
  ///
  /// Occasionally, StoreKit seems to send back a value 7 days for a 7day trial
  /// instead of a value of 1 week for a trial of 7 days in length.
  /// Source: https://github.com/RevenueCat/react-native-purchases/issues/348
  private func normalized() -> SubscriptionPeriod {
    switch unit {
    case .day:
      if value.isMultiple(of: 7) {
        let numberOfWeeks = value / 7
        return .init(value: numberOfWeeks, unit: .week)
      }
    case .month:
      if value.isMultiple(of: 12) {
        let numberOfYears = value / 12
        return .init(value: numberOfYears, unit: .year)
      }
    case .week, .year:
      break
    }
    return self
  }
}

extension SubscriptionPeriod {
  func pricePerDay(withTotalPrice price: Decimal) -> Decimal {
    let periodsPerDay: Decimal = {
      switch self.unit {
      case .day: return 1
      case .week: return 7
      case .month: return 30
      case .year: return 365
      }
    }() * Decimal(value)

    return (price as NSDecimalNumber)
      .dividing(by: periodsPerDay as NSDecimalNumber,
        withBehavior: Self.roundingBehavior) as Decimal
  }

  func pricePerWeek(withTotalPrice price: Decimal) -> Decimal {
    let periodsPerDay: Decimal = {
      switch self.unit {
      case .day: return 1 / 7
      case .week: return 1
      case .month: return 4
      case .year: return 52
      }
    }() * Decimal(value)

    return (price as NSDecimalNumber)
      .dividing(by: periodsPerDay as NSDecimalNumber,
        withBehavior: Self.roundingBehavior) as Decimal
  }

  func pricePerMonth(withTotalPrice price: Decimal) -> Decimal {
    let periodsPerMonth: Decimal = {
      switch self.unit {
      case .day: return 1 / 30
      case .week: return 1 / 4
      case .month: return 1
      case .year: return 12
      }
    }() * Decimal(self.value)

    return (price as NSDecimalNumber)
      .dividing(by: periodsPerMonth as NSDecimalNumber,
        withBehavior: Self.roundingBehavior) as Decimal
  }

  func pricePerYear(withTotalPrice price: Decimal) -> Decimal {
    let periodsPerYear: Decimal = {
      switch self.unit {
      case .day: return 1 / 365
      case .week: return 1 / 52
      case .month: return 1 / 12
      case .year: return 1
      }
    }() * Decimal(self.value)

    return (price as NSDecimalNumber)
      .dividing(by: periodsPerYear as NSDecimalNumber,
        withBehavior: Self.roundingBehavior) as Decimal
  }

  static let roundingBehavior = NSDecimalNumberHandler(
    roundingMode: .down,
    scale: 2,
    raiseOnExactness: false,
    raiseOnOverflow: false,
    raiseOnUnderflow: false,
    raiseOnDivideByZero: false
  )
}

private extension SubscriptionPeriod.Unit {
  static func from(sk1PeriodUnit: SK1Product.PeriodUnit) -> Self? {
    switch sk1PeriodUnit {
    case .day: return .day
    case .week: return .week
    case .month: return .month
    case .year: return .year
    @unknown default: return nil
    }
  }

  @available(iOS 15.0, tvOS 15.0, watchOS 8, *)
  static func from(sk2PeriodUnit: StoreKit.Product.SubscriptionPeriod.Unit) -> Self? {
    switch sk2PeriodUnit {
    case .day: return .day
    case .week: return .week
    case .month: return .month
    case .year: return .year
    @unknown default: return nil
    }
  }
}
