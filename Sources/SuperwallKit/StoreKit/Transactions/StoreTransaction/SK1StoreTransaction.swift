//
//  File.swift
//
//
//  Created by Yusuf Tör on 07/12/2022.
//
// swiftlint:disable strict_fileprivate

import StoreKit

struct SK1StoreTransaction: StoreTransactionType {
  let underlyingSK1Transaction: SK1Transaction

  let transactionDate: Date?
  let originalTransactionIdentifier: String
  let state: StoreTransactionState
  let storeTransactionId: String?
  let originalTransactionDate: Date?
  let webOrderLineItemID: String?
  let appBundleId: String?
  let subscriptionGroupId: String?
  let isUpgraded: Bool?
  let expirationDate: Date?
  let offerId: String?
  let revocationDate: Date?
  let appAccountToken: UUID?
  let payment: StorePayment

  init(transaction: SK1Transaction) {
    self.underlyingSK1Transaction = transaction

    transactionDate = transaction.transactionDate
    originalTransactionIdentifier = transaction.transactionID
    state = StoreTransactionState(from: transaction.transactionState)
    storeTransactionId = transaction.transactionIdentifier
    originalTransactionDate = nil
    webOrderLineItemID = nil
    appBundleId = nil
    subscriptionGroupId = nil
    isUpgraded = nil
    expirationDate = nil
    offerId = nil
    revocationDate = nil
    appAccountToken = nil
    payment = StorePayment(from: transaction.payment)
  }
}

extension SKPaymentTransaction {
  fileprivate var transactionID: String {
    guard let identifier = self.transactionIdentifier else {
      return UUID().uuidString
    }

    return identifier
  }
}
