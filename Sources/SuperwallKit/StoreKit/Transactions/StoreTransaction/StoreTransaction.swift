//
//  File.swift
//
//
//  Created by Yusuf Tör on 07/12/2022.
//

import Foundation
import StoreKit

/// TypeAlias to StoreKit 1's Transaction type, called `StoreKit/SKPaymentTransaction`
public typealias SK1Transaction = SKPaymentTransaction

/// TypeAlias to StoreKit 2's Transaction type, called `StoreKit.Transaction`
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public typealias SK2Transaction = StoreKit.Transaction

/// A convenience wrapper around a StoreKit 1 or StoreKit 2 transaction.
@objc(SWKStoreTransaction)
@objcMembers
public final class StoreTransaction: NSObject, StoreTransactionType, Encodable {
  /// A string that uniquely identifies the transaction. Used on the server.
  private let id = UUID().uuidString
  private let transaction: StoreTransactionType

  public let configRequestId: String
  public let appSessionId: String

  public var transactionDate: Date? { transaction.transactionDate }
  public var originalTransactionIdentifier: String { transaction.originalTransactionIdentifier }
  public var state: StoreTransactionState { transaction.state }
  public var storeTransactionId: String? { transaction.storeTransactionId }
  public var payment: StorePayment { transaction.payment }
  public var originalTransactionDate: Date? { transaction.originalTransactionDate }
  public var webOrderLineItemID: String? { transaction.webOrderLineItemID }
  public var appBundleId: String? { transaction.appBundleId }
  public var subscriptionGroupId: String? { transaction.subscriptionGroupId }
  public var isUpgraded: Bool? { transaction.isUpgraded }
  public var expirationDate: Date? { transaction.expirationDate }
  public var offerId: String? { transaction.offerId }
  public var revocationDate: Date? { transaction.revocationDate }
  public var appAccountToken: UUID? { transaction.appAccountToken }

  /// Returns the `SKPaymentTransaction` if this `StoreTransaction` represents a `SKPaymentTransaction`.
  public var sk1Transaction: SK1Transaction? {
    return (self.transaction as? SK1StoreTransaction)?.underlyingSK1Transaction
  }

  /// Returns the `StoreKit.Transaction` if this `StoreTransaction` represents a `StoreKit.Transaction`.
  @available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  public var sk2Transaction: SK2Transaction? {
    return (self.transaction as? SK2StoreTransaction)?.underlyingSK2Transaction
  }

  init(
    transaction: StoreTransactionType,
    configRequestId: String,
    appSessionId: String
  ) {
    self.transaction = transaction
    self.configRequestId = configRequestId
    self.appSessionId = appSessionId
  }

  public enum CodingKeys: String, CodingKey {
    case id
    case configRequestId
    case appSessionId
    case transactionDate
    case originalTransactionIdentifier
    case state
    case storeTransactionId
    case payment
    case originalTransactionDate
    case webOrderLineItemID
    case appBundleId
    case subscriptionGroupId
    case isUpgraded
    case expirationDate
    case offerId
    case revocationDate
    case appAccountToken
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(configRequestId, forKey: .configRequestId)
    try container.encode(appSessionId, forKey: .appSessionId)
    try container.encodeIfPresent(transactionDate, forKey: .transactionDate)
    try container.encode(originalTransactionIdentifier, forKey: .originalTransactionIdentifier)
    try container.encode(state, forKey: .state)
    try container.encodeIfPresent(storeTransactionId, forKey: .storeTransactionId)
    try container.encode(payment, forKey: .payment)
    try container.encodeIfPresent(originalTransactionDate, forKey: .originalTransactionDate)
    try container.encodeIfPresent(webOrderLineItemID, forKey: .webOrderLineItemID)
    try container.encodeIfPresent(appBundleId, forKey: .appBundleId)
    try container.encodeIfPresent(subscriptionGroupId, forKey: .subscriptionGroupId)
    try container.encodeIfPresent(isUpgraded, forKey: .isUpgraded)
    try container.encodeIfPresent(expirationDate, forKey: .expirationDate)
    try container.encodeIfPresent(offerId, forKey: .offerId)
    try container.encodeIfPresent(revocationDate, forKey: .revocationDate)
    try container.encodeIfPresent(appAccountToken, forKey: .appAccountToken)
    try container.encode(id, forKey: .id)
  }
}

// MARK: - Stubbable
extension StoreTransaction: Stubbable {
  static func stub() -> StoreTransaction {
    return StoreTransaction(
      transaction: SK1StoreTransaction(transaction: SKPaymentTransaction()),
      configRequestId: "abc",
      appSessionId: "def"
    )
  }
}
