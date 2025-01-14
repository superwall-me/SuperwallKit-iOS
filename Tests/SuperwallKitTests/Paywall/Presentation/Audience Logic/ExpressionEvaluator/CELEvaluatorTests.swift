//
//  CELEvaluatorTests.swift
//  SuperwallKit
//
//  Created by Yusuf Tör on 14/10/2024.
//
// swiftlint:disable all

import Foundation
import XCTest
@testable import SuperwallKit

final class CELEvaluatorTests: XCTestCase {
  func testEvaluateExpression_expressionMatchesAll() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = CELEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )

    let rule: TriggerRule = .stub()
      .setting(\.expression, to: nil)
    let result = await evaluator.evaluateExpression(
      fromAudienceFilter: rule,
      placementData: .stub()
    )

    XCTAssertEqual(result, .match(audience: rule))
  }

  func testEvaluateExpression_expressionTrue() async  {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = CELEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    dependencyContainer.identityManager.mergeUserAttributes(["a": "b"])
    let rule: TriggerRule = .stub()
      .setting(\.expression, to: "user.a == \"b\"")
    let result = await evaluator.evaluateExpression(
      fromAudienceFilter: rule,
      placementData: PlacementData(name: "ss", parameters: [:], createdAt: Date())
    )

    XCTAssertEqual(result, .match(audience: rule))
  }

  func testEvaluateExpression_expression_withOccurrence() async  {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = CELEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    dependencyContainer.identityManager.mergeUserAttributes(["a": "b"])
    let occurrence = TriggerAudienceOccurrence(key: "a", maxCount: 1, interval: .infinity)
    let rule: TriggerRule = .stub()
      .setting(\.expression, to: "user.a == \"b\"")
      .setting(\.occurrence, to: occurrence)
    let result = await evaluator.evaluateExpression(
      fromAudienceFilter: rule,
      placementData: PlacementData(name: "ss", parameters: [:], createdAt: Date())
    )

    XCTAssertEqual(result, .match(audience: rule, unsavedOccurrence: occurrence))
  }

  func testEvaluateExpression_expressionParams() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = CELEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    dependencyContainer.identityManager.mergeUserAttributes([:])
    let rule: TriggerRule = .stub()
      .setting(\.expression, to: "params.a == \"b\"")
    let result = await evaluator.evaluateExpression(
      fromAudienceFilter: rule,
      placementData: PlacementData(name: "ss", parameters: ["a": "b"], createdAt: Date())
    )
    XCTAssertEqual(result, .match(audience: rule))
  }

  func testEvaluateExpression_expressionDeviceTrue() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = CELEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    dependencyContainer.identityManager.mergeUserAttributes([:])
    let rule: TriggerRule = .stub()
      .setting(\.expression, to: "device.platform == \"iOS\"")
    let result = await evaluator.evaluateExpression(
      fromAudienceFilter: rule,
      placementData: PlacementData(name: "ss", parameters: ["a": "b"], createdAt: Date())
    )
    XCTAssertEqual(result, .match(audience: rule))
  }

  func testEvaluateExpression_expressionDeviceFalse() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = CELEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    dependencyContainer.identityManager.mergeUserAttributes([:])
    let rule: TriggerRule = .stub()
      .setting(\.expression, to: "device.platform == \"Android\"")
    let result = await evaluator.evaluateExpression(
        fromAudienceFilter: rule,
      placementData: PlacementData(name: "ss", parameters: ["a": "b"], createdAt: Date())
    )
    XCTAssertEqual(result, .noMatch(source: .expression, experimentId: rule.experiment.id))
  }

  func testEvaluateExpression_expressionFalse() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = CELEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    dependencyContainer.identityManager.mergeUserAttributes([:])
    let rule: TriggerRule = .stub()
      .setting(\.expression, to: "a == \"b\"")
    let result = await evaluator.evaluateExpression(
      fromAudienceFilter: rule,
      placementData: .stub()
    )
    XCTAssertEqual(result, .noMatch(source: .expression, experimentId: rule.experiment.id))
  }

  func testEvaluateExpression_noEntitlements_match() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    dependencyContainer.entitlementsInfo.status = .inactive
    let evaluator = CELEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    print("device entitlements", dependencyContainer.entitlementsInfo.active)
    let rule: TriggerRule = .stub()
      .setting(\.expression, to: "size(device.activeEntitlements) == 0")
    let result = await evaluator.evaluateExpression(
      fromAudienceFilter: rule,
      placementData: .stub()
    )
    XCTAssertEqual(result, .match(audience: rule))
  }

  func testEvaluateExpression_noEntitlements_noMatch() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    dependencyContainer.entitlementsInfo.status = .active([.stub()])
    let evaluator = CELEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    let rule: TriggerRule = .stub()
      .setting(\.expression, to: "size(device.activeEntitlements) == 0")
    let result = await evaluator.evaluateExpression(
      fromAudienceFilter: rule,
      placementData: .stub()
    )
    XCTAssertEqual(result, .noMatch(source: .expression, experimentId: rule.experiment.id))
  }

  func testEvaluateExpression_containsSpecificEntitlement() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    dependencyContainer.entitlementsInfo.status = .active([.init(id: "bronze")])
    let evaluator = CELEvaluator(
      storage: dependencyContainer.storage,
      factory: dependencyContainer
    )
    let rule: TriggerRule = .stub()
      .setting(\.expression, to: "[\"bronze\"].all(identifier, device.activeEntitlements.contains(identifier))")
    let result = await evaluator.evaluateExpression(
      fromAudienceFilter: rule,
      placementData: .stub()
    )
    XCTAssertEqual(result, .match(audience: rule))
  }
}
