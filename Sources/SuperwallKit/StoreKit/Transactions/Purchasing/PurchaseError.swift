//
//  File.swift
//  
//
//  Created by Yusuf Tör on 29/08/2023.
//

import Foundation

enum PurchaseError: LocalizedError {
  case productUnavailable
  case noSk1Product
  case unknown
  case noTransactionDetected
  case unverifiedTransaction

  var errorDescription: String? {
    switch self {
    case .productUnavailable:
      return "There was an error retrieving the product to purchase."
    case .noSk1Product:
      return "No StoreKit 1 product found."
    case .noTransactionDetected:
      return "No receipt was found on device for the product transaction."
    case .unverifiedTransaction:
      return "The product transaction could not be verified."
    case .unknown:
      return "An unknown error occurred."
    }
  }
}
