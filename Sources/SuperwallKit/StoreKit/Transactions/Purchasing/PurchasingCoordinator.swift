//
//  File.swift
//  
//
//  Created by Yusuf Tör on 14/09/2023.
//

import Foundation
import StoreKit

/// An actor that manages and coordinates the storing of types associated with purchasing.
actor PurchasingCoordinator {
  var lastInternalTransaction: StoreTransaction?
  var purchaseDate: Date?
  var source: PurchaseSource?
  var transactions: [String: StoreTransaction] = [:]
  var isFreeTrialAvailable = false
  var product: StoreProduct?
  private var completion: ((PurchaseResult) -> Void)?
  private let factory: StoreTransactionFactory

  init(factory: StoreTransactionFactory) {
    self.factory = factory
  }

  func setIsFreeTrialAvailable(to newValue: Bool) {
    isFreeTrialAvailable = newValue
  }

  /// A boolean indicating whether the given `date` is within an hour of the `purchaseDate`.
  func dateIsWithinLastHour(_ transactionDate: Date?) -> Bool {
    guard
      let transactionDate = transactionDate,
      let purchaseDate = purchaseDate
    else {
      return false
    }
    return transactionDate.isWithinAnHourBefore(purchaseDate)
  }

  func setCompletion(_ completion: @escaping (PurchaseResult) -> Void) {
    self.completion = completion
  }

  func beginPurchase(
    of product: StoreProduct,
    source: PurchaseSource,
    isFreeTrialAvailable: Bool
  ) {
    self.purchaseDate = Date()
    self.source = source
    self.isFreeTrialAvailable = isFreeTrialAvailable
    self.product = product
  }

  /// Gets the latest transaction of a specified product ID. Used with purchases, including when a purchase has
  /// resulted in a restore.
  func getLatestTransaction(
    forProductId productId: String,
    factory: StoreTransactionFactory
  ) async -> StoreTransaction? {
    // Get the date a purchase was initiated. This can never be nil after
    // a purchase.
    guard let purchaseDate = purchaseDate else {
      return nil
    }

    // If on iOS 15+, try and get latest transaction using SK2.
    if #available(iOS 15.0, *) {
      if let verificationResult = await Transaction.latest(
        for: productId,
        since: purchaseDate
      ) {
        // Skip verification step as this has already been done.
        let transaction = verificationResult.unsafePayloadValue
        return await factory.makeStoreTransaction(from: transaction)
      }
    }

    // If no transaction retrieved, try to get last transaction if
    // the SDK handled purchasing.
    if let transaction = lastInternalTransaction {
      lastInternalTransaction = nil
      return transaction
    }

    func getLastExternalStoreTransaction() async -> StoreTransaction? {
      if let transaction = transactions[productId],
        dateIsWithinLastHour(transaction.transactionDate) {
        return transaction
      }
      return nil
    }

    // Otherwise get the last externally purchased
    // transaction from the payment queue. This won't work
    // with a purchase that results in a restore. That
    // should be caught by the above  instead.
    if let transaction = await getLastExternalStoreTransaction() {
      return transaction
    }

    // If still no transaction, wait 500ms and try again before returning nil.
    try? await Task.sleep(nanoseconds: 500_000_000)

    if let transaction = await getLastExternalStoreTransaction() {
      return transaction
    }

    return nil
  }

  /// Stores the transaction if purchased and is the latest for a specific product ID.
  /// This is used as a fallback if we can't retrieve the transaction using SK2.
  func storeIfPurchased(_ transaction: StoreTransaction) {
    guard case .purchased = transaction.state else {
      return
    }
    let productId = transaction.payment.productIdentifier

    // If there is an existing transaction, which has a transaction date...
    if let existingTransaction = transactions[productId],
      let existingTransactionDate = existingTransaction.transactionDate {
      // And if the new transaction date was after the stored transaction, update.
      // Else, ignore.
      if transaction.transactionDate?.compare(existingTransactionDate) == .orderedDescending {
        transactions[productId] = transaction
      }
    } else {
      // If there isn't an existing transaction, store.
      transactions[productId] = transaction
    }
  }

  func completePurchase(
    of transaction: SK1Transaction,
    result: PurchaseResult
  ) async {
    let transaction = await factory.makeStoreTransaction(from: transaction)
    completePurchase(of: transaction, result: result)
  }

  @available(iOS 15.0, *)
  func completePurchase(
    of transaction: SK2Transaction,
    result: PurchaseResult
  ) async {
    let transaction = await factory.makeStoreTransaction(from: transaction)
    completePurchase(of: transaction, result: result)
  }

  private func completePurchase(
    of transaction: StoreTransaction,
    result: PurchaseResult
  ) {
    if result == .purchased {
      storeIfPurchased(transaction)
    }
    // Only complete if the product ID of the transaction is the same as
    // the purchasing transaction.
    guard product?.productIdentifier == transaction.payment.productIdentifier else {
      return
    }
    // If the transaction completed a purchase, check it is within the last
    // hour since starting purchase. Otherwise old purchased products may come
    // through and complete the purchase.
    if result == .purchased {
      guard dateIsWithinLastHour(transaction.transactionDate) else {
        return
      }
    }
    lastInternalTransaction = transaction
    completion?(result)
  }

  func reset() {
    purchaseDate = nil
    completion = nil
    product = nil
    source = nil
    isFreeTrialAvailable = false
  }
}
