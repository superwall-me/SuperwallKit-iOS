//
//  RestoreResult.swift
//  
//
//  Created by Jake Mor on 4/27/23.
//


import Foundation
import StoreKit

/// An enum that defines the possible outcomes of attempting to restore a product.
///
/// When implementing the ``PurchaseController/restorePurchases()`` delegate
/// method, all cases should be considered.
public enum RestorationResult: Sendable, Equatable {
  /// The restore was successful
  ///
  /// - Warning: This does not mean the user is subscribed, it just means your restore
  /// logic did not fail due to some error. User will see an alert if `Superwall.shared.entitlements.active` is
  /// not empty after returning this value.
  case restored

  /// The restore failed for some reason (i.e. you were not able to determine if the user has an active subscription.
  /// User will see an alert if this value is returned. Optionally pass through an error.
  case failed(Error?)

  public static func == (lhs: RestorationResult, rhs: RestorationResult) -> Bool {
    switch (lhs, rhs) {
    case (.restored, .restored), (.failed, .failed):
      return true
    default:
      return false
    }
  }

  func toObjc() -> RestorationResultObjc {
    switch self {
    case .restored:
      return .restored
    case .failed:
      return .failed
    }
  }
}

/// An enum that defines the possible outcomes of attempting to restore a product.
///
/// When implementing the ``PurchaseControllerObjc/restorePurchases(completion:)`` delegate
/// method, all cases should be considered.
@objc(SWKRestorationResult)
public enum RestorationResultObjc: Int, Sendable, Equatable {
  /// The restore was successful – this does not mean the user is subscribed, it just means your restore
  /// logic did not fail due to some error. User will see an alert if `Superwall.shared.entitlements.active` is
  /// not empty after returning this value.
  case restored

  /// The restore failed for some reason, e.g. you were not able to determine if the user has an active subscription.
  /// User will see an alert if this value is returned.
  case failed
}
