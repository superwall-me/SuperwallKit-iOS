// swiftlint:disable all
//
//  RCPurchaseController.swift
//  PurchaseController + Entitlements
//
//  Created by Yusuf Tor on 13/12/24.
//

import Combine
import StoreKit
import SuperwallKit
import RevenueCat

enum PurchasingError: LocalizedError {
  case sk2ProductNotFound

  var errorDescription: String? {
    switch self {
    case .sk2ProductNotFound:
      return "Superwall didn't pass a StoreKit 2 product to purchase. Are you sure you're not "
        + "configuring Superwall with a SuperwallOption to use StoreKit 1?"
    }
  }
}

// MARK: Quickstart (v3.0.0+)
/// 1. Copy this file into your app
/// 2. Create an `RCPurchaseController` wherever Superwall and RevenueCat are being initialized.
///   `let purchaseController = RCPurchaseController()`
/// 3. First, configure Superwall. Pass in the `purchaseController` you just created.
///   `Superwall.configure(apiKey: "superwall_api_key", purchaseController: purchaseController)`
/// 4. Second, configure RevenueCat.
///   `Purchases.configure(withAPIKey: "revenuecat_api_key")`
/// 5. Third, Keep Superwall's entitlements up-to-date with RevenueCat's.
///   `purchaseController.syncEntitlements()`
final class RCPurchaseController: PurchaseController {
  // MARK: Sync Entitlements
  /// Makes sure that Superwall knows the customer's entitlements by
  /// changing `Superwall.shared.entitlements`
  func syncEntitlements() {
    assert(Purchases.isConfigured, "You must configure RevenueCat before calling this method.")
    Task {
      for await customerInfo in Purchases.shared.customerInfoStream {
        // Gets called whenever new CustomerInfo is available
        let superwallEntitlements = customerInfo.entitlements.activeInCurrentEnvironment.keys.map {
          Entitlement(id: $0)
        }
        await MainActor.run { [superwallEntitlements] in
          if superwallEntitlements.isEmpty {
            Superwall.shared.entitlements.status = .inactive
          } else {
            Superwall.shared.entitlements.status = .active(Set(superwallEntitlements))
          }
        }
      }
    }
  }

  // MARK: Handle Purchases
  /// Makes a purchase with RevenueCat and returns its result. This gets called when
  /// someone tries to purchase a product on one of your paywalls.
  func purchase(product: SuperwallKit.StoreProduct) async -> PurchaseResult {
    do {
      guard let sk2Product = product.sk2Product else {
        throw PurchasingError.sk2ProductNotFound
      }
      let storeProduct = RevenueCat.StoreProduct(sk2Product: sk2Product)
      let revenueCatResult = try await Purchases.shared.purchase(product: storeProduct)
      if revenueCatResult.userCancelled {
        return .cancelled
      } else {
        return .purchased
      }
    } catch let error as ErrorCode {
      if error == .paymentPendingError {
        return .pending
      } else {
        return .failed(error)
      }
    } catch {
      return .failed(error)
    }
  }

  // MARK: Handle Restores
  /// Makes a restore with RevenueCat and returns `.restored`, unless an error is thrown.
  /// This gets called when someone tries to restore purchases on one of your paywalls.
  func restorePurchases() async -> RestorationResult {
    do {
      _ = try await Purchases.shared.restorePurchases()
      return .restored
    } catch let error {
      return .failed(error)
    }
  }
}
