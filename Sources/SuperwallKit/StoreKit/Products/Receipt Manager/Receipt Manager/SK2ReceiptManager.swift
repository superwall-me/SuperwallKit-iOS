//
//  File.swift
//  SuperwallKit
//
//  Created by Yusuf Tör on 19/09/2024.
//

import Foundation
import StoreKit

protocol ReceiptManagerType: AnyObject {
  var purchases: Set<Purchase> { get }

  func loadIntroOfferEligibility(forProducts storeProducts: Set<StoreProduct>) async
  func loadPurchases() async -> Set<Purchase>
  func isEligibleForIntroOffer(_ storeProduct: StoreProduct) async -> Bool
}

@available(iOS 15.0, *)
final class SK2ReceiptManager: ReceiptManagerType {
  private var sk2IntroOfferEligibility: [String: Bool] = [:]
  var purchases: Set<Purchase> = []

  func loadIntroOfferEligibility(forProducts storeProducts: Set<StoreProduct>) async {
    for storeProduct in storeProducts {
      sk2IntroOfferEligibility[storeProduct.productIdentifier] = await isEligibleForIntroOffer(storeProduct)
    }
  }

  func loadPurchases() async -> Set<Purchase> {
    var purchases: Set<Purchase> = []
    // Iterate through the user's purchased products.
    for await verificationResult in Transaction.all {
      switch verificationResult {
      case .verified(let transaction):
        // If already expired, set as inactive
        if let expirationDate = transaction.expirationDate {
          if expirationDate < Date() {
            purchases.insert(
              Purchase(
                id: transaction.productID,
                isActive: false,
                purchaseDate: transaction.purchaseDate
              )
            )
            continue
          }
        }
        purchases.insert(
          Purchase(
            id: transaction.productID,
            isActive: true,
            purchaseDate: transaction.purchaseDate
          )
        )
      case let .unverified(transaction, error):
        Logger.debug(
          logLevel: .warn,
          scope: .transactions,
          message: "The purchased transactions contains an unverified transaction "
            + "\(transaction.debugDescription). \(error.localizedDescription)"
        )
      }
    }
    self.purchases = purchases
    return purchases
  }

  func isEligibleForIntroOffer(_ storeProduct: StoreProduct) async -> Bool {
    guard let product = storeProduct.product as? SK2StoreProduct else {
      return false
    }
    if let eligibility = sk2IntroOfferEligibility[storeProduct.productIdentifier] {
      return eligibility
    }
    guard product.hasFreeTrial else {
      return false
    }
    let sk2Product = product.underlyingSK2Product
    guard let renewableSubscription = sk2Product.subscription else {
      // Technically this is covered in hasFreeTrial, but good for unwrapping subscription
      return false
    }
    if await renewableSubscription.isEligibleForIntroOffer {
      // The product is eligible for an introductory offer.
      return true
    }
    return false
  }
}
