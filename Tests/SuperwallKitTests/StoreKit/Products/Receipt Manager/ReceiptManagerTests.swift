//
//  InAppReceiptTests.swift
//  
//
//  Created by Yusuf Tör on 24/03/2022.
//
// swiftlint:disable all

import XCTest
@testable import SuperwallKit

// TODO: SK2 Tests
class ReceiptManagerTests: XCTestCase {
  let dependencyContainer = DependencyContainer()
  lazy var purchaseController: AutomaticPurchaseController = {
    return AutomaticPurchaseController(
      factory: dependencyContainer,
      entitlementsInfo: dependencyContainer.entitlementsInfo
    )
  }()

  func test_loadPurchasedProducts_nilProducts() async {
    let product = MockSkProduct(subscriptionGroupIdentifier: "abc")
    let getReceiptData: () -> Data = {
      return MockReceiptData.newReceipt
    }
    let productsFetcher = ProductsFetcherSK1Mock(
      productCompletionResult: .success([StoreProduct(sk1Product: product, entitlements: [.stub()])]),
      entitlementsInfo: dependencyContainer.entitlementsInfo
    )
    let productsManager = ProductsManager(
      entitlementsInfo: dependencyContainer.entitlementsInfo,
      storeKitVersion: .storeKit1,
      productsFetcher: productsFetcher
    )
    let sk1ReceiptManager = SK1ReceiptManager(receiptData: getReceiptData)
    let receiptManager = ReceiptManager(
      storeKitVersion: .storeKit1,
      productsManager: productsManager,
      receiptManager: sk1ReceiptManager,
      receiptDelegate: purchaseController
    )

    await receiptManager.loadPurchasedProducts()
    let purchasedSubscriptionGroupIds = sk1ReceiptManager.purchasedSubscriptionGroupIds
    XCTAssertEqual(purchasedSubscriptionGroupIds, ["abc"])
  }

  func test_loadPurchasedProducts_productError() async {
    let getReceiptData: () -> Data = {
      return MockReceiptData.newReceipt
    }
    let productsFetcher = ProductsFetcherSK1Mock(
      productCompletionResult: .failure(TestError("error")),
      entitlementsInfo: dependencyContainer.entitlementsInfo
    )
    let productsManager = ProductsManager(
      entitlementsInfo: dependencyContainer.entitlementsInfo,
      storeKitVersion: .storeKit1,
      productsFetcher: productsFetcher
    )
    let sk1ReceiptManager = SK1ReceiptManager(receiptData: getReceiptData)
    let receiptManager = ReceiptManager(
      storeKitVersion: .storeKit1,
      productsManager: productsManager,
      receiptManager: sk1ReceiptManager,
      receiptDelegate: purchaseController
    )

    await receiptManager.loadPurchasedProducts()
    let purchasedSubscriptionGroupIds = sk1ReceiptManager.purchasedSubscriptionGroupIds
    XCTAssertNil(purchasedSubscriptionGroupIds)
  }

  func test_isFreeTrialAvailable() {
    
  }
  /*
  // MARK: - Test processing of receipt data
  func testCrashReceipt_hasntPurchased() {
    let getReceiptData: () -> Data = {
      return MockReceiptData.crashReceipt
    }
    let inAppReceipt = ReceiptManager(getReceiptData: getReceiptData)
    let hasPurchased = inAppReceipt.hasPurchasedInSubscriptionGroupOfProduct(withId: "CYCLEMAPS_PREMIUM")
    XCTAssertFalse(hasPurchased)
  }

  func testNewReceipt_hasPurchased() {
    let getReceiptData: () -> Data = {
      return MockReceiptData.newReceipt
    }
    let inAppReceipt = ReceiptManager(getReceiptData: getReceiptData)
    let hasPurchased = inAppReceipt.hasPurchasedInSubscriptionGroupOfProduct(withId: "CYCLEMAPS_PREMIUM")
    XCTAssertTrue(hasPurchased)
  }

  func testNewReceipt_hasntPurchased() {
    let getReceiptData: () -> Data = {
      return MockReceiptData.newReceipt
    }
    let inAppReceipt = ReceiptManager(getReceiptData: getReceiptData)
    let hasPurchased = inAppReceipt.hasPurchasedInSubscriptionGroupOfProduct(withId: "OTHER_ID")
    XCTAssertFalse(hasPurchased)
  }

  func testLegacyReceipt_hasPurchased() {
    let getReceiptData: () -> Data = {
      return MockReceiptData.legacyReceipt
    }
    let inAppReceipt = ReceiptManager(getReceiptData: getReceiptData)
    let hasPurchased = inAppReceipt.hasPurchasedInSubscriptionGroupOfProduct(withId: "com.nutcallalert.inapp.optimum")
    XCTAssertTrue(hasPurchased)
  }

  func testLegacyReceipt_hasntPurchased() {
    let getReceiptData: () -> Data = {
      return MockReceiptData.legacyReceipt
    }
    let inAppReceipt = ReceiptManager(getReceiptData: getReceiptData)
    let hasPurchased = inAppReceipt.hasPurchasedInSubscriptionGroupOfProduct(withId: "otherId")
    XCTAssertFalse(hasPurchased)
  }

  func testPurchasedProductIds() {
    let getReceiptData: () -> Data = {
      return MockReceiptData.legacyReceipt
    }
    let inAppReceipt = ReceiptManager(getReceiptData: getReceiptData)
    let hasPurchased = inAppReceipt.hasPurchasedInSubscriptionGroupOfProduct(withId: "com.nutcallalert.inapp.optimum")
    XCTAssertTrue(hasPurchased)
    XCTAssertEqual(inAppReceipt.purchasedProductIds, Set(["com.nutcallalert.inapp.pro", "com.nutcallalert.inapp.optimum", "com.nutcallalert.inapp.lite"]))
  }

  // MARK: - hasPurchasedInSubscriptionGroupOfProduct

  func test_purchasedWithinSubscriptionGroupId() {
    let storeKitManager = StoreKitManager()
    let subscriptionGroupId = "abc"

    let proProductId = "com.nutcallalert.inapp.pro"
    let proProduct = MockSkProduct(
      productIdentifier: proProductId,
      subscriptionGroupIdentifier: subscriptionGroupId
    )

    let notYetPurchasedProductId = "com.nutcallalert.inapp.notyetpurchased"
    let notYetPurchasedProduct = MockSkProduct(
      productIdentifier: notYetPurchasedProductId,
      subscriptionGroupIdentifier: subscriptionGroupId
    )
    storeKitManager.productsById = [
      proProductId: proProduct,
      notYetPurchasedProductId: notYetPurchasedProduct
    ]
    let getReceiptData: () -> Data = {
      return MockReceiptData.legacyReceipt
    }
    let inAppReceipt = ReceiptManager(
      getReceiptData: getReceiptData,
      storeKitManager: storeKitManager
    )
    inAppReceipt.loadSubscriptionGroupIds()
    let hasPurchased = inAppReceipt.hasPurchasedInSubscriptionGroupOfProduct(withId: notYetPurchasedProductId)
    XCTAssertTrue(hasPurchased)
    XCTAssertEqual(inAppReceipt.purchasedProductIds, Set(["com.nutcallalert.inapp.pro", "com.nutcallalert.inapp.optimum", "com.nutcallalert.inapp.lite"]))
  }

  func test_hasntPurchasedWithinSubscriptionGroupId() {
    let storeKitManager = StoreKitManager()
    let subscriptionGroupId1 = "abc"
    let subscriptionGroupId2 = "cde"

    let proProductId = "com.nutcallalert.inapp.pro"
    let proProduct = MockSkProduct(
      productIdentifier: proProductId,
      subscriptionGroupIdentifier: subscriptionGroupId1
    )

    let notYetPurchasedProductId = "com.nutcallalert.inapp.notyetpurchased"
    let notYetPurchasedProduct = MockSkProduct(
      productIdentifier: notYetPurchasedProductId,
      subscriptionGroupIdentifier: subscriptionGroupId2
    )
    storeKitManager.productsById = [
      proProductId: proProduct,
      notYetPurchasedProductId: notYetPurchasedProduct
    ]
    let getReceiptData: () -> Data = {
      return MockReceiptData.legacyReceipt
    }
    let inAppReceipt = ReceiptManager(
      getReceiptData: getReceiptData,
      storeKitManager: storeKitManager
    )
    inAppReceipt.loadSubscriptionGroupIds()
    let hasPurchased = inAppReceipt.hasPurchasedInSubscriptionGroupOfProduct(withId: notYetPurchasedProductId)
    XCTAssertFalse(hasPurchased)
  }

  func test_failedToLoadSubscriptionGroupIds() {
    let storeKitManager = StoreKitManager()
    let subscriptionGroupId1 = "abc"

    let proProductId = "com.nutcallalert.inapp.pro"
    let proProduct = MockSkProduct(
      productIdentifier: proProductId,
      subscriptionGroupIdentifier: subscriptionGroupId1
    )

    let notYetPurchasedProductId = "com.nutcallalert.inapp.notyetpurchased"
    let notYetPurchasedProduct = MockSkProduct(
      productIdentifier: notYetPurchasedProductId,
      subscriptionGroupIdentifier: subscriptionGroupId1
    )
    storeKitManager.productsById = [
      proProductId: proProduct,
      notYetPurchasedProductId: notYetPurchasedProduct
    ]
    let getReceiptData: () -> Data = {
      return MockReceiptData.legacyReceipt
    }
    let inAppReceipt = ReceiptManager(
      getReceiptData: getReceiptData,
      storeKitManager: storeKitManager
    )
    inAppReceipt.failedToLoadPurchasedProducts()
    let hasPurchased = inAppReceipt.hasPurchasedInSubscriptionGroupOfProduct(withId: notYetPurchasedProductId)
    XCTAssertFalse(hasPurchased)
  }

  func test_nonAutorenewingSubscription() {
    let storeKitManager = StoreKitManager()
    let subscriptionGroupId1 = "abc"

    let proProductId = "com.nutcallalert.inapp.pro"
    let proProduct = MockSkProduct(
      productIdentifier: proProductId
    )

    storeKitManager.productsById = [
      proProductId: proProduct
    ]
    let getReceiptData: () -> Data = {
      return MockReceiptData.legacyReceipt
    }
    let inAppReceipt = ReceiptManager(
      getReceiptData: getReceiptData,
      storeKitManager: storeKitManager
    )
    inAppReceipt.loadSubscriptionGroupIds()
    let hasPurchased = inAppReceipt.hasPurchasedInSubscriptionGroupOfProduct(withId: proProductId)
    XCTAssertTrue(hasPurchased)
  }*/
}

