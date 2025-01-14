//
//  File.swift
//  
//
//  Created by Yusuf Tör on 30/05/2022.
//
// swiftlint:disable all

import Foundation
import StoreKit

final class MockSKPaymentTransaction: SKPaymentTransaction, @unchecked Sendable {
  private var internalState: SKPaymentTransactionState

  override var transactionState: SKPaymentTransactionState {
    return internalState
  }

  init(state: SKPaymentTransactionState) {
    internalState = state
    super.init()
  }
}
