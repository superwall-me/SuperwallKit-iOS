//
//  InternalPurchaseController.swift
//
//
//  Created by Bryan Dubno on 11/3/23.
//

import Foundation

protocol InternalPurchaseController {
  var isInternal: Bool { get }
}

extension PurchaseController {
  var isInternal: Bool {
      return (self as? InternalPurchaseController)?.isInternal ?? false
  }
}
