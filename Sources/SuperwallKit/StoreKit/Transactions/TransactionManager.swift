//
//  File 2.swift
//
//
//  Created by Yusuf Tör on 20/10/2022.
//
// swiftlint:disable type_body_length file_length line_length function_body_length

import Combine
import StoreKit
import UIKit

final class TransactionManager {
  private let storeKitManager: StoreKitManager
  private let receiptManager: ReceiptManager
  private let purchaseController: PurchaseController
  private let placementsQueue: PlacementsQueue
  private let purchaseManager: PurchaseManager
  private let productsManager: ProductsManager
  private let factory: Factory
  typealias Factory = OptionsFactory
    & TriggerFactory
    & PurchasedTransactionsFactory
    & StoreTransactionFactory
    & DeviceHelperFactory
    & HasExternalPurchaseControllerFactory
  enum State {
    case observing
    case purchasing(PurchaseSource)
  }

  init(
    storeKitManager: StoreKitManager,
    receiptManager: ReceiptManager,
    purchaseController: PurchaseController,
    placementsQueue: PlacementsQueue,
    purchaseManager: PurchaseManager,
    productsManager: ProductsManager,
    factory: Factory
  ) {
    self.storeKitManager = storeKitManager
    self.receiptManager = receiptManager
    self.purchaseController = purchaseController
    self.placementsQueue = placementsQueue
    self.purchaseManager = purchaseManager
    self.productsManager = productsManager
    self.factory = factory
  }

  /// Purchases the given product and handles the result appropriately.
  ///
  /// This uses a `PurchasingCoordinator` to coordinate the purchasing from start to finish.
  ///
  /// - Parameters:
  ///   - productId: The ID of the product to purchase.
  ///   - paywallViewController: The `PaywallViewController` that the product is being
  ///   purchased from.
  @discardableResult
  func purchase(_ purchaseSource: PurchaseSource) async -> PurchaseResult {
    let product: StoreProduct

    switch purchaseSource {
    case .internal(let productId, _):
      guard let storeProduct = await storeKitManager.productsById[productId] else {
        Logger.debug(
          logLevel: .error,
          scope: .transactions,
          message:
            "Trying to purchase \(productId) but the product has failed to load. Visit https://superwall.com/l/missing-products to diagnose."
        )
        return .failed(PurchaseError.productUnavailable)
      }
      product = storeProduct
    case .purchaseFunc(let storeProduct):
      product = storeProduct
    case .observeFunc:
      // This is a no-op, there's no way someone can call this func using observe.
      return .cancelled
    }
    await prepareToPurchase(
      product: product,
      purchaseSource: purchaseSource
    )

    let result = await purchase(product, purchaseSource: purchaseSource)

    // Return early if using a purchase controller and purchasing externally.
    // This avoids duplicate calls by the purchase function of the purchase
    // controller.
    if case .purchaseFunc = purchaseSource,
      factory.makeHasExternalPurchaseController() {
      // Not resetting coordinator here because we need it with the purchase controller
      // call.
      return result
    }

    await handle(
      result: result,
      state: .purchasing(purchaseSource)
    )

    return result
  }

  func handle(
    result: PurchaseResult,
    state: State
  ) async {
    let coordinator = factory.makePurchasingCoordinator()

    switch result {
    case .purchased:
      await didPurchase()
    case .restored:
      await didRestore()
    case .failed(let error):
      let superwallOptions = factory.makeSuperwallOptions()
      guard
        let outcome = TransactionErrorLogic.handle(
          error,
          triggers: factory.makeTriggers(),
          shouldShowPurchaseFailureAlert: superwallOptions.paywalls.shouldShowPurchaseFailureAlert
        )
      else {
        await trackFailure(error: error)
        switch state {
        case .observing:
          break
        case .purchasing(let purchaseSource):
          if case let .internal(_, paywallViewController) = purchaseSource {
            await paywallViewController.togglePaywallSpinner(isHidden: true)
          }
        }
        return await coordinator.reset()
      }
      switch outcome {
      case .cancelled:
        await trackCancelled()
      case .presentAlert:
        await trackFailure(error: error)
        switch state {
        case .observing:
          break
        case .purchasing(let purchaseSource):
          await presentAlert(
            title: "An error occurred",
            message: error.safeLocalizedDescription,
            source: purchaseSource.toGenericSource()
          )
        }
      }
    case .pending:
      await handlePendingTransaction()
    case .cancelled:
      await trackCancelled()
    }

    await coordinator.reset()
  }

  @available(iOS 17.2, visionOS 1.1, *)
  func logSK2ObserverModeTransaction(_ transaction: SK2Transaction) async {
    guard let product = try? await productsManager.products(
      identifiers: [transaction.productID],
      forPaywall: nil,
      placement: nil
    ).first else {
      return
    }
    await prepareToPurchase(
      product: product,
      purchaseSource: .observeFunc(product)
    )

    let hasOffer = transaction.offer != nil
    let coordinator = factory.makePurchasingCoordinator()
    await coordinator.setIsFreeTrialAvailable(to: hasOffer)

    await didPurchase()
  }

  @MainActor
  @discardableResult
  func tryToRestore(_ restoreSource: RestoreSource) async -> RestorationResult {
    func logAndTrack(
      state: InternalSuperwallPlacement.Restore.State,
      message: String,
      paywallInfo: PaywallInfo
    ) async {
      Logger.debug(
        logLevel: .debug,
        scope: .transactions,
        message: message
      )
      let trackedEvent = InternalSuperwallPlacement.Restore(
        state: state,
        paywallInfo: paywallInfo
      )
      await Superwall.shared.track(trackedEvent)
    }

    func handleRestoreResult(
      _ restorationResult: RestorationResult,
      paywallInfo: PaywallInfo,
      paywallViewController: PaywallViewController?
    ) async -> Bool {
      let hasRestored = restorationResult == .restored
      let hasActiveEntitlements = !Superwall.shared.entitlements.active.isEmpty

      if hasRestored && hasActiveEntitlements {
        await logAndTrack(
          state: .complete,
          message: "Transactions Restored",
          paywallInfo: paywallInfo
        )
        await didRestore(restoreSource: restoreSource)
        return true
      } else {
        var message = "Transactions Failed to Restore."
        if !hasActiveEntitlements && hasRestored {
          message +=
            " The restoration result is \"restored\" but there are no active entitlements. Ensure the active entitlements are set before confirming successful restoration."
        }
        if case .failed(let error) = restorationResult,
          let error = error {
          message += " Original restoration error message: \(error.safeLocalizedDescription)"
        }
        await logAndTrack(
          state: .fail(message),
          message: message,
          paywallInfo: paywallInfo
        )
        if let paywallViewController = paywallViewController {
          paywallViewController.webView.messageHandler.handle(.restoreFail(message))
        }
        return false
      }
    }

    switch restoreSource {
    case .internal(let paywallViewController):
      paywallViewController.loadingState = .loadingPurchase

      await logAndTrack(
        state: .start,
        message: "Attempting Restore",
        paywallInfo: paywallViewController.info
      )
      paywallViewController.webView.messageHandler.handle(.restoreStart)

      let restorationResult = await purchaseController.restorePurchases()
      let success = await handleRestoreResult(
        restorationResult,
        paywallInfo: paywallViewController.info,
        paywallViewController: paywallViewController
      )

      if success {
        paywallViewController.webView.messageHandler.handle(.restoreComplete)
      } else {
        paywallViewController.presentAlert(
          title: Superwall.shared.options.paywalls.restoreFailed.title,
          message: Superwall.shared.options.paywalls.restoreFailed.message,
          closeActionTitle: Superwall.shared.options.paywalls.restoreFailed.closeButtonTitle
        )
      }
      return restorationResult
    case .external:
      let hasExternalPurchaseController = factory.makeHasExternalPurchaseController()

      // If there's an external purchase controller, it means they'll be restoring inside the
      // restore function. So, when that function returns, it will hit the internal case first,
      // then here only to do the actual restore, before returning.
      if hasExternalPurchaseController {
        return await factory.restorePurchases()
      }

      await logAndTrack(
        state: .start,
        message: "Attempting Restore",
        paywallInfo: .empty()
      )

      let restorationResult = await factory.restorePurchases()
      let success = await handleRestoreResult(
        restorationResult,
        paywallInfo: .empty(),
        paywallViewController: nil
      )

      if !success {
        await presentAlert(
          title: Superwall.shared.options.paywalls.restoreFailed.title,
          message: Superwall.shared.options.paywalls.restoreFailed.message,
          closeActionTitle: Superwall.shared.options.paywalls.restoreFailed.closeButtonTitle,
          source: restoreSource
        )
      }

      return restorationResult
    }
  }

  func didRestore(restoreSource: RestoreSource? = nil) async {
    let coordinator = factory.makePurchasingCoordinator()
    var transaction: StoreTransaction?
    let restoreType: RestoreType

    let coordinatorSource = await coordinator.source
    guard let source = restoreSource ?? coordinatorSource?.toRestoreSource() else {
      return
    }

    let product = await coordinator.product

    if let product = product {
      // Product exists so much have been via a purchase of a specific product.
      transaction = await coordinator.getLatestTransaction(
        forProductId: product.productIdentifier,
        factory: factory
      )
      restoreType = .viaPurchase(transaction)
    } else {
      // Otherwise it was a generic restore.
      restoreType = .viaRestore
    }

    var isObserved = false
    if case .observeFunc = coordinatorSource {
      isObserved = true
    }

    switch source {
    case .internal(let paywallViewController):
      let paywallInfo = await paywallViewController.info

      let transactionRestore = InternalSuperwallPlacement.Transaction(
        state: .restore(restoreType),
        paywallInfo: paywallInfo,
        product: product,
        transaction: transaction,
        source: .internal,
        isObserved: isObserved,
        storeKitVersion: purchaseManager.isUsingSK2 ? .storeKit2 : .storeKit1
      )
      await Superwall.shared.track(transactionRestore)
      await paywallViewController.webView.messageHandler.handle(.transactionRestore)

      let superwallOptions = factory.makeSuperwallOptions()
      if superwallOptions.paywalls.automaticallyDismiss {
        await Superwall.shared.dismiss(paywallViewController, result: .restored)
      }
    case .external:
      let trackedEvent = InternalSuperwallPlacement.Transaction(
        state: .restore(restoreType),
        paywallInfo: .empty(),
        product: product,
        transaction: transaction,
        source: .external,
        isObserved: isObserved,
        storeKitVersion: purchaseManager.isUsingSK2 ? .storeKit2 : .storeKit1
      )
      await Superwall.shared.track(trackedEvent)
    }
  }

  private func purchase(
    _ product: StoreProduct,
    purchaseSource: PurchaseSource
  ) async -> PurchaseResult {
    switch purchaseSource {
    case .internal:
      return await purchaseController.purchase(product: product)
    case .purchaseFunc:
      return await factory.purchase(product: product)
    case .observeFunc:
      // No-op, there's no way this can be called from observe.
      return .cancelled
    }
  }

  /// Cancels the transaction timeout when the application resigns active.
  ///
  /// When the purchase sheet appears, the application resigns active.

  // MARK: - Transaction lifecycle

  func trackFailure(error: Error) async {
    let coordinator = factory.makePurchasingCoordinator()
    guard
      let source = await coordinator.source,
      let product = await coordinator.product
    else {
      return
    }

    var isObserved = false
    if case .observeFunc = source {
      isObserved = true
    }

    switch source {
    case .internal(_, let paywallViewController):
      Logger.debug(
        logLevel: .debug,
        scope: .transactions,
        message: "Transaction Error",
        info: [
          "product_id": product.productIdentifier,
          "paywall_vc": paywallViewController
        ],
        error: error
      )

      let paywallInfo = await paywallViewController.info
      Task { [isObserved] in
        let trackedEvent = InternalSuperwallPlacement.Transaction(
          state: .fail(.failure(error.safeLocalizedDescription, product)),
          paywallInfo: paywallInfo,
          product: product,
          transaction: nil,
          source: .internal,
          isObserved: isObserved,
          storeKitVersion: purchaseManager.isUsingSK2 ? .storeKit2 : .storeKit1
        )
        await Superwall.shared.track(trackedEvent)
        await paywallViewController.webView.messageHandler.handle(.transactionFail)
      }
    case .purchaseFunc,
      .observeFunc:
      Logger.debug(
        logLevel: .debug,
        scope: .transactions,
        message: "Transaction Error",
        info: [
          "product_id": product.productIdentifier
        ],
        error: error
      )

      Task { [isObserved] in
        let trackedEvent = InternalSuperwallPlacement.Transaction(
          state: .fail(.failure(error.safeLocalizedDescription, product)),
          paywallInfo: .empty(),
          product: product,
          transaction: nil,
          source: .external,
          isObserved: isObserved,
          storeKitVersion: purchaseManager.isUsingSK2 ? .storeKit2 : .storeKit1
        )
        await Superwall.shared.track(trackedEvent)
      }
    }
  }

  func observeTransaction(for productId: String) async {
    guard
      let storeProduct = try? await productsManager.products(
        identifiers: [productId],
        forPaywall: nil,
        placement: nil
      ).first
    else {
      Logger.debug(
        logLevel: .debug,
        scope: .superwallCore,
        message: "There's a purchase happening of a product with id \(productId), "
          + "but we couldn't retrieve it to observe its purchase."
      )
      return
    }
    let coordinator = factory.makePurchasingCoordinator()
    await prepareToPurchase(
      product: storeProduct,
      purchaseSource: .observeFunc(storeProduct)
    )
    await coordinator.setCompletion { result in
      Task { [weak self] in
        await self?.handle(
          result: result,
          state: .observing
        )
      }
    }
  }

  /// Tracks the analytics and logs the start of the transaction.
  func prepareToPurchase(
    product: StoreProduct,
    purchaseSource: PurchaseSource
  ) async {
    let isFreeTrialAvailable = await receiptManager.isFreeTrialAvailable(for: product)

    var isObserved = false
    if case .observeFunc = purchaseSource {
      isObserved = true
    }

    // Skip transaction start tracking if using StoreKit2 and the source is observeFunc
    let shouldTrackTransactionStart = !(purchaseManager.isUsingSK2 && isObserved)

    switch purchaseSource {
    case .internal(_, let paywallViewController):
      Logger.debug(
        logLevel: .debug,
        scope: .transactions,
        message: "Transaction Purchasing",
        info: ["paywall_vc": paywallViewController],
        error: nil
      )

      let paywallInfo = await paywallViewController.info

      let transactionStart = InternalSuperwallPlacement.Transaction(
        state: .start(product),
        paywallInfo: paywallInfo,
        product: product,
        transaction: nil,
        source: .internal,
        isObserved: isObserved,
        storeKitVersion: purchaseManager.isUsingSK2 ? .storeKit2 : .storeKit1
      )
      await Superwall.shared.track(transactionStart)
      await paywallViewController.webView.messageHandler.handle(.transactionStart)

      await MainActor.run {
        paywallViewController.loadingState = .loadingPurchase
      }
    case .purchaseFunc,
      .observeFunc:
      // If an external purchase controller is being used, skip because this will
      // get called by the purchase function of the purchase controller.
      let options = factory.makeSuperwallOptions()
      if !options.shouldObservePurchases,
        factory.makeHasExternalPurchaseController() {
        return
      }

      Logger.debug(
        logLevel: .debug,
        scope: .transactions,
        message: "External Transaction Purchasing"
      )

      if shouldTrackTransactionStart {
        let trackedEvent = InternalSuperwallPlacement.Transaction(
          state: .start(product),
          paywallInfo: .empty(),
          product: product,
          transaction: nil,
          source: .external,
          isObserved: isObserved,
          storeKitVersion: purchaseManager.isUsingSK2 ? .storeKit2 : .storeKit1
        )
        await Superwall.shared.track(trackedEvent)
      }
    }

    await factory.makePurchasingCoordinator().beginPurchase(
      of: product,
      source: purchaseSource,
      isFreeTrialAvailable: isFreeTrialAvailable
    )
  }

  /// Dismisses the view controller, if the developer hasn't disabled the option.
  func didPurchase() async {
    let coordinator = factory.makePurchasingCoordinator()
    guard
      let source = await coordinator.source,
      let product = await coordinator.product
    else {
      return
    }

    switch source {
    case .internal(_, let paywallViewController):
      guard let product = await coordinator.product else {
        return
      }
      Logger.debug(
        logLevel: .debug,
        scope: .transactions,
        message: "Transaction Succeeded",
        info: [
          "product_id": product.productIdentifier,
          "paywall_vc": paywallViewController
        ],
        error: nil
      )

      let purchasingCoordinator = factory.makePurchasingCoordinator()
      let transaction = await purchasingCoordinator.getLatestTransaction(
        forProductId: product.productIdentifier,
        factory: factory
      )

      await receiptManager.loadPurchasedProducts()
      await trackTransactionDidSucceed(transaction)

      let superwallOptions = factory.makeSuperwallOptions()
      if superwallOptions.paywalls.automaticallyDismiss {
        await Superwall.shared.dismiss(
          paywallViewController,
          result: .purchased(product)
        )
      }
    case .purchaseFunc,
      .observeFunc:
      Logger.debug(
        logLevel: .debug,
        scope: .transactions,
        message: "Transaction Succeeded",
        info: [
          "product_id": product.productIdentifier
        ],
        error: nil
      )

      let purchasingCoordinator = factory.makePurchasingCoordinator()
      let transaction = await purchasingCoordinator.getLatestTransaction(
        forProductId: product.productIdentifier,
        factory: factory
      )

      await receiptManager.loadPurchasedProducts()

      await trackTransactionDidSucceed(transaction)
    }
  }

  /// Track the cancelled
  func trackCancelled() async {
    let coordinator = factory.makePurchasingCoordinator()
    guard
      let source = await coordinator.source,
      let product = await coordinator.product
    else {
      return
    }

    var isObserved = false
    if case .observeFunc = source {
      isObserved = true
    }

    switch source {
    case .internal(_, let paywallViewController):
      Logger.debug(
        logLevel: .debug,
        scope: .transactions,
        message: "Transaction Abandoned",
        info: ["product_id": product.productIdentifier, "paywall_vc": paywallViewController],
        error: nil
      )

      let paywallInfo = await paywallViewController.info
      let transactionAbandon = InternalSuperwallPlacement.Transaction(
        state: .abandon(product),
        paywallInfo: paywallInfo,
        product: product,
        transaction: nil,
        source: .internal,
        isObserved: isObserved,
        storeKitVersion: purchaseManager.isUsingSK2 ? .storeKit2 : .storeKit1
      )
      await Superwall.shared.track(transactionAbandon)
      await paywallViewController.webView.messageHandler.handle(.transactionAbandon)

      await MainActor.run {
        paywallViewController.loadingState = .ready
      }
    case .purchaseFunc,
      .observeFunc:
      Logger.debug(
        logLevel: .debug,
        scope: .transactions,
        message: "Transaction Abandoned",
        info: ["product_id": product.productIdentifier],
        error: nil
      )

      let trackedEvent = InternalSuperwallPlacement.Transaction(
        state: .abandon(product),
        paywallInfo: .empty(),
        product: product,
        transaction: nil,
        source: .external,
        isObserved: isObserved,
        storeKitVersion: purchaseManager.isUsingSK2 ? .storeKit2 : .storeKit1
      )
      await Superwall.shared.track(trackedEvent)
    }
  }

  func handlePendingTransaction() async {
    let coordinator = factory.makePurchasingCoordinator()
    guard let source = await coordinator.source else {
      return
    }

    var isObserved = false
    if case .observeFunc = source {
      isObserved = true
    }

    switch source {
    case .internal(_, let paywallViewController):
      Logger.debug(
        logLevel: .debug,
        scope: .transactions,
        message: "Transaction Pending",
        info: ["paywall_vc": paywallViewController],
        error: nil
      )

      let paywallInfo = await paywallViewController.info

      let transactionFail = InternalSuperwallPlacement.Transaction(
        state: .fail(.pending("Needs parental approval")),
        paywallInfo: paywallInfo,
        product: nil,
        transaction: nil,
        source: .internal,
        isObserved: isObserved,
        storeKitVersion: purchaseManager.isUsingSK2 ? .storeKit2 : .storeKit1
      )
      await Superwall.shared.track(transactionFail)
      await paywallViewController.webView.messageHandler.handle(.transactionFail)
    case .purchaseFunc,
      .observeFunc:
      Logger.debug(
        logLevel: .debug,
        scope: .transactions,
        message: "Transaction Pending",
        error: nil
      )

      let trackedEvent = InternalSuperwallPlacement.Transaction(
        state: .fail(.pending("Needs parental approval")),
        paywallInfo: .empty(),
        product: nil,
        transaction: nil,
        source: .external,
        isObserved: isObserved,
        storeKitVersion: purchaseManager.isUsingSK2 ? .storeKit2 : .storeKit1
      )
      await Superwall.shared.track(trackedEvent)
    }

    await presentAlert(
      title: "Waiting for Approval",
      message:
        "Thank you! This purchase is pending approval from your parent. Please try again once it is approved.",
      source: source.toGenericSource()
    )
  }

  private func presentAlert(
    title: String,
    message: String,
    closeActionTitle: String? = nil,
    source: GenericSource
  ) async {
    switch source {
    case .internal(let paywallViewController):
      await paywallViewController.presentAlert(
        title: title,
        message: message,
        closeActionTitle: closeActionTitle ?? "Done"
      )
    case .external:
      guard let topMostViewController = await UIViewController.topMostViewController else {
        Logger.debug(
          logLevel: .error,
          scope: .transactions,
          message:
            "Could not find the top-most view controller to present a transaction alert from."
        )
        return
      }
      let alertController = await AlertControllerFactory.make(
        title: title,
        message: message,
        closeActionTitle: closeActionTitle ?? "Done",
        sourceView: topMostViewController.view
      )
      await topMostViewController.present(alertController, animated: true)
    }
  }

  func trackTransactionDidSucceed(_ transaction: StoreTransaction?) async {
    let coordinator = factory.makePurchasingCoordinator()
    guard
      let source = await coordinator.source,
      let product = await coordinator.product
    else {
      return
    }

    // Insert the transaction ID into the cache if observing. This prevents racing with
    // the SK2 observer.
    if #available(iOS 17.2, *),
      let purchaser = purchaseManager.purchaser as? ProductPurchaserSK2,
      let id = transaction?.sk2Transaction?.id {
      let observer = purchaser.sk2ObserverModePurchaseDetector
      await observer.insertToCachedTransactionIds([id])
    }

    let didStartOffer: Bool

    if #available(iOS 17.2, visionOS 1.1, *),
      let sk2Transaction = transaction?.sk2Transaction {
      didStartOffer = sk2Transaction.offer != nil
    } else {
      didStartOffer = await coordinator.isFreeTrialAvailable
    }

    var isObserved = false
    if case .observeFunc = source {
      isObserved = true
    }

    let type: TransactionType = {
      if product.subscriptionPeriod == nil {
        return .nonRecurringProductPurchase
      } else if didStartOffer {
        return .freeTrialStart
      } else {
        return .subscriptionStart
      }
    }()

    let paywallInfo: PaywallInfo
    let eventSource: InternalSuperwallPlacement.Transaction.Source
    switch source {
    case .internal(_, let paywallViewController):
      paywallInfo = await paywallViewController.info
      eventSource = .internal
      await paywallViewController.webView.messageHandler.handle(.transactionComplete)
    case .purchaseFunc,
      .observeFunc:
      paywallInfo = .empty()
      eventSource = .external
    }

    let trackedTransactionEvent = InternalSuperwallPlacement.Transaction(
      state: .complete(product, transaction, type),
      paywallInfo: paywallInfo,
      product: product,
      transaction: transaction,
      source: eventSource,
      isObserved: isObserved,
      storeKitVersion: purchaseManager.isUsingSK2 ? .storeKit2 : .storeKit1
    )
    await Superwall.shared.track(trackedTransactionEvent)
    await placementsQueue.flushInternal()

    switch type {
    case .nonRecurringProductPurchase:
      await Superwall.shared.track(
        InternalSuperwallPlacement.NonRecurringProductPurchase(
          paywallInfo: paywallInfo,
          product: product,
          transaction: transaction
        )
      )
    case .freeTrialStart:
      await Superwall.shared.track(
        InternalSuperwallPlacement.FreeTrialStart(
          paywallInfo: paywallInfo,
          product: product,
          transaction: transaction
        )
      )
      let notifications = paywallInfo.localNotifications.filter {
        $0.type == .trialStarted
      }
      await NotificationScheduler.scheduleNotifications(notifications, factory: factory)
    case .subscriptionStart:
      await Superwall.shared.track(
        InternalSuperwallPlacement.SubscriptionStart(
          paywallInfo: paywallInfo,
          product: product,
          transaction: transaction
        )
      )
    }
  }
}
