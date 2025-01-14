//
//  File.swift
//
//
//  Created by Yusuf Tör on 06/12/2022.
//
// swiftlint:disable function_body_length

import Foundation
import StoreKit

final class ProductPurchaserSK1: NSObject, Purchasing {
  // MARK: Purchasing
  let coordinator: PurchasingCoordinator

  // MARK: Restoration
  final class Restoration {
    var completion: ((Error?) -> Void)?
    var dispatchGroup = DispatchGroup()
    /// Used to serialise the async `SKPaymentQueue` calls when restoring.
    var queue = DispatchQueue(
      label: "com.superwall.restoration",
      qos: .userInitiated
    )
  }
  private let restoration = Restoration()
  private let shouldFinishTransaction: Bool

  // MARK: Dependencies
  private let storeKitManager: StoreKitManager
  private let receiptManager: ReceiptManager
  private let identityManager: IdentityManager
  private let storage: Storage
  private let factory:
    HasExternalPurchaseControllerFactory
      & StoreTransactionFactory
      & OptionsFactory
      & TransactionManagerFactory

  deinit {
    SKPaymentQueue.default().remove(self)
  }

  init(
    shouldFinishTransactions: Bool,
    storeKitManager: StoreKitManager,
    receiptManager: ReceiptManager,
    identityManager: IdentityManager,
    coordinator: PurchasingCoordinator,
    storage: Storage,
    factory: HasExternalPurchaseControllerFactory
      & StoreTransactionFactory
      & OptionsFactory
      & TransactionManagerFactory
  ) {
    self.coordinator = coordinator
    self.storeKitManager = storeKitManager
    self.receiptManager = receiptManager
    self.identityManager = identityManager
    self.storage = storage
    self.factory = factory
    self.shouldFinishTransaction = shouldFinishTransactions

    super.init()
    SKPaymentQueue.default().add(self)
  }

  /// Purchases a product, waiting for the completion block to be fired and
  /// returning a purchase result.
  func purchase(product: StoreProduct) async -> PurchaseResult {
    guard let product = product.sk1Product else {
      return .failed(PurchaseError.noSk1Product)
    }
    let task = Task {
      return await withCheckedContinuation { continuation in
        Task {
          await coordinator.setCompletion { result in
            continuation.resume(returning: result)
          }
        }
      }
    }
    let payment = SKMutablePayment(product: product)
    payment.applicationUsername = identityManager.appUserId
    SKPaymentQueue.default().add(payment)

    return await task.value
  }

  func restorePurchases() async -> RestorationResult {
    let result = await withCheckedContinuation { continuation in
      // Using restoreCompletedTransactions instead of just refreshing
      // the receipt so that RC can pick up on the restored products,
      // if observing. It will also refresh the receipt on device.
      restoration.completion = { completed in
        return continuation.resume(returning: completed)
      }
      SKPaymentQueue.default().restoreCompletedTransactions()
    }
    restoration.completion = nil
    return result == nil ? .restored : .failed(result)
  }
}

// MARK: - SKPaymentTransactionObserver
extension ProductPurchaserSK1: SKPaymentTransactionObserver {
  func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
    Logger.debug(
      logLevel: .debug,
      scope: .transactions,
      message: "Restore Completed Transactions Finished"
    )
    restoration.dispatchGroup.notify(queue: restoration.queue) { [weak self] in
      self?.restoration.completion?(nil)
    }
  }

  func paymentQueue(
    _ queue: SKPaymentQueue,
    restoreCompletedTransactionsFailedWithError error: Error
  ) {
    Logger.debug(
      logLevel: .debug,
      scope: .transactions,
      message: "Restore Completed Transactions Failed With Error",
      error: error
    )
    restoration.dispatchGroup.notify(queue: restoration.queue) { [weak self] in
      self?.restoration.completion?(error)
    }
  }

  func paymentQueue(
    _ queue: SKPaymentQueue,
    updatedTransactions transactions: [SKPaymentTransaction]
  ) {
    restoration.dispatchGroup.enter()
    Task {
      let paywallViewController = Superwall.shared.paywallViewController

      for transaction in transactions {
        await updatePurchaseCompletionBlock(
          for: transaction,
          paywallViewController: paywallViewController
        )
      }
      await loadPurchasedProductsIfPossible(from: transactions)
      restoration.dispatchGroup.leave()
    }
  }

  // MARK: - Private API

  func paymentQueue(
    _ queue: SKPaymentQueue,
    removedTransactions transactions: [SKPaymentTransaction]
  ) {
    var storedIds = storage.get(PurchasingProductIds.self) ?? []
    for transaction in transactions {
      if let id = storedIds.first(where: {
        $0 == transaction.payment.productIdentifier
      }) {
        storedIds.remove(id)
      }
    }
    storage.save(storedIds, forType: PurchasingProductIds.self)
  }

  /// Sends a `PurchaseResult` to the completion block and stores the latest purchased transaction.
  func updatePurchaseCompletionBlock(
    for skTransaction: SKPaymentTransaction,
    paywallViewController: PaywallViewController? = nil
  ) async {
    // Only continue if using internal purchase controller, in a purchasing
    // state, or observing. The transaction may be readded to the queue if
    // finishing fails so we need to make sure we can re-finish the transaction.
    // It doesn't matter if purchased internally or externally.
    let source = await coordinator.source
    if let source = source {
      switch source {
      case .internal,
        .purchaseFunc:
        if factory.makeHasExternalPurchaseController() {
          return
        }
      case .observeFunc:
        break
      }
    } else if skTransaction.transactionState == .purchasing {
    } else {
      if factory.makeHasExternalPurchaseController() {
        return
      }
    }

    let purchaseDate = await coordinator.purchaseDate
    let options = factory.makeSuperwallOptions()

    switch skTransaction.transactionState {
    case .purchasing:
      // If in observer mode, and the purchasing transaction has not
      // come from a function within Superwall, check that it's not
      // a purchase that's been readded to the queue. Then start observing it.
      if source == nil,
        options.shouldObservePurchases {
        var storedIds = storage.get(PurchasingProductIds.self) ?? []
        let isExistingTransaction = storedIds.contains(
          where: { $0 == skTransaction.payment.productIdentifier }
        )
        if !isExistingTransaction {
          let transactionManager = factory.makeTransactionManager()
          await transactionManager.observeTransaction(for: skTransaction.payment.productIdentifier)
          storedIds.insert(skTransaction.payment.productIdentifier)
          storage.save(storedIds, forType: PurchasingProductIds.self)
        }
      }
    case .purchased:
      finishTransaction(skTransaction)
      do {
        try await ProductPurchaserLogic.validate(
          transaction: skTransaction,
          since: purchaseDate,
          withProductId: skTransaction.payment.productIdentifier
        )
        await coordinator.completePurchase(
          of: skTransaction,
          result: .purchased
        )
      } catch {
        await coordinator.completePurchase(
          of: skTransaction,
          result: .failed(error)
        )
      }
    case .failed:
      finishTransaction(skTransaction)
      if let error = skTransaction.error {
        if let error = error as? SKError {
          switch error.code {
          case .paymentCancelled,
            .overlayCancelled:
            return await coordinator.completePurchase(
              of: skTransaction,
              result: .cancelled
            )
          default:
            break
          }

          if #available(iOS 14, *) {
            switch error.code {
            case .overlayTimeout:
              await trackTimeout(paywallViewController: paywallViewController)
              return await coordinator.completePurchase(
                of: skTransaction,
                result: .cancelled
              )
            default:
              break
            }
          }
        }
        await coordinator.completePurchase(
          of: skTransaction,
          result: .failed(error))
      }
    case .deferred:
      finishTransaction(skTransaction)
      await coordinator.completePurchase(of: skTransaction, result: .pending)
    case .restored:
      finishTransaction(skTransaction)
    default:
      break
    }
  }

  private func finishTransaction(_ skTransaction: SKPaymentTransaction) {
    guard shouldFinishTransaction else {
      return
    }
    SKPaymentQueue.default().finishTransaction(skTransaction)
  }

  private func trackTimeout(paywallViewController: PaywallViewController? = nil) async {
    var source: InternalSuperwallPlacement.Transaction.Source = .internal

    var isObserved = false
    switch await coordinator.source {
    case .observeFunc:
      isObserved = true
      source = .external
    case .purchaseFunc:
      source = .external
    default:
      break
    }

    let trackedEvent = await InternalSuperwallPlacement.Transaction(
      state: .timeout,
      paywallInfo: paywallViewController?.info ?? .empty(),
      product: nil,
      transaction: nil,
      source: source,
      isObserved: isObserved,
      storeKitVersion: .storeKit1
    )
    await Superwall.shared.track(trackedEvent)
    await paywallViewController?.webView.messageHandler.handle(.transactionTimeout)
  }

  /// Loads purchased products in the StoreKitManager if a purchase or restore has occurred.
  private func loadPurchasedProductsIfPossible(from transactions: [SKPaymentTransaction]) async {
    if transactions.first(
      where: { $0.transactionState == .purchased || $0.transactionState == .restored }
    ) == nil {
      return
    }
    await receiptManager.loadPurchasedProducts()
  }
}
