//
//  File.swift
//
//
//  Created by Yusuf Tör on 27/05/2022.
//

import Foundation
import StoreKit

/// The payment for the transaction.
@objc(SWKStorePayment)
@objcMembers
public final class StorePayment: NSObject, Encodable, Sendable {
  /// The ID of a product being bought.
  public let productIdentifier: String

  /// The number of items the user wants to purchase.
  public let quantity: Int

  /// The ID for the discount offer to apply to the payment.
  public let discountIdentifier: String?

  init(from payment: SKPayment) {
    self.productIdentifier = payment.productIdentifier
    self.quantity = payment.quantity
    self.discountIdentifier = payment.paymentDiscount?.identifier
  }

  @available(iOS 15.0, *)
  init(from transaction: Transaction) {
    self.productIdentifier = transaction.productID
    self.quantity = transaction.purchasedQuantity
    self.discountIdentifier = nil
  }
}
