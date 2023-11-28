//
//  File 2.swift
//  
//
//  Created by Yusuf Tör on 20/10/2022.
//
// swiftlint:disable type_body_length file_length

import StoreKit
import UIKit
import Combine

final class TransactionManager {
  private var storeKitManager: StoreKitManager {
    return factory.storeKitManager
  }

  private var receiptManager: ReceiptManager {
    return factory.receiptManager
  }

  private var purchaseController: PurchaseController {
    return factory.purchaseController
  }

  private var sessionEventsManager: SessionEventsManager {
    return factory.sessionEventsManager
  }

  private let factory: DependencyContainer

  init(factory: DependencyContainer) {
    self.factory = factory
  }

  /// Purchases the given product and handles the result appropriately.
  ///
  /// - Parameters:
  ///   - productId: The ID of the product to purchase.
  ///   - paywallViewController: The `PaywallViewController` that the product is being
  ///   purchased from.
  func purchase(
    _ productId: String,
    from paywallViewController: PaywallViewController
  ) async {
    guard let product = await storeKitManager.productsById[productId] else {
      return
    }

    await prepareToStartTransaction(of: product, from: paywallViewController)

    let result = await purchase(product)

    switch result {
    case .purchased:
      await didPurchase(
        product,
        from: paywallViewController
      )
    case .restored:
      await didRestore(
        product: product,
        paywallViewController: paywallViewController
      )
    case .failed(let error):
      let superwallOptions = factory.makeSuperwallOptions()
      guard let outcome = TransactionErrorLogic.handle(
        error,
        triggers: factory.makeTriggers(),
        shouldShowPurchaseFailureAlert: superwallOptions.paywalls.shouldShowPurchaseFailureAlert
      ) else {
        await trackFailure(
          error: error,
          product: product,
          paywallViewController: paywallViewController
        )
        return await paywallViewController.togglePaywallSpinner(isHidden: true)
      }
      switch outcome {
      case .cancelled:
        await trackCancelled(
          product: product,
          from: paywallViewController
        )
      case .presentAlert:
        await trackFailure(
          error: error,
          product: product,
          paywallViewController: paywallViewController
        )
        await presentAlert(
          forError: error,
          product: product,
          paywallViewController: paywallViewController
        )
      }
    case .pending:
      await handlePendingTransaction(from: paywallViewController)
    case .cancelled:
      await trackCancelled(product: product, from: paywallViewController)
    }
  }

  @MainActor
  func tryToRestore(from paywallViewController: PaywallViewController) async {
    Logger.debug(
      logLevel: .debug,
      scope: .paywallTransactions,
      message: "Attempting Restore"
    )

    paywallViewController.loadingState = .loadingPurchase

    let restorationResult = await purchaseController.restorePurchases()

    let hasRestored = restorationResult == .restored
    let isUserSubscribed = Superwall.shared.subscriptionStatus == .active

    if hasRestored && isUserSubscribed {
      Logger.debug(
        logLevel: .debug,
        scope: .paywallTransactions,
        message: "Transactions Restored"
      )
      await didRestore(
        paywallViewController: paywallViewController
      )
    } else {
      Logger.debug(
        logLevel: .debug,
        scope: .paywallTransactions,
        message: "Transactions Failed to Restore"
      )

      paywallViewController.presentAlert(
        title: Superwall.shared.options.paywalls.restoreFailed.title,
        message: Superwall.shared.options.paywalls.restoreFailed.message,
        closeActionTitle: Superwall.shared.options.paywalls.restoreFailed.closeButtonTitle
      )
    }
  }

  private func didRestore(
    product: StoreProduct? = nil,
    paywallViewController: PaywallViewController
  ) async {
    let purchasingCoordinator = factory.makePurchasingCoordinator()
    var transaction: StoreTransaction?
    let restoreType: RestoreType

    if let product = product {
      // Product exists so much have been via a purchase of a specific product.
      transaction = await purchasingCoordinator.getLatestTransaction(
        forProductId: product.productIdentifier,
        factory: factory
      )
      restoreType = .viaPurchase(transaction)
    } else {
      // Otherwise it was a generic restore.
      restoreType = .viaRestore
    }

    let paywallInfo = await paywallViewController.info

    let trackedEvent = InternalSuperwallEvent.Transaction(
      state: .restore(restoreType),
      paywallInfo: paywallInfo,
      product: product,
      model: transaction
    )
    await Superwall.shared.track(trackedEvent)

    let superwallOptions = factory.makeSuperwallOptions()
    if superwallOptions.paywalls.automaticallyDismiss {
      await Superwall.shared.dismiss(paywallViewController, result: .restored)
    }
  }

  private func purchase(_ product: StoreProduct) async -> PurchaseResult {
    guard let sk1Product = product.sk1Product else {
      return .failed(PurchaseError.productUnavailable)
    }
    return await purchaseController.purchase(product: sk1Product)
  }

  /// Cancels the transaction timeout when the application resigns active.
  ///
  /// When the purchase sheet appears, the application resigns active.

  // MARK: - Transaction lifecycle

  private func trackFailure(
    error: Error,
    product: StoreProduct,
    paywallViewController: PaywallViewController
  ) async {
    Logger.debug(
      logLevel: .debug,
      scope: .paywallTransactions,
      message: "Transaction Error",
      info: [
        "product_id": product.productIdentifier,
        "paywall_vc": paywallViewController
      ],
      error: error
    )

    let paywallInfo = await paywallViewController.info
    Task {
      let trackedEvent = InternalSuperwallEvent.Transaction(
        state: .fail(.failure(error.safeLocalizedDescription, product)),
        paywallInfo: paywallInfo,
        product: product,
        model: nil
      )
      await Superwall.shared.track(trackedEvent)
      await self.sessionEventsManager.triggerSession.trackTransactionError()
    }
  }

  /// Tracks the analytics and logs the start of the transaction.
  private func prepareToStartTransaction(
    of product: StoreProduct,
    from paywallViewController: PaywallViewController
  ) async {
    Logger.debug(
      logLevel: .debug,
      scope: .paywallTransactions,
      message: "Transaction Purchasing",
      info: ["paywall_vc": paywallViewController],
      error: nil
    )

    let paywallInfo = await paywallViewController.info

    await self.sessionEventsManager.triggerSession.trackBeginTransaction(of: product)
    let trackedEvent = InternalSuperwallEvent.Transaction(
      state: .start(product),
      paywallInfo: paywallInfo,
      product: product,
      model: nil
    )
    await Superwall.shared.track(trackedEvent)

    await MainActor.run {
      paywallViewController.loadingState = .loadingPurchase
    }
  }

  /// Dismisses the view controller, if the developer hasn't disabled the option.
  private func didPurchase(
    _ product: StoreProduct,
    from paywallViewController: PaywallViewController
  ) async {
    Logger.debug(
      logLevel: .debug,
      scope: .paywallTransactions,
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

    if let transaction = transaction {
      await self.sessionEventsManager.enqueue(transaction)
    }

    await receiptManager.loadPurchasedProducts()

    await trackTransactionDidSucceed(
      transaction,
      product: product,
      paywallViewController: paywallViewController
    )

    let superwallOptions = factory.makeSuperwallOptions()
    if superwallOptions.paywalls.automaticallyDismiss {
      await Superwall.shared.dismiss(
        paywallViewController,
        result: .purchased(productId: product.productIdentifier)
      )
    }
  }

  /// Track the cancelled
  private func trackCancelled(
    product: StoreProduct,
    from paywallViewController: PaywallViewController
  ) async {
    Logger.debug(
      logLevel: .debug,
      scope: .paywallTransactions,
      message: "Transaction Abandoned",
      info: ["product_id": product.productIdentifier, "paywall_vc": paywallViewController],
      error: nil
    )

    let paywallInfo = await paywallViewController.info
    let trackedEvent = InternalSuperwallEvent.Transaction(
      state: .abandon(product),
      paywallInfo: paywallInfo,
      product: product,
      model: nil
    )
    await Superwall.shared.track(trackedEvent)
    await sessionEventsManager.triggerSession.trackTransactionAbandon()

    await MainActor.run {
      paywallViewController.loadingState = .ready
    }
  }

  private func handlePendingTransaction(from paywallViewController: PaywallViewController) async {
    Logger.debug(
      logLevel: .debug,
      scope: .paywallTransactions,
      message: "Transaction Pending",
      info: ["paywall_vc": paywallViewController],
      error: nil
    )

    let paywallInfo = await paywallViewController.info

    let trackedEvent = InternalSuperwallEvent.Transaction(
      state: .fail(.pending("Needs parental approval")),
      paywallInfo: paywallInfo,
      product: nil,
      model: nil
    )
    await Superwall.shared.track(trackedEvent)
    await self.sessionEventsManager.triggerSession.trackPendingTransaction()

    await paywallViewController.presentAlert(
      title: "Waiting for Approval",
      message: "Thank you! This purchase is pending approval from your parent. Please try again once it is approved."
    )
  }

  private func presentAlert(
    forError error: Error,
    product: StoreProduct,
    paywallViewController: PaywallViewController
  ) async {
    await paywallViewController.presentAlert(
      title: "An error occurred",
      message: error.safeLocalizedDescription
    )
  }

  func trackTransactionDidSucceed(
    _ transaction: StoreTransaction?,
    product: StoreProduct,
    paywallViewController: PaywallViewController
  ) async {
    let paywallShowingFreeTrial = await paywallViewController.paywall.isFreeTrialAvailable == true
    let didStartFreeTrial = product.hasFreeTrial && paywallShowingFreeTrial

    let paywallInfo = await paywallViewController.info

    if let transaction = transaction {
      await self.sessionEventsManager.triggerSession.trackTransactionSucceeded(
        withId: transaction.storeTransactionId,
        for: product,
        isFreeTrialAvailable: didStartFreeTrial
      )
    }

    let trackedEvent = InternalSuperwallEvent.Transaction(
      state: .complete(product, transaction),
      paywallInfo: paywallInfo,
      product: product,
      model: transaction
    )
    await Superwall.shared.track(trackedEvent)

    if product.subscriptionPeriod == nil {
      let trackedEvent = InternalSuperwallEvent.NonRecurringProductPurchase(
        paywallInfo: paywallInfo,
        product: product
      )
      await Superwall.shared.track(trackedEvent)
    }

    if didStartFreeTrial {
      let trackedEvent = InternalSuperwallEvent.FreeTrialStart(
        paywallInfo: paywallInfo,
        product: product
      )
      await Superwall.shared.track(trackedEvent)

      let notifications = paywallInfo.localNotifications.filter {
        $0.type == .trialStarted
      }

      await NotificationScheduler.scheduleNotifications(notifications, factory: factory)
    } else {
      let trackedEvent = InternalSuperwallEvent.SubscriptionStart(
        paywallInfo: paywallInfo,
        product: product
      )
      await Superwall.shared.track(trackedEvent)
    }
  }
}
