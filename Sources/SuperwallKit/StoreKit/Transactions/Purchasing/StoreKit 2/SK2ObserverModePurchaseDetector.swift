//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2ObserverModePurchaseDetector.swift
//
//  Created by Will Taylor on 5/1/24.
//  Modified by Yusuf Tor

import Foundation
import StoreKit

/// A delegate protocol for handling verified transactions in observer mode.
@available(iOS 17.2, *)
protocol SK2ObserverModePurchaseDetectorDelegate: AnyObject {
  /// Handles a verified transaction.
  /// - Parameters:
  ///   - transaction: The verified transaction to be processed.
  func logSK2ObserverModeTransaction(
    _ transaction: SK2Transaction
  ) async throws
}

/// Actor responsibile for detecting purchases from StoreKit2 that should be processed by observer mode.
@available(iOS 17.2, *)
actor SK2ObserverModePurchaseDetector {
  private let storage: Storage
  private let allTransactionsProvider: AllTransactionsProviderType
  private var cacheLegacyTransactionTask: Task<Void, Never>?
  private let factory: Factory
  typealias Factory = PurchasedTransactionsFactory & OptionsFactory

  init(
    storage: Storage,
    allTransactionsProvider: AllTransactionsProviderType,
    factory: Factory
  ) {
    self.storage = storage
    self.allTransactionsProvider = allTransactionsProvider
    self.factory = factory
  }

  func cacheLegacyTransactions() {
    cacheLegacyTransactionTask = Task {
      await self.cacheLegacyTransactions()
    }
  }

  private func cacheLegacyTransactions() async {
    let didCacheLegacyTransactions = storage.get(DidCacheLegacyTransactions.self) ?? false
    if didCacheLegacyTransactions {
      return
    }
    let allTransactions = await allTransactionsProvider.getAllTransactions()
    let legacyTransactionIDs = Set(allTransactions.map { $0.underlyingTransaction.id })
    storage.save(legacyTransactionIDs, forType: SK2TransactionIds.self)
    storage.save(true, forType: DidCacheLegacyTransactions.self)
  }

  /// Detects unobserved transactions and forwards them to the delegate for processing.
  func detectUnobservedTransactions(
    delegate: SK2ObserverModePurchaseDetectorDelegate
  ) async {
    // Make sure legacy transactions pre SDK upgrade are cached.
    guard let cacheLegacyTransactionTask = cacheLegacyTransactionTask else {
      return
    }
    await cacheLegacyTransactionTask.value

    let coordinator = factory.makePurchasingCoordinator()
    let source = await coordinator.source

    // Check that a Superwall purchase hasn't already started.
    // This could race with a transactionDidSucceed, however, in that function
    // we insert the transaction ID into the cache. That means that even if it
    // races, we won't continue. This needs to be here incase this calls before
    // transactionDidSucceed.
    guard source == nil else {
      return
    }

    let allTransactions = await allTransactionsProvider.getAllTransactions()

    // Clear saved transaction IDs if empty transaction list, e.g. if removed from Xcode transactions.
    if allTransactions.isEmpty {
      storage.delete(SK2TransactionIds.self)
    }

    guard let mostRecentTransaction = await allTransactionsProvider.getMostRecentVerifiedTransaction(
      from: allTransactions
    ) else {
      // Exit early if no verified transactions are found
      return
    }

    // Extract the verified transaction object
    guard let transaction = mostRecentTransaction.verifiedTransaction else {
      // Exit early if the transaction could not be verified
      return
    }

    // Fetch cached transaction IDs that have already been synced
    let cachedTxnIds = storage.get(SK2TransactionIds.self) ?? []

    // If the current transaction ID is already synced, exit early
    if cachedTxnIds.contains(transaction.id) {
      return
    }

    // Identify transaction IDs that haven't been synced yet
    let unsyncedTransactionIDs = allTransactions
      .filter {
        // Only keep transactions whose IDs are not in the cached synced IDs
        !cachedTxnIds.contains($0.underlyingTransaction.id)
      }
      .map {
        // Extract the IDs of the unsynced transactions
        $0.underlyingTransaction.id
      }
    do {
      // Update the cache with the new synced transaction IDs
      insertToCachedTransactionIds(Set(unsyncedTransactionIDs))

      // Check that the transaction reason is purchase and not renewal.
      guard transaction.reason == .purchase else {
        return
      }

      // Delegate the handling of the verified transaction for observer mode
      try await delegate.logSK2ObserverModeTransaction(transaction)
    } catch {
      Logger.debug(
        logLevel: .error,
        scope: .transactions,
        message: "Superwall could not process transaction completed by your app: \(error)"
      )
    }
  }

  func insertToCachedTransactionIds(_ ids: Set<UInt64>) {
    let options = factory.makeSuperwallOptions()
    guard options.shouldObservePurchases else {
      return
    }
    var cachedTxnIds = storage.get(SK2TransactionIds.self) ?? []
    cachedTxnIds.formUnion(ids)
    storage.save(cachedTxnIds, forType: SK2TransactionIds.self)
  }
}

/// A wrapper protocol that allows for abstracting out calls to an `AsyncSequence<VerificationResult<Transaction>>`.
/// This will usually be `Transaction.all` in production but allows us to inject custom AsyncSequences for testing.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
protocol AllTransactionsProviderType: Sendable {
  func getAllTransactions() async -> [StoreKit.VerificationResult<StoreKit.Transaction>]
  func getMostRecentVerifiedTransaction(
    from transactions: [StoreKit.VerificationResult<StoreKit.Transaction>]
  ) async -> StoreKit.VerificationResult<StoreKit.Transaction>?
}

/// A concretete implementation of `AllTransactionsProviderType` that fetches
/// transactions from StoreKit's ``StoreKit/Transaction/all``
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct SK2AllTransactionsProvider: AllTransactionsProviderType, Sendable {
  func getAllTransactions() async -> [StoreKit.VerificationResult<StoreKit.Transaction>] {
    return await StoreKit.Transaction.all.extractValues()
  }

  func getMostRecentVerifiedTransaction(
    from transactions: [StoreKit.VerificationResult<StoreKit.Transaction>]
  ) async -> StoreKit.VerificationResult<StoreKit.Transaction>? {
    let verifiedTransactions = transactions.filter { transaction in
      return transaction.verifiedTransaction != nil
    }
    if verifiedTransactions.isEmpty { return nil }
    guard let mostRecentTransaction = verifiedTransactions.max(by: {
      $0.verifiedTransaction?.purchaseDate ?? .distantPast < $1.verifiedTransaction?.purchaseDate ?? .distantPast
    }) else { return nil }

    return mostRecentTransaction
  }
}
