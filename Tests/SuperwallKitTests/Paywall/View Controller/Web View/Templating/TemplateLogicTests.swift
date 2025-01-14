//
//  File.swift
//
//
//  Created by Yusuf Tör on 18/01/2023.
// swiftlint:disable all

import StoreKit
import XCTest

@testable import SuperwallKit

final class TemplateLogicTests: XCTestCase {
  class MockVariablesFactory: VariablesFactory {
    let userAttributes: [String: Any]
    let deviceDict: [String: Any]?

    init(
      userAttributes: [String: Any],
      deviceDict: [String: Any]?
    ) {
      self.userAttributes = userAttributes
      self.deviceDict = deviceDict
    }

    func makeJsonVariables(
      products productVariables: [ProductVariable]?,
      computedPropertyRequests: [ComputedPropertyRequest],
      placement: PlacementData?
    ) async -> JSON {
      return Variables(
        products: productVariables,
        params: placement?.parameters,
        userAttributes: userAttributes,
        templateDeviceDictionary: deviceDict
      ).templated()
    }
  }

  func test_getBase64EncodedTemplates_oneProduct_noFreeTrial_userAttributes() async {
    // MARK: Given
    let dependencyContainer = DependencyContainer()
    let products = [
      Product(
        name: "primary",
        type: .appStore(.init(id: "123")),
        entitlements: [.stub()]
      )
    ]
    let productVariables = [ProductVariable(name: "primary", attributes: ["period": "month"])]
    let userAttributes = [
      "name": "Yusuf"
    ]
    let deviceDict = [
      "isMac": false
    ]

    let factory = MockVariablesFactory(
      userAttributes: userAttributes,
      deviceDict: deviceDict
    )

    // MARK: When

    // Encode
    let encodedTemplates = await TemplateLogic.getBase64EncodedTemplates(
      from: .stub()
        .setting(\.products, to: products)
        .setting(\.productVariables, to: productVariables),
      placement: .stub()
        .setting(\.parameters, to: ["myparam": "test"]),
      receiptManager: dependencyContainer.receiptManager,
      factory: factory
    )

    // decode
    let encodedData = Data(base64Encoded: encodedTemplates)!
    let json = try! JSON(data: encodedData)
    let jsonArray = json.array!

    // MARK: Then
    XCTAssertEqual(jsonArray[0]["event_name"], "products")
    XCTAssertEqual(jsonArray[0]["products"][0]["productId"].stringValue, products.first!.id)
    XCTAssertEqual(jsonArray[0]["products"][0]["product"].stringValue, products.first!.name)
    XCTAssertEqual(jsonArray[0]["products"].count, 1)

    XCTAssertEqual(jsonArray[1]["event_name"], "template_variables")
    print(jsonArray[1]["variables"])
    XCTAssertFalse(jsonArray[1]["variables"]["device"]["isMac"].boolValue)
    XCTAssertEqual(jsonArray[1]["variables"]["params"]["myparam"], "test")
    XCTAssertEqual(jsonArray[1]["variables"]["user"]["name"], "Yusuf")
    XCTAssertEqual(jsonArray[1]["variables"]["products"][0]["primary"]["period"], "month")
    XCTAssertEqual(jsonArray[1]["variables"]["products"][0]["primary"]["isSubscribed"], false)
    XCTAssertEqual(jsonArray[1]["variables"]["products"][0]["primary"].count, 2)
    XCTAssertEqual(jsonArray[1]["variables"]["products"].count, 1)

    XCTAssertEqual(jsonArray[2]["event_name"], "template_substitutions_prefix")
    XCTAssertEqual(jsonArray[2].count, 1)
  }

  func test_getBase64EncodedTemplates_oneProduct_freeTrial_userAttributes() async {
    // MARK: Given
    let dependencyContainer = DependencyContainer()
    let productItems = [
      Product(
        name: "primary",
        type: .appStore(.init(id: "123")),
        entitlements: [.stub()]
      )
    ]
    let productVariables = [ProductVariable(name: "primary", attributes: ["period": "month"])]
    let userAttributes = [
      "name": "Yusuf"
    ]
    let deviceDict = [
      "isMac": false
    ]
    let params: JSON = ["myparam": "test"]

    let factory = MockVariablesFactory(
      userAttributes: userAttributes,
      deviceDict: deviceDict
    )

    // MARK: When

    // Encode
    let encodedTemplates = await TemplateLogic.getBase64EncodedTemplates(
      from: .stub()
        .setting(\.products, to: productItems)
        .setting(\.productVariables, to: productVariables)
        .setting(\.isFreeTrialAvailable, to: true),
      placement: .stub()
        .setting(\.parameters, to: params),
      receiptManager: dependencyContainer.receiptManager,
      factory: factory
    )

    // decode
    let encodedData = Data(base64Encoded: encodedTemplates)!
    let json = try! JSON(data: encodedData)
    let jsonArray = json.array!

    // MARK: Then
    XCTAssertEqual(jsonArray[0]["event_name"], "products")
    XCTAssertEqual(jsonArray[0]["products"][0]["productId"].stringValue, productItems.first!.id)
    XCTAssertEqual(
      jsonArray[0]["products"][0]["product"].stringValue, productItems.first!.name!.description)
    XCTAssertEqual(jsonArray[0]["products"].count, 1)

    XCTAssertEqual(jsonArray[1]["event_name"], "template_variables")
    XCTAssertFalse(jsonArray[1]["variables"]["device"]["isMac"].boolValue)
    XCTAssertEqual(jsonArray[1]["variables"]["params"]["myparam"], "test")
    XCTAssertEqual(jsonArray[1]["variables"]["user"]["name"], "Yusuf")
    XCTAssertEqual(jsonArray[1]["variables"]["products"][0]["primary"]["period"], "month")
    XCTAssertEqual(jsonArray[1]["variables"]["products"][0]["primary"].count, 2)
    XCTAssertEqual(jsonArray[1]["variables"]["products"].count, 1)

    XCTAssertEqual(jsonArray[2]["event_name"], "template_substitutions_prefix")
    XCTAssertEqual(jsonArray[2]["prefix"], "freeTrial")
  }

  func test_getBase64EncodedTemplates_threeProducts_freeTrial_userAttributes() async {
    // MARK: Given
    let dependencyContainer = DependencyContainer()
    let products = [
      Product(
        name: "primary",
        type: .appStore(.init(id: "123")),
        entitlements: [.stub()]
      ),
      Product(
        name: "secondary",
        type: .appStore(.init(id: "456")),
        entitlements: [.stub()]
      ),
      Product(
        name: "tertiary",
        type: .appStore(.init(id: "789")),
        entitlements: [.stub()]
      ),
    ]
    let productVariables = [
      ProductVariable(name: "primary", attributes: ["period": "month"]),
      ProductVariable(name: "secondary", attributes: ["period": "month"]),
      ProductVariable(name: "tertiary", attributes: ["period": "month"]),
    ]
    let userAttributes = [
      "name": "Yusuf"
    ]
    let deviceDict = [
      "isMac": false
    ]
    let params: JSON = ["myparam": "test"]

    let factory = MockVariablesFactory(
      userAttributes: userAttributes,
      deviceDict: deviceDict
    )

    // MARK: When

    // Encode
    let encodedTemplates = await TemplateLogic.getBase64EncodedTemplates(
      from: .stub()
        .setting(\.products, to: products)
        .setting(\.productVariables, to: productVariables)
        .setting(\.isFreeTrialAvailable, to: true),
      placement: .stub()
        .setting(\.parameters, to: params),
      receiptManager: dependencyContainer.receiptManager,
      factory: factory
    )

    // decode
    let encodedData = Data(base64Encoded: encodedTemplates)!
    let json = try! JSON(data: encodedData)
    let jsonArray = json.array!

    // MARK: Then
    XCTAssertEqual(jsonArray[0]["event_name"], "products")
    XCTAssertEqual(jsonArray[0]["products"][0]["productId"].stringValue, products.first!.id)
    XCTAssertEqual(jsonArray[0]["products"][0]["product"].stringValue, products.first!.name)
    XCTAssertEqual(jsonArray[0]["products"][1]["productId"].stringValue, products[1].id)
    XCTAssertEqual(jsonArray[0]["products"][1]["product"].stringValue, products[1].name)
    XCTAssertEqual(jsonArray[0]["products"][2]["productId"].stringValue, products[2].id)
    XCTAssertEqual(jsonArray[0]["products"][2]["product"].stringValue, products[2].name)
    XCTAssertEqual(jsonArray[0]["products"].count, 3)

    XCTAssertEqual(jsonArray[1]["event_name"], "template_variables")
    XCTAssertFalse(jsonArray[1]["variables"]["device"]["isMac"].boolValue)
    XCTAssertEqual(jsonArray[1]["variables"]["params"]["myparam"], "test")
    XCTAssertEqual(jsonArray[1]["variables"]["user"]["name"], "Yusuf")
    XCTAssertEqual(jsonArray[1]["variables"]["products"][0]["primary"]["period"], "month")
    XCTAssertEqual(jsonArray[1]["variables"]["products"][0]["primary"].count, 2)
    XCTAssertEqual(jsonArray[1]["variables"]["products"][1]["secondary"]["period"], "month")
    XCTAssertEqual(jsonArray[1]["variables"]["products"][1]["secondary"].count, 2)
    XCTAssertEqual(jsonArray[1]["variables"]["products"][2]["tertiary"]["period"], "month")
    XCTAssertEqual(jsonArray[1]["variables"]["products"][2]["tertiary"].count, 2)
    XCTAssertEqual(jsonArray[1]["variables"]["products"].count, 3)

    XCTAssertEqual(jsonArray[2]["event_name"], "template_substitutions_prefix")
    XCTAssertEqual(jsonArray[2]["prefix"], "freeTrial")
  }

  func test_getBase64EncodedTemplates_threeProducts_freeTrial_userAttributes_variablesTemplate()
    async
  {
    // MARK: Given
    let dependencyContainer = DependencyContainer()
    let products = [
      Product(
        name: "primary",
        type: .appStore(.init(id: "123")),
        entitlements: [.stub()]
      ),
      Product(
        name: "secondary",
        type: .appStore(.init(id: "456")),
        entitlements: [.stub()]
      ),
      Product(
        name: "tertiary",
        type: .appStore(.init(id: "789")),
        entitlements: [.stub()]
      ),
    ]
    let productVariables = [
      ProductVariable(name: "primary", attributes: ["period": "month"]),
      ProductVariable(name: "secondary", attributes: ["period": "month"]),
      ProductVariable(name: "tertiary", attributes: ["period": "month"]),
    ]
    let userAttributes = [
      "name": "Yusuf"
    ]
    let deviceDict = [
      "isMac": false
    ]
    let params: JSON = ["myparam": "test"]

    let factory = MockVariablesFactory(
      userAttributes: userAttributes,
      deviceDict: deviceDict
    )

    // MARK: When

    // Encode
    let encodedTemplates = await TemplateLogic.getBase64EncodedTemplates(
      from: .stub()
        .setting(\.products, to: products)
        .setting(\.productVariables, to: productVariables)
        .setting(\.isFreeTrialAvailable, to: true),
      placement: .stub()
        .setting(\.parameters, to: params),
      receiptManager: dependencyContainer.receiptManager,
      factory: factory
    )

    // decode
    let encodedData = Data(base64Encoded: encodedTemplates)!
    let json = try! JSON(data: encodedData)
    let jsonArray = json.array!

    // MARK: Then
    XCTAssertEqual(jsonArray[0]["event_name"], "products")
    XCTAssertEqual(jsonArray[0]["products"][0]["productId"].stringValue, products.first!.id)
    XCTAssertEqual(jsonArray[0]["products"][0]["product"].stringValue, products.first!.name)
    XCTAssertEqual(jsonArray[0]["products"][1]["productId"].stringValue, products[1].id)
    XCTAssertEqual(jsonArray[0]["products"][1]["product"].stringValue, products[1].name)
    XCTAssertEqual(jsonArray[0]["products"][2]["productId"].stringValue, products[2].id)
    XCTAssertEqual(jsonArray[0]["products"][2]["product"].stringValue, products[2].name)
    XCTAssertEqual(jsonArray[0]["products"].count, 3)

    XCTAssertEqual(jsonArray[1]["event_name"], "template_variables")
    XCTAssertFalse(jsonArray[1]["variables"]["device"]["isMac"].boolValue)
    XCTAssertEqual(jsonArray[1]["variables"]["params"]["myparam"], "test")
    XCTAssertEqual(jsonArray[1]["variables"]["user"]["name"], "Yusuf")
    XCTAssertEqual(jsonArray[1]["variables"]["products"][0]["primary"]["period"], "month")
    XCTAssertEqual(jsonArray[1]["variables"]["products"][0]["primary"].count, 2)
    XCTAssertEqual(jsonArray[1]["variables"]["products"][1]["secondary"]["period"], "month")
    XCTAssertEqual(jsonArray[1]["variables"]["products"][1]["secondary"].count, 2)
    XCTAssertEqual(jsonArray[1]["variables"]["products"][2]["tertiary"]["period"], "month")
    XCTAssertEqual(jsonArray[1]["variables"]["products"][2]["tertiary"].count, 2)

    XCTAssertEqual(jsonArray[2]["event_name"], "template_substitutions_prefix")
    XCTAssertEqual(jsonArray[2]["prefix"], "freeTrial")
  }
}
