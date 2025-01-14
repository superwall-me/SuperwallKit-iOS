//
//  File.swift
//  SuperwallKit
//
//  Created by Yusuf Tör on 19/09/2024.
//

import Foundation
import StoreKit

@available(iOS 15.0, *)
final actor ProductsFetcherSK2: ProductFetchable {
  private unowned let entitlementsInfo: EntitlementsInfo

  init(entitlementsInfo: EntitlementsInfo) {
    self.entitlementsInfo = entitlementsInfo
  }

  func products(
    identifiers: Set<String>,
    forPaywall paywall: Paywall?,
    placement: PlacementData?
  ) async throws -> Set<StoreProduct> {
    let sk2Products = try await StoreKit.Product.products(for: identifiers)

    if sk2Products.isEmpty,
      !identifiers.isEmpty {
      var errorMessage = "Could not load products"
      if let paywallName = paywall?.name {
        errorMessage += " from paywall \"\(paywallName)\""
      }
      Logger.debug(
        logLevel: .error,
        scope: .productsManager,
        message: "\(errorMessage). Visit https://superwall.com/l/missing-products to diagnose.",
        info: ["product_ids": identifiers.description]
      )
    }

    let storeProducts = Set(sk2Products.map {
      let entitlements = entitlementsInfo.byProductId($0.id)
      return StoreProduct(sk2Product: $0, entitlements: entitlements)
    })
    return storeProducts
  }
}
