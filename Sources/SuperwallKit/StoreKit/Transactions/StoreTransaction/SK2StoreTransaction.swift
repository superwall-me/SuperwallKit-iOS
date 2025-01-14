//
//  File.swift
//
//
//  Created by Yusuf Tör on 07/12/2022.
//

import Foundation
import StoreKit

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
struct SK2StoreTransaction: StoreTransactionType {
  let underlyingSK2Transaction: SK2Transaction

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

  init(transaction: SK2Transaction) {
    self.underlyingSK2Transaction = transaction

    transactionDate = transaction.purchaseDate
    originalTransactionIdentifier = "\(transaction.originalID)"
    state = StoreTransactionState(from: .purchased)
    storeTransactionId = "\(transaction.id)"
    originalTransactionDate = transaction.originalPurchaseDate
    webOrderLineItemID = transaction.webOrderLineItemID
    appBundleId = transaction.appBundleID
    subscriptionGroupId = transaction.subscriptionGroupID
    isUpgraded = transaction.isUpgraded
    expirationDate = transaction.expirationDate
    offerId = transaction.offerID
    revocationDate = transaction.revocationDate
    appAccountToken = transaction.appAccountToken
    payment = StorePayment(from: transaction)
  }
}
