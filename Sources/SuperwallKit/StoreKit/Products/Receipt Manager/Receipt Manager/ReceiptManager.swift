//
//  File.swift
//  
//
//  Created by Yusuf Tör on 24/03/2022.
//

import Foundation
import StoreKit

protocol ReceiptDelegate: AnyObject {
  func syncEntitlements(purchases: Set<Purchase>) async
}

struct Purchase: Hashable {
  let id: String
  let isActive: Bool
  let purchaseDate: Date
}

actor ReceiptManager: NSObject {
  private var receiptRefreshCompletion: ((Bool) -> Void)?
  private unowned let productsManager: ProductsManager
  private weak var receiptDelegate: ReceiptDelegate?
  private let storeKitVersion: SuperwallOptions.StoreKitVersion
  private let manager: ReceiptManagerType

  init(
    storeKitVersion: SuperwallOptions.StoreKitVersion,
    productsManager: ProductsManager,
    receiptManager: ReceiptManagerType? = nil, // For testing
    receiptDelegate: ReceiptDelegate?
  ) {
    self.storeKitVersion = storeKitVersion
    self.productsManager = productsManager

    if let receiptManager = receiptManager {
      self.manager = receiptManager
      return
    }

    if #available(iOS 15.0, *),
      storeKitVersion == .storeKit2 {
      self.manager = Self.versionedManager(storeKitVersion: storeKitVersion)
    } else {
      self.manager = SK1ReceiptManager()
    }

    self.receiptDelegate = receiptDelegate
  }

  static func versionedManager(
    storeKitVersion: SuperwallOptions.StoreKitVersion
  ) -> ReceiptManagerType {
    if #available(iOS 15.0, *),
      storeKitVersion == .storeKit2 {
      return SK2ReceiptManager()
    } else {
      return SK1ReceiptManager()
    }
  }

  /// Loads purchased products from the receipt, storing the purchased subscription group identifiers,
  /// purchases and active purchases.
  func loadPurchasedProducts() async {
    let purchases = await manager.loadPurchases()

    await receiptDelegate?.syncEntitlements(purchases: purchases)

    let purchasedProductIds = Set(purchases.map { $0.id })

    guard let storeProducts = try? await productsManager.products(
      identifiers: purchasedProductIds,
      forPaywall: nil,
      placement: nil
    ) else {
      return
    }

    await manager.loadIntroOfferEligibility(forProducts: storeProducts)
  }

  /// Determines whether a free trial is available based on the product the user is purchasing.
  ///
  /// A free trial is available if the user hasn't already purchased within the subscription group of the
  /// supplied product. If it isn't a subscription-based product or there are other issues retrieving the products,
  /// the outcome will default to whether or not the user has already purchased that product.
  func isFreeTrialAvailable(for storeProduct: StoreProduct) async -> Bool {
    await manager.isEligibleForIntroOffer(storeProduct)
  }

  /// Determines whether the user is subscribed to the given product id.
  func isSubscribed(to productId: String) -> Bool {
    return manager.purchases
      .filter { $0.id == productId }
      .sorted { $0.purchaseDate > $1.purchaseDate }
      .first?
      .isActive == true
  }

  func getActiveProductIds() -> Set<String> {
    return Set(
      manager.purchases
      .filter(\.isActive)
      .map(\.id)
    )
  }

  /// This refreshes the device receipt.
  ///
  /// - Warning: This will prompt the user to log in, so only do this on
  /// when restoring or after purchasing.
  func refreshSK1Receipt() async {
    guard storeKitVersion == .storeKit1 else {
      return
    }
    Logger.debug(
      logLevel: .debug,
      scope: .receipts,
      message: "Refreshing receipts"
    )

    // Don't need the result at the moment.
    _ = await withCheckedContinuation { continuation in
      let refresh = SKReceiptRefreshRequest()
      refresh.delegate = self
      refresh.start()
      receiptRefreshCompletion = { completed in
        continuation.resume(returning: completed)
      }
    }
  }
}

extension ReceiptManager: SKRequestDelegate {
  nonisolated func requestDidFinish(_ request: SKRequest) {
    guard request is SKReceiptRefreshRequest else {
      return
    }
    Logger.debug(
      logLevel: .debug,
      scope: .transactions,
      message: "Receipt refresh request finished.",
      info: ["request": request]
    )
    Task {
      await receiptRefreshCompletion?(true)
    }
    request.cancel()
  }

  nonisolated func request(_ request: SKRequest, didFailWithError error: Error) {
    guard request is SKReceiptRefreshRequest else {
      return
    }
    Logger.debug(
      logLevel: .error,
      scope: .transactions,
      message: "Receipt refresh request failed.",
      info: ["request": request],
      error: error
    )
    Task {
      await receiptRefreshCompletion?(false)
    }
    request.cancel()
  }
}
