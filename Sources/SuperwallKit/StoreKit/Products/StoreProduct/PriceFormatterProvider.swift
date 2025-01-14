//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PriceFormatterProvider.swift
//
//  Created by Juanpe Catalán on 10/3/22.
//  Updated by Yusuf Tör from Superwall on 11/8/22.

import Foundation

/// A `NumberFormatter` provider class for prices.
/// This provider caches the formatter to improve the performance.
final class PriceFormatterProvider {
  private var cachedPriceFormatterForSK1: NumberFormatter?
  private var cachedPriceFormatterForSK2: NumberFormatter?
  private let queue = DispatchQueue(label: "com.superwall.priceformatterprovider", attributes: .concurrent)

  func priceFormatterForSK1(with locale: Locale) -> NumberFormatter {
    queue.sync {
      func makePriceFormatterForSK1(with locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter
      }

      guard
        let formatter = cachedPriceFormatterForSK1,
        formatter.locale == locale
      else {
        let newFormatter = makePriceFormatterForSK1(with: locale)
        cachedPriceFormatterForSK1 = newFormatter
        return newFormatter
      }
      return formatter
    }
  }

  func priceFormatterForSK2(
    withCurrencyCode currencyCode: String,
    locale: Locale = .autoupdatingCurrent
  ) -> NumberFormatter {
    queue.sync {
      func makePriceFormatterForSK2(with currencyCode: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = currencyCode
        return formatter
      }

      guard
        let formatter = cachedPriceFormatterForSK2,
        formatter.currencyCode == currencyCode,
        formatter.locale == locale
      else {
        let newFormatter = makePriceFormatterForSK2(with: currencyCode)
        cachedPriceFormatterForSK2 = newFormatter

        return newFormatter
      }

      return formatter
    }
  }
}

// It's unchecked here because we're using a queue to serialise access to the caches.
extension PriceFormatterProvider: @unchecked Sendable {}
