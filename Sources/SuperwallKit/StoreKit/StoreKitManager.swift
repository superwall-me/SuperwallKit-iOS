import Foundation
import StoreKit
import Combine

actor StoreKitManager {
  private let factory: DependencyContainer

  /// Retrieves products from storekit.
  private var productsFetcher: ProductsFetcherSK1 {
    return factory.productsFetcher
  }

  private(set) var productsById: [String: StoreProduct] = [:]
  private struct ProductProcessingResult {
    let productIdsToLoad: Set<String>
    let substituteProductsById: [String: StoreProduct]
    let products: [Product]
  }

  init(factory: DependencyContainer) {
    self.factory = factory
  }

  func getProductVariables(for paywall: Paywall) async -> [ProductVariable] {
    guard let output = try? await getProducts(
      withIds: paywall.productIds,
      forPaywall: paywall.name
    ) else {
      return []
    }

    let variables = paywall.products.compactMap { product -> ProductVariable? in
      guard let storeProduct = output.productsById[product.id] else {
        return nil
      }
      return ProductVariable(
        type: product.type,
        attributes: storeProduct.attributesJson
      )
    }

    return variables
  }

  func getProducts(
    withIds responseProductIds: [String],
    forPaywall paywallName: String? = nil,
    responseProducts: [Product] = [],
    substituting substituteProducts: PaywallProducts? = nil
  ) async throws -> (productsById: [String: StoreProduct], products: [Product]) {
    let processingResult = removeAndStore(
      substituteProducts: substituteProducts,
      fromResponseProductIds: responseProductIds,
      responseProducts: responseProducts
    )

    let products = try await productsFetcher.products(
      identifiers: processingResult.productIdsToLoad,
      forPaywall: paywallName
    )

    var productsById = processingResult.substituteProductsById

    for product in products {
      productsById[product.productIdentifier] = product
      self.productsById[product.productIdentifier] = product
    }

    return (productsById, processingResult.products)
  }

  /// For each product to substitute, this removes the response product at the given index and stores
  /// the substitute product in memory.
  private func removeAndStore(
    substituteProducts: PaywallProducts?,
    fromResponseProductIds responseProductIds: [String],
    responseProducts: [Product]
  ) -> ProductProcessingResult {
    var responseProductIds = responseProductIds
    var substituteProductsById: [String: StoreProduct] = [:]
    var products: [Product] = responseProducts

    func storeAndSubstitute(
      _ product: StoreProduct,
      type: ProductType,
      index: Int
    ) {
      let id = product.productIdentifier
      substituteProductsById[id] = product
      self.productsById[id] = product
      let product = Product(type: type, id: id)
      products[guarded: index] = product
      responseProductIds.remove(safeAt: index)
    }

    if let primaryProduct = substituteProducts?.primary {
      storeAndSubstitute(
        primaryProduct,
        type: .primary,
        index: 0
      )
    }
    if let secondaryProduct = substituteProducts?.secondary {
      storeAndSubstitute(
        secondaryProduct,
        type: .secondary,
        index: 1
      )
    }
    if let tertiaryProduct = substituteProducts?.tertiary {
      storeAndSubstitute(
        tertiaryProduct,
        type: .tertiary,
        index: 2
      )
    }

    return ProductProcessingResult(
      productIdsToLoad: Set(responseProductIds),
      substituteProductsById: substituteProductsById,
      products: products
    )
  }
}
