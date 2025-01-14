//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductsManager.swift
//
//  Created by Andrés Boedo on 7/14/20.
//
// swiftlint:disable function_body_length

import Foundation
import StoreKit

struct ProductRequest {
  let identifiers: Set<String>
  let paywall: Paywall?
  let placement: PlacementData?
  let retriesLeft: Int
}

class ProductsFetcherSK1: NSObject, ProductFetchable {
	private var cachedProductsByIdentifier: [String: SKProduct] = [:]
	private let queue = DispatchQueue(label: "com.superwall.ProductsManager")
	private var productsByRequest: [SKRequest: ProductRequest] = [:]
  private var paywallNameByRequest: [SKRequest: String] = [:]
  typealias ProductRequestCompletionBlock = (Result<Set<SKProduct>, Error>) -> Void
	private var completionHandlers: [Set<String>: [ProductRequestCompletionBlock]] = [:]
  private static let numberOfRetries: Int = 10
  private unowned let entitlementsInfo: EntitlementsInfo

  init(entitlementsInfo: EntitlementsInfo) {
    self.entitlementsInfo = entitlementsInfo
  }

  // MARK: - ProductsFetcher
  /// Gets StoreKit 1 products from identifiers.
  ///
  /// - Parameters:
  ///   - identifiers: A `Set` of product identifiers.
  /// - Returns: A `Set` of `StoreProducts`.
  /// - Throws: An error if it couldn't retrieve the products.
  func products(
    identifiers: Set<String>,
    forPaywall paywall: Paywall?,
    placement: PlacementData?
  ) async throws -> Set<StoreProduct> {
    let sk1Products = try await withCheckedThrowingContinuation { [weak self] continuation in
      self?.products(withIdentifiers: identifiers, forPaywall: paywall, placement: placement) { result in
        continuation.resume(with: result)
      }
    }
    let storeProducts = Set(sk1Products.map {
      let entitlements = entitlementsInfo.byProductId($0.productIdentifier)
      return StoreProduct(sk1Product: $0, entitlements: entitlements)
    })
    return storeProducts
  }

	private func products(
    withIdentifiers identifiers: Set<String>,
    forPaywall paywall: Paywall?,
    placement: PlacementData?,
    completion: @escaping ProductRequestCompletionBlock
  ) {
    // Return if there aren't any product IDs.
		if identifiers.isEmpty {
      completion(.success([]))
			return
		}

		queue.async { [weak self] in
      guard let self = self else {
        return
      }
      // If products already cached, return them
      let productsAlreadyCached = self.cachedProductsByIdentifier.filter { key, _ in identifiers.contains(key) }

      if productsAlreadyCached.count == identifiers.count {
        let productsAlreadyCachedSet = Set(self.cachedProductsByIdentifier.map { $0.value })
				Logger.debug(
          logLevel: .debug,
          scope: .productsManager,
          message: "Products Already Cached",
          info: ["product_ids": identifiers],
          error: nil
        )
        DispatchQueue.main.async {
          completion(.success(productsAlreadyCachedSet))
        }
				return
			}

      // If there are any existing completion handlers, it means there have already been some requests for products but they haven't loaded. Queue up this request's completion handler.
			if let existingHandlers = self.completionHandlers[identifiers] {
				Logger.debug(
          logLevel: .debug,
          scope: .productsManager,
          message: "Found Existing Product Request",
          info: ["product_ids": identifiers],
          error: nil
        )
				self.completionHandlers[identifiers] = existingHandlers + [completion]
				return
			}

      // Otherwise request products and enqueue the completion handler.
      // When the request finishes, all completion handlers will get called with the products.
			Logger.debug(
        logLevel: .debug,
        scope: .productsManager,
        message: "Creating New Request",
        info: ["product_ids": identifiers],
        error: nil
      )
      self.completionHandlers[identifiers] = [completion]
      startRequest(
        forIdentifiers: identifiers,
        paywall: paywall,
        placement: placement,
        retriesLeft: Self.numberOfRetries
      )
		}
	}

  // Note: this isn't thread-safe and must therefore be used inside of `queue` only.
  private func startRequest(
    forIdentifiers identifiers: Set<String>,
    paywall: Paywall?,
    placement: PlacementData?,
    retriesLeft: Int
  ) {
    let request = SKProductsRequest(productIdentifiers: identifiers)
    request.delegate = self
    self.productsByRequest[request] = ProductRequest(
      identifiers: identifiers,
      paywall: paywall,
      placement: placement,
      retriesLeft: retriesLeft
    )
    request.start()
  }

  private func cacheProducts(_ products: [SKProduct]) {
    let productsByIdentifier = products.reduce(into: [:]) { resultDict, product in
      resultDict[product.productIdentifier] = product
    }

    cachedProductsByIdentifier = cachedProductsByIdentifier.merging(productsByIdentifier)
  }

	private func cacheProduct(_ product: SKProduct) {
		queue.async { [weak self] in
      guard let self = self else {
        return
      }
			self.cachedProductsByIdentifier[product.productIdentifier] = product
		}
	}
}

// MARK: - SKProductsRequestDelegate
extension ProductsFetcherSK1: SKProductsRequestDelegate {
	func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
		queue.async { [weak self] in
      guard let self = self else {
        return
      }
			Logger.debug(
        logLevel: .debug,
        scope: .productsManager,
        message: "Products request received response",
        info: ["request": request.debugDescription],
        error: nil
      )
			guard let requestProducts = self.productsByRequest[request] else {
				Logger.debug(
          logLevel: .warn,
          scope: .productsManager,
          message: "Requested Products Not Found",
          info: ["request": request.debugDescription],
          error: nil
        )
				return
			}
      guard let completionBlocks = self.completionHandlers[requestProducts.identifiers] else {
				Logger.debug(
          logLevel: .error,
          scope: .productsManager,
          message: "Completion Handler Not Found",
          info: ["products": requestProducts, "request": request.debugDescription],
          error: nil
        )
				return
			}

      self.completionHandlers.removeValue(forKey: requestProducts.identifiers)
			self.productsByRequest.removeValue(forKey: request)

      if response.products.isEmpty,
        !requestProducts.identifiers.isEmpty {
        var errorMessage = "Could not load products"
        if let paywallName = self.paywallNameByRequest[request] {
          errorMessage += " from paywall \"\(paywallName)\""
        }
        Logger.debug(
          logLevel: .error,
          scope: .productsManager,
          message: "\(errorMessage). Visit https://superwall.com/l/missing-products to diagnose.",
          info: ["product_ids": requestProducts.identifiers.description]
        )
      }
      self.cacheProducts(response.products)

      for completion in completionBlocks {
        DispatchQueue.main.async {
          completion(.success(Set(response.products)))
        }
      }
      self.paywallNameByRequest.removeValue(forKey: request)
		}
	}

	func requestDidFinish(_ request: SKRequest) {
		Logger.debug(
      logLevel: .debug,
      scope: .productsManager,
      message: "Request Complete",
      info: ["request": request.debugDescription],
      error: nil
    )
		request.cancel()
	}

	func request(_ request: SKRequest, didFailWithError error: Error) {
    queue.async { [weak self] in
      guard let self = self else {
        return
      }
      Logger.debug(
        logLevel: .error,
        scope: .productsManager,
        message: "Request Failed",
        info: ["request": request.debugDescription],
        error: error
      )
      guard let productRequest = self.productsByRequest[request] else {
        Logger.debug(
          logLevel: .error,
          scope: .productsManager,
          message: "Requested Products Not Found.",
          info: ["request": request.debugDescription],
          error: error
        )
        return
      }
      if productRequest.retriesLeft <= 0 {
        guard let completionBlocks = self.completionHandlers[productRequest.identifiers] else {
          Logger.debug(
            logLevel: .error,
            scope: .productsManager,
            message: "Callbacks Not Found for Failed Request",
            info: ["request": request.debugDescription],
            error: error
          )
          return
        }

        self.completionHandlers.removeValue(forKey: productRequest.identifiers)
        self.productsByRequest.removeValue(forKey: request)
        self.paywallNameByRequest.removeValue(forKey: request)
        for completion in completionBlocks {
          DispatchQueue.main.async {
            completion(.failure(error))
          }
        }
        request.cancel()
      } else {
        self.queue.asyncAfter(deadline: .now() + .seconds(3)) {
          let retryCount = Self.numberOfRetries - (productRequest.retriesLeft - 1)
          Task {
            guard let paywall = productRequest.paywall else {
              return
            }
            let productLoadRetry = InternalSuperwallPlacement.PaywallProductsLoad(
              state: .retry(retryCount),
              paywallInfo: paywall.getInfo(fromPlacement: productRequest.placement),
              placementData: productRequest.placement
            )
            await Superwall.shared.track(productLoadRetry)
          }
          Logger.debug(
            logLevel: .info,
            scope: .productsManager,
            message: "Retrying product request.",
            info: [
              "retry_count": retryCount,
              "product_ids": productRequest.identifiers
            ],
            error: error
          )
          self.startRequest(
            forIdentifiers: productRequest.identifiers,
            paywall: productRequest.paywall,
            placement: productRequest.placement,
            retriesLeft: productRequest.retriesLeft - 1
          )
        }
      }
    }
	}
}

// MARK: - Sendable
// @unchecked because:
// - It has mutable state, but it's made thread-safe through `queue`.
// - It's non-final, but only because we mock it.
extension ProductsFetcherSK1: @unchecked Sendable {}
