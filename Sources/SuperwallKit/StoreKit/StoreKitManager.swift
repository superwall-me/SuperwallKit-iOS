import Foundation
import StoreKit
import Combine

actor StoreKitManager {
  /// Retrieves products from storekit.
  private let productsManager: ProductsManager

  private(set) var productsById: [String: StoreProduct] = [:]
  private struct ProductProcessingResult {
    let productIdsToLoad: Set<String>
    let substituteProductsById: [String: StoreProduct]
    let productItems: [Product]
  }

  init(productsManager: ProductsManager) {
    self.productsManager = productsManager
  }

  func getProductVariables(for paywall: Paywall) async -> [ProductVariable] {
    guard let output = try? await getProducts(
      forPaywall: paywall,
      placement: nil
    ) else {
      return []
    }

    var productAttributes: [ProductVariable] = []

    // Add the StoreProduct attributes for each product at its corresponding index
    paywall.products.forEach { productItem in
      guard let storeProduct = output.productsById[productItem.id] else {
        return
      }

      if let name = productItem.name {
        productAttributes.append(
          ProductVariable(
            name: name,
            attributes: storeProduct.attributesJson
          )
        )
      }
    }

    return productAttributes
  }

  func getProducts(
    forPaywall paywall: Paywall?,
    placement: PlacementData?,
    substituting substituteProductsByLabel: [String: StoreProduct]? = nil
  ) async throws -> (productsById: [String: StoreProduct], productItems: [Product]) {
    let processingResult = removeAndStore(
      substituteProductsByLabel: substituteProductsByLabel,
      paywallProductIds: paywall?.productIds ?? [],
      productItems: paywall?.products ?? []
    )

    let products = try await productsManager.products(
      identifiers: processingResult.productIdsToLoad,
      forPaywall: paywall,
      placement: placement
    )

    var productsById = processingResult.substituteProductsById

    for product in products {
      productsById[product.productIdentifier] = product
      self.productsById[product.productIdentifier] = product
    }

    return (productsById, processingResult.productItems)
  }

  /// For each product to substitute, this replaces the paywall product at the given index and stores
  /// the substitute product in memory.
  private func removeAndStore(
    substituteProductsByLabel: [String: StoreProduct]?,
    paywallProductIds: [String],
    productItems: [Product]
  ) -> ProductProcessingResult {
    /// Product IDs to load in the future. Initialised to the given paywall products.
    var productIdsToLoad = paywallProductIds

    /// Products to substitute, initially empty.
    var substituteProductsById: [String: StoreProduct] = [:]

    /// The final product IDs by index. Initialised with the ones from the paywall object.
    var productItems: [Product] = productItems

    // If there are no substitutions, return what we have
    guard let substituteProductsByLabel = substituteProductsByLabel else {
      return ProductProcessingResult(
        productIdsToLoad: Set(productIdsToLoad),
        substituteProductsById: substituteProductsById,
        productItems: productItems
      )
    }

    // Otherwise, iterate over each substitute product
    for (name, product) in substituteProductsByLabel {
      let productId = product.productIdentifier

      // Map substitute product by its ID.
      substituteProductsById[productId] = product

      // Store the substitute product by id in the class' dictionary
      self.productsById[productId] = product

      if let index = productItems.firstIndex(where: { $0.name == name }) {
        // Update the product ID at the found index
        productItems[index] = Product(
          name: name,
          type: .appStore(.init(id: productId)),
          entitlements: product.entitlements
        )
      } else {
        // If it isn't found, just append to the list.
        productItems.append(
          Product(
            name: name,
            type: .appStore(.init(id: productId)),
            entitlements: product.entitlements
          )
        )
      }

      // Make sure we don't load the substitute product id
      productIdsToLoad.removeAll { $0 == productId }
    }

    return ProductProcessingResult(
      productIdsToLoad: Set(productIdsToLoad),
      substituteProductsById: substituteProductsById,
      productItems: productItems
    )
  }
}
