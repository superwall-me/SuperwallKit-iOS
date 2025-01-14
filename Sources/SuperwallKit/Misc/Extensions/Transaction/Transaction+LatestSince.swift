//
//  File.swift
//  
//
//  Created by Yusuf Tör on 18/09/2023.
//

import StoreKit

@available(iOS 15.0, *)
extension Transaction {
  /// Gets the latest transaction for a given `productId` since
  /// an hour up to a given `purchaseDate`.
  static func latest(
    for productId: String,
    since purchaseDate: Date
  ) async -> VerificationResult<Transaction>? {
    let verificationResult = await Transaction.latest(for: productId)

    if let transaction = verificationResult.map({ $0.unsafePayloadValue }),
      transaction.purchaseDate.isWithinAnHourBefore(purchaseDate) {
      return verificationResult
    }

    return nil
  }
}
