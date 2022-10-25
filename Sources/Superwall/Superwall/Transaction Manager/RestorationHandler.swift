//
//  File.swift
//  
//
//  Created by Yusuf Tör on 20/10/2022.
//

import Foundation
import StoreKit

@MainActor
final class RestorationHandler {
  func tryToRestore(_ paywallViewController: PaywallViewController) async {
    Logger.debug(
      logLevel: .debug,
      scope: .paywallTransactions,
      message: "Attempting Restore"
    )

    paywallViewController.loadingState = .loadingPurchase

    let hasRestored = await Superwall.shared.delegateManager.restorePurchases()

    paywallViewController.loadingState = .ready

    if hasRestored {
      Logger.debug(
        logLevel: .debug,
        scope: .paywallTransactions,
        message: "Transaction Restored"
      )
      transactionWasRestored(paywallViewController: paywallViewController)
    } else {
      // TODO: We're not tracking restoration failures?
      Logger.debug(
        logLevel: .debug,
        scope: .paywallTransactions,
        message: "Transaction Failed to Restore"
      )

      paywallViewController.presentAlert(
        title: Superwall.options.paywalls.restoreFailed.title,
        message: Superwall.options.paywalls.restoreFailed.message,
        closeActionTitle: Superwall.options.paywalls.restoreFailed.closeButtonTitle
      )
    }
  }

  private func transactionWasRestored(paywallViewController: PaywallViewController) {
    let paywallInfo = paywallViewController.paywallInfo
    let isFreeTrialAvailable = paywallViewController.paywall.isFreeTrialAvailable == true
    Task.detached(priority: .utility) {
      let trackedEvent = InternalSuperwallEvent.Transaction(
        state: .restore,
        paywallInfo: paywallInfo,
        product: nil
      )
      await Superwall.track(trackedEvent)

      // If on iOS 15+ we don't use the Sk1 transaction observer.
      // So will need to track transactions here.
      if #available(iOS 15.0, *) {
        await SessionEventsManager.shared.triggerSession.trackTransactionRestoration(
          isFreeTrialAvailable: isFreeTrialAvailable
        )
      }
    }

    if Superwall.options.paywalls.automaticallyDismiss {
      Superwall.shared.dismiss(paywallViewController, state: .restored)
    } else {
      paywallViewController.loadingState = .ready
    }
  }
}