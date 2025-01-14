//
//  File.swift
//  SuperwallKit
//
//  Created by Yusuf Tör on 19/09/2024.
//

import Foundation

protocol Purchasing {
  func purchase(product: StoreProduct) async -> PurchaseResult
  func restorePurchases() async -> RestorationResult
}

final class PurchaseManager: Purchasing {
  let coordinator: PurchasingCoordinator
  let purchaser: Purchasing
  private unowned let factory: Factory
  typealias Factory = HasExternalPurchaseControllerFactory
    & StoreTransactionFactory
    & OptionsFactory
    & TransactionManagerFactory
    & PurchasedTransactionsFactory

  // swiftlint:disable:next identifier_name
  var _sk2TransactionListener: Any?
  @available(iOS 15.0, *)
  var sk2TransactionListener: SK2TransactionListener {
    // swiftlint:disable:next force_cast force_unwrapping
    return self._sk2TransactionListener! as! SK2TransactionListener
  }

  var isUsingSK2: Bool {
    return !(purchaser is ProductPurchaserSK1)
  }

  init(
    storeKitVersion: SuperwallOptions.StoreKitVersion,
    storeKitManager: StoreKitManager,
    receiptManager: ReceiptManager,
    identityManager: IdentityManager,
    storage: Storage,
    factory: Factory
  ) {
    self.factory = factory
    coordinator = PurchasingCoordinator(factory: factory)

    let hasPurchaseController = factory.makeHasExternalPurchaseController()
    let options = factory.makeSuperwallOptions()
    let shouldFinishTransactions = !hasPurchaseController && !options.shouldObservePurchases

    if #available(iOS 15.0, *),
      storeKitVersion == .storeKit2 {
      purchaser = ProductPurchaserSK2(
        identityManager: identityManager,
        receiptManager: receiptManager,
        storage: storage,
        factory: factory
      )
      _sk2TransactionListener = SK2TransactionListener(
        shouldFinishTransactions: shouldFinishTransactions,
        receiptManager: receiptManager,
        factory: factory
      )
      Task {
        await sk2TransactionListener.listenForTransactions()
      }
    } else {
      purchaser = ProductPurchaserSK1(
        shouldFinishTransactions: shouldFinishTransactions,
        storeKitManager: storeKitManager,
        receiptManager: receiptManager,
        identityManager: identityManager,
        coordinator: coordinator,
        storage: storage,
        factory: factory
      )
    }
  }

  func purchase(product: StoreProduct) async -> PurchaseResult {
    return await purchaser.purchase(product: product)
  }

  func restorePurchases() async -> RestorationResult {
    return await purchaser.restorePurchases()
  }
}
