//
//  PurchaseResult.swift
//  
//
//  Created by Yusuf Tör on 18/10/2022.
//

import Foundation
import StoreKit

/// An enum that defines the possible outcomes of attempting to purchase a product.
///
/// When implementing the ``PurchaseController/purchase(product:)`` delegate
/// method, all cases should be considered.
public enum PurchaseResult: Sendable, Equatable {
  /// The purchase was cancelled.
  ///
  /// In StoreKit 1, you can detect this by switching over the error code enum from the `.failed`
  /// transaction state. The following cases should all be reported as a `.cancelled` state to
  /// Superwall:
  /// - `.overlayCancelled`,
  /// - `.paymentCancelled`,
  /// - `.overlayTimeout`
  ///
  /// In StoreKit 2, this is the `.cancelled` error state.
  ///
  /// With RevenueCat, this is when the `userCancelled` boolean returns `true` from the purchase
  /// method.
  case cancelled

  /// The product was purchased.
  case purchased

  /// The product was restored.
  case restored

  /// The purchase is pending and requires action from the developer.
  ///
  /// In StoreKit 1, this is the same as the `.deferred` transaction state.
  ///
  /// With RevenueCat, this is retrieved by switching over the the thrown error during purchase. This is
  /// the same as `.paymentPendingError`.
  case pending

  /// The purchase failed for a reason other than the user cancelling or the payment pending.
  ///
  /// Send the `Error` back to Superwall to alert the user.
  case failed(Error)

  public static func == (lhs: PurchaseResult, rhs: PurchaseResult) -> Bool {
    switch (lhs, rhs) {
    case (.cancelled, .cancelled),
      (.purchased, .purchased),
      (.pending, .pending):
      return true
    case let (.failed(error), .failed(error2)):
      return error.safeLocalizedDescription == error2.safeLocalizedDescription
    default:
      return false
    }
  }

  func toObjc() -> PurchaseResultObjc {
    switch self {
    case .cancelled: return .cancelled
    case .purchased: return .purchased
    case .restored: return .restored
    case .pending: return .pending
    case .failed: return .failed
    }
  }
}

// MARK: - Objective-C Only

/// An Objective-C-only enum that defines the possible outcomes of attempting to purchase a product.
@objc(SWKPurchaseResult)
public enum PurchaseResultObjc: Int, Sendable, Equatable {
  /// The purchase was cancelled.
  ///
  /// In StoreKit 1, you can detect this by switching over the error code from the `.failed`
  /// transaction state. The following cases should all be reported as a `.cancelled` state to
  /// Superwall:
  /// - `.overlayCancelled`,
  /// - `.paymentCancelled`,
  /// - `.overlayTimeout`
  ///
  /// With RevenueCat, this is when the `userCancelled` boolean returned from the purchase
  /// method is `true`.
  case cancelled

  /// The product was purchased.
  case purchased

  /// The product was restored.
  case restored

  /// The purchase is pending and requires action from the developer.
  ///
  /// In StoreKit 1, this is the same as the `.deferred` transaction state.
  ///
  /// With RevenueCat, this is the same as the `.paymentPendingError`.
  case pending

  /// The purchase failed for a reason other than the user cancelling or the payment pending.
  ///
  /// Send the `Error` back in the ``PurchaseControllerObjc/purchase(product:completion:)``
  /// completion block to Superwall to alert the user.
  case failed
}
