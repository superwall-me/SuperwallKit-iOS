//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2TransactionFetcher.swift
//
//  Created by Nacho Soto on 5/24/23.

import StoreKit

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension StoreKit.VerificationResult where SignedType == StoreKit.Transaction {
  var verifiedTransaction: StoreKit.Transaction? {
    switch self {
    case let .verified(transaction): return transaction
    case .unverified: return nil
    }
  }

  var underlyingTransaction: StoreKit.Transaction {
    switch self {
    case let .unverified(transaction, _): return transaction
    case let .verified(transaction): return transaction
    }
  }
}
