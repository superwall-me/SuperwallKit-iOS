//
//  AutomaticPurchaseController.swift
//
//
//  Created by Yusuf Tör on 29/08/2023.
//

import Foundation
import StoreKit

final class AutomaticPurchaseController {
  private let factory: DependencyContainer

  private var productPurchaser: ProductPurchaserSK1 {
    return factory.productsPurchaser
  }

  private var receiptManager: ReceiptManager {
    return factory.receiptManager
  }

  init(factory: DependencyContainer) {
    self.factory = factory
  }

  func syncSubscriptionStatus(withPurchases purchases: Set<InAppPurchase>) async {
    let activePurchases = purchases.filter { $0.isActive }
    await MainActor.run {
      if activePurchases.isEmpty {
        Superwall.shared.subscriptionStatus = .inactive
      } else {
        Superwall.shared.subscriptionStatus = .active
      }
    }
  }
}

// MARK: - PurchaseController

extension AutomaticPurchaseController: PurchaseController {
  @MainActor
  func purchase(product: SKProduct) async -> PurchaseResult {
    await productPurchaser.coordinator.beginPurchase(
      of: product.productIdentifier
    )
    return await productPurchaser.purchase(product: product)
  }

  @MainActor
  func restorePurchases() async -> RestorationResult {
    let result = await productPurchaser.restorePurchases()

    let hasRestored = result == .restored
    await receiptManager.refreshReceipt()
    if hasRestored {
      await receiptManager.loadPurchasedProducts()
    }

    return result
  }
}

// MARK: - InternalPurchaseControllable

extension AutomaticPurchaseController: InternalPurchaseController {
  var isInternal: Bool { return true }
}

// MARK: - ReceiptDelegate

extension AutomaticPurchaseController: ReceiptDelegate {
  func receiptLoaded(purchases: Set<InAppPurchase>) async {
    await syncSubscriptionStatus(withPurchases: purchases)
  }
}
