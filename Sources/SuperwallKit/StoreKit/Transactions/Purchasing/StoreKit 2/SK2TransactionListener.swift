//
//  File.swift
//  SuperwallKit
//
//  Created by Yusuf Tör on 20/09/2024.
//

import Foundation
import StoreKit

@available(iOS 15.0, *)
actor SK2TransactionListener {
  private(set) var taskHandle: Task<Void, Never>?
  private let shouldFinishTransactions: Bool
  private let factory: HasExternalPurchaseControllerFactory
  private unowned let receiptManager: ReceiptManager

  deinit {
    self.taskHandle?.cancel()
    self.taskHandle = nil
  }

  init(
    shouldFinishTransactions: Bool,
    receiptManager: ReceiptManager,
    factory: HasExternalPurchaseControllerFactory
  ) {
    self.shouldFinishTransactions = shouldFinishTransactions
    self.receiptManager = receiptManager
    self.factory = factory
  }

  func listenForTransactions() {
    self.taskHandle?.cancel()
    self.taskHandle = Task(priority: .utility) { [weak self] in
      for await result in Transaction.updates {
        guard let self = self else { break }
        switch result {
        case let .verified(transaction),
          let .unverified(transaction, _):

          if self.shouldFinishTransactions {
            await transaction.finish()
          }

          await receiptManager.loadPurchasedProducts()
        }
      }
    }
  }
}
