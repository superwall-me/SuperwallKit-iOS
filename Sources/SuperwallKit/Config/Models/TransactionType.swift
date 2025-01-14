//
//  TransactionType.swift
//  SuperwallKit
//
//  Created by Yusuf Tör on 22/11/2024.
//

@objc(SWKTransactionType)
public enum TransactionType: Int, CustomStringConvertible {
  case nonRecurringProductPurchase
  case freeTrialStart
  case subscriptionStart

  public var description: String {
    switch self {
    case .nonRecurringProductPurchase: return "NON_RECURRING_PRODUCT_PURCHASE"
    case .freeTrialStart: return "FREE_TRIAL_START"
    case .subscriptionStart: return "SUBSCRIPTION_START"
    }
  }
}
