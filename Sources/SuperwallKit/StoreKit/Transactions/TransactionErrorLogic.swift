//
//  File.swift
//  
//
//  Created by Yusuf Tör on 21/10/2022.
//

import Foundation
import StoreKit

/// The error that occurred when a transaction failed.
public enum TransactionError: Error {
  /// The transaction is pending approval via a parent or guardian.
  case pending(String)

  /// The transaction failed.
  case failure(String, StoreProduct)
}

enum TransactionErrorLogic {
  enum ErrorOutcome {
    case cancelled
    case presentAlert
  }

  static func handle(
    _ error: Error,
    triggers: Set<String>,
    shouldShowPurchaseFailureAlert: Bool
  ) -> ErrorOutcome? {
    if #available(iOS 15.0, *),
      let error = error as? StoreKitError {
      switch error {
      case .userCancelled:
        return .cancelled
      default:
        break
      }
    }

    if let error = error as? SKError {
      switch error.code {
      case .overlayCancelled,
        .paymentCancelled:
        return .cancelled
      default:
        break
      }

      if #available(iOS 14, *) {
        switch error.code {
        case .overlayTimeout:
          return .cancelled
        default:
          break
        }
      }
    }

    let transactionFailExists = triggers.contains(SuperwallPlacementObjc.transactionFail.description)

    if shouldShowPurchaseFailureAlert,
      !transactionFailExists {
      return .presentAlert
    } else {
      return nil
    }
  }
}
