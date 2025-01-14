//
//  File.swift
//
//
//  Created by Yusuf Tör on 07/12/2022.
//

import Foundation
import StoreKit

protocol StoreTransactionType: Sendable {
  /// The date that App Store charged the user’s account for a purchased or restored product,
  /// or for a subscription purchase or renewal after a lapse.
  var transactionDate: Date? { get }

  /// The unique identifier for the transaction.
  var originalTransactionIdentifier: String { get }

  var state: StoreTransactionState { get }

  var storeTransactionId: String? { get }

  /// Info about the payment associated with the transaction
  var payment: StorePayment { get }

  // MARK: iOS 15 only properties
  /// The date of purchase for the original transaction.
  var originalTransactionDate: Date? { get }

  /// The date of purchase for the original transaction.
  var webOrderLineItemID: String? { get }

  /// The bundle identifier for the app.
  var appBundleId: String? { get }

  /// The identifier of the subscription group that the subscription belongs to.
  var subscriptionGroupId: String? { get }

  /// A Boolean that indicates whether the user upgraded to another subscription.
  var isUpgraded: Bool? { get }

  /// The date the subscription expires or renews.
  var expirationDate: Date? { get }

  /// A string that identifies an offer applied to the current subscription.
  var offerId: String? { get }

  /// The date that App Store refunded the transaction or revoked it from family sharing.
  var revocationDate: Date? { get }

  /// A UUID that associates the transaction with a user on your own service.
  var appAccountToken: UUID? { get }
}

public enum StoreTransactionState: String, Codable, Sendable {
  case purchasing = "PURCHASING"
  case purchased = "PURCHASED"
  case failed = "FAILED"
  case restored = "RESTORED"
  case deferred = "DEFERRED"

  init(from transactionState: SKPaymentTransactionState) {
    switch transactionState {
    case .deferred:
      self = .deferred
    case .failed:
      self = .failed
    case .purchased:
      self = .purchased
    case .purchasing:
      self = .purchasing
    case .restored:
      self = .restored
    @unknown default:
      self = .purchasing
    }
  }
}
