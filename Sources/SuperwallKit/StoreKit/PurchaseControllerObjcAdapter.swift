//
//  PurchaseControllerObjcAdapter.swift
//
//
//  Created by Bryan Dubno on 11/1/23.
//

import Foundation
import StoreKit

public class PurchaseControllerObjcAdapter: PurchaseController {
  private let objcController: PurchaseControllerObjc

  public init(objcController: PurchaseControllerObjc) {
    self.objcController = objcController
  }

  public func purchase(product: SKProduct) async -> PurchaseResult {
    return await withCheckedContinuation { continuation in
      objcController.purchase(product: product) { (result, error) in
        if let error = error {
          continuation.resume(returning: .failed(error))
        } else {
          switch result {
          case .purchased:
            continuation.resume(returning: .purchased)
          case .restored:
            continuation.resume(returning: .restored)
          case .pending:
            continuation.resume(returning: .pending)
          case .cancelled:
            continuation.resume(returning: .cancelled)
          case .failed:
            break
          }
        }
      }
    }
  }

  public func restorePurchases() async -> RestorationResult {
    return await withCheckedContinuation { continuation in
      objcController.restorePurchases { (result, error) in
        switch result {
        case .restored:
          continuation.resume(returning: .restored)
        case .failed:
          continuation.resume(returning: .failed(error))
        }
      }
    }
  }
}
