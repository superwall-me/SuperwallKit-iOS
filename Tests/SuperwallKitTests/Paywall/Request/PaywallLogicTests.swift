//
//  PaywallLogicTests.swift
//  
//
//  Created by Yusuf Tör on 17/03/2022.
//
// swiftlint:disable all

import XCTest
@testable import SuperwallKit
import StoreKit

@available(iOS 14.0, *)
class PaywallLogicTests: XCTestCase {
  // MARK: - Request Hash
  func testRequestHash_withIdentifierNoEvent() {
    // Given
    let id = "myid"
    let locale = "en_US"

    // When
    let hash = PaywallLogic.requestHash(
      identifier: id,
      locale: locale,
      joinedSubstituteProductIds: nil
    )

    // Then
    XCTAssertEqual(hash, "\(id)_\(locale)_")
  }

  func testRequestHash_withIdentifierWithEvent() {
    // Given
    let id = "myid"
    let locale = "en_US"
    let event: PlacementData = .stub()

    // When
    let hash = PaywallLogic.requestHash(
      identifier: id,
      placement: event,
      locale: locale,
      joinedSubstituteProductIds: nil
    )

    // Then
    XCTAssertEqual(hash, "\(id)_\(locale)_")
  }

  func testRequestHash_withIdentifierWithEventAndProducts() {
    // Given
    let id = "myid"
    let locale = "en_US"
    let event: PlacementData = .stub()
    let product1 = StoreProduct(
      sk1Product: MockSkProduct(productIdentifier: "abc"),
      entitlements: []
    )
    let product2 = StoreProduct(
      sk1Product: MockSkProduct(productIdentifier: "def"),
      entitlements: []
    )
    let ids = ["abc", "def"].joined()

    // When
    let hash = PaywallLogic.requestHash(
      identifier: id,
      placement: event,
      locale: locale,
      joinedSubstituteProductIds: ids
    )

    // Then
    XCTAssertEqual(hash, "\(id)_\(locale)_abcdef")
  }

  func testRequestHash_noIdentifierWithEvent() {
    // Given
    let locale = "en_US"
    let eventName = "MyEvent"
    let event: PlacementData = .stub()
      .setting(\.name, to: eventName)

    // When
    let hash = PaywallLogic.requestHash(
      placement: event,
      locale: locale,
      joinedSubstituteProductIds: nil
    )

    // Then
    XCTAssertEqual(hash, "\(eventName)_\(locale)_")
  }

  func testRequestHash_noIdentifierNoEvent() {
    // Given
    let locale = "en_US"

    // When
    let hash = PaywallLogic.requestHash(
      locale: locale,
      joinedSubstituteProductIds: nil
    )

    // Then
    XCTAssertEqual(hash, "$called_manually_\(locale)_")
  }

  func testRequestHash_noIdentifierWithEventAndProducts() {
    // Given
    let locale = "en_US"
    let eventName = "MyEvent"
    let event: PlacementData = .stub()
      .setting(\.name, to: eventName)
    let product1 = StoreProduct(
      sk1Product: MockSkProduct(productIdentifier: "abc"),
      entitlements: []
    )
    let ids = "abc"

    // When
    let hash = PaywallLogic.requestHash(
      placement: event,
      locale: locale,
      joinedSubstituteProductIds: ids
    )

    // Then
    XCTAssertEqual(hash, "\(eventName)_\(locale)_abc")
  }

  // MARK: - getVariablesAndFreeTrial
  func testGetVariablesAndFreeTrial_noProducts() async {
    let response = await PaywallLogic.getVariablesAndFreeTrial(
      productItems: [],
      productsById: [:],
      isFreeTrialAvailableOverride: nil,
      isFreeTrialAvailable: { product in return false }
    )

    let expectation = ProductProcessingOutcome(
      productVariables: [],
      swProducts: [],
      isFreeTrialAvailable: false
    )

    XCTAssertEqual(response.isFreeTrialAvailable, expectation.isFreeTrialAvailable)
    XCTAssertTrue(response.productVariables.isEmpty)
    XCTAssertTrue(response.swProducts.isEmpty)
  }

  func testGetVariablesAndFreeTrial_productNotFound() async {
    let productId = "id1"
    let products = [Product(
      name: "primary",
      type: .appStore(.init(id: productId)),
      entitlements: []
    )]

    let skProductId = "id2"
    let skProduct = MockSkProduct(
      productIdentifier: skProductId,
      price: 1.99
    )
    let productsById = [skProductId: StoreProduct(sk1Product: skProduct, entitlements: [])]

    let response = await PaywallLogic.getVariablesAndFreeTrial(
      productItems: products,
      productsById: productsById,
      isFreeTrialAvailableOverride: nil,
      isFreeTrialAvailable: { product in return false }
    )

    let expectation = ProductProcessingOutcome(
      productVariables: [],
      swProducts: [],
      isFreeTrialAvailable: false
    )

    XCTAssertEqual(response.isFreeTrialAvailable, expectation.isFreeTrialAvailable)
    XCTAssertTrue(response.productVariables.isEmpty)
    XCTAssertTrue(response.swProducts.isEmpty)
  }

  func testGetVariablesAndFreeTrial_secondaryProduct() async {
    // Given
    let productId = "id1"
    let products = [Product(
      name: "secondary",
      type: .appStore(.init(id: productId)),
      entitlements: []
    )]

    let product = StoreProduct(
      sk1Product:
        MockSkProduct(
          productIdentifier: productId,
          price: 1.99
        ),
      entitlements: []
    )
    let productsById = [productId: product]

    // When
    let response = await PaywallLogic.getVariablesAndFreeTrial(
      productItems: products,
      productsById: productsById,
      isFreeTrialAvailableOverride: nil,
      isFreeTrialAvailable: { product in return false }
    )

    // Then

    let expectedProductVariables = [ProductVariable(
      name: "secondary",
      attributes: product.attributesJson
    )]
    XCTAssertFalse(response.isFreeTrialAvailable)
    XCTAssertEqual(response.productVariables, expectedProductVariables)
  }

  func testGetVariablesAndFreeTrial_primaryProductHasPurchased_noOverride() async {
    // Given
    let productId = "id1"
    let products = [Product(
      name: "primary",
      type: .appStore(.init(id: productId)), entitlements: []
    )]
    let mockIntroPeriod = MockIntroductoryPeriod(
      testSubscriptionPeriod: MockSubscriptionPeriod()
    )

    let product = StoreProduct(
      sk1Product:
        MockSkProduct(
          productIdentifier: productId,
          introPeriod: mockIntroPeriod,
          price: 1.99
        ), 
      entitlements: []
    )
    let productsById = [productId: product]

    
    // When
    let response = await PaywallLogic.getVariablesAndFreeTrial(
      productItems: products,
      productsById: productsById,
      isFreeTrialAvailableOverride: nil,
      isFreeTrialAvailable: { _ in
        return false
      }
    )

    // Then
    let expectedProductVariables = [ProductVariable(
      name: "primary",
      attributes: product.attributesJson
    )]

    XCTAssertFalse(response.isFreeTrialAvailable)
    XCTAssertEqual(response.productVariables, expectedProductVariables)
  }

  func testGetVariablesAndFreeTrial_primaryProductHasntPurchased_noOverride() async {
    // Given
    let productId = "id1"
    let products = [Product(
      name: "primary",
      type: .appStore(.init(id: productId)), entitlements: []
    )]
    let mockIntroPeriod = MockIntroductoryPeriod(
      testSubscriptionPeriod: MockSubscriptionPeriod()
    )
    let product = StoreProduct(
      sk1Product:
        MockSkProduct(
          productIdentifier: productId,
          introPeriod: mockIntroPeriod,
          price: 1.99
        ),
      entitlements: []
    )
    let productsById = [productId: product]

    // When
    let response = await PaywallLogic.getVariablesAndFreeTrial(
      productItems: products,
      productsById: productsById,
      isFreeTrialAvailableOverride: nil,
      isFreeTrialAvailable: { _ in
        return true
      }
    )

    // Then
    let expectedVariables = [ProductVariable(
      name: "primary",
      attributes: product.attributesJson
    )]

    XCTAssertTrue(response.isFreeTrialAvailable)
    XCTAssertEqual(response.productVariables, expectedVariables)
  }

  func testGetVariablesAndFreeTrial_primaryProductHasPurchased_withOverride() async {
    // Given
    let productId = "id1"
    let products = [Product(
      name: "primary",
      type: .appStore(.init(id: productId)), 
      entitlements: []
    )]
    let mockIntroPeriod = MockIntroductoryPeriod(
      testSubscriptionPeriod: MockSubscriptionPeriod()
    )
    let product = StoreProduct(
      sk1Product:
        MockSkProduct(
          productIdentifier: productId,
          introPeriod: mockIntroPeriod,
          price: 1.99
        ), 
      entitlements: []
    )
    let productsById = [productId: product]

    // When
    let response = await PaywallLogic.getVariablesAndFreeTrial(
      productItems: products,
      productsById: productsById,
      isFreeTrialAvailableOverride: true,
      isFreeTrialAvailable: { _ in
        return false
      }
    )

    // Then
    let expectedProductVariables = [ProductVariable(
      name: "primary",
      attributes: product.attributesJson
    )]
    XCTAssertTrue(response.isFreeTrialAvailable)
    XCTAssertEqual(response.productVariables, expectedProductVariables)
  }
}
