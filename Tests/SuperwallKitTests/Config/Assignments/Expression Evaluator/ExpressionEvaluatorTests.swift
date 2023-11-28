//
//  File.swift
//
//
//  Created by Brian Anglin on 2/21/22.
//
// swiftlint:disable all

import Foundation
import XCTest
@testable import SuperwallKit

@available(iOS 14.0, *)
final class ExpressionEvaluatorTests: XCTestCase {
  // MARK: - tryToMatchOccurrence
  func test_tryToMatchOccurrence_noMatch() async {
    let dependencyContainer = DependencyContainer()
    let storage = StorageMock()
    let evaluator = ExpressionEvaluator(factory: dependencyContainer)
    let rule = TriggerRule.stub()
      .setting(\.occurrence, to: .stub())
    let outcome = await evaluator.tryToMatchOccurrence(
      from: rule,
      expressionMatched: false
    )
    XCTAssertEqual(outcome, .noMatch(source: .expression, experimentId: rule.experiment.id))
  }

  func test_tryToMatchOccurrence_noOccurrenceRule() async {
    let dependencyContainer = DependencyContainer()
    let storage = StorageMock()
    let evaluator = ExpressionEvaluator(factory: dependencyContainer)
    let rule = TriggerRule.stub()
      .setting(\.occurrence, to: nil)
    let outcome = await evaluator.tryToMatchOccurrence(
      from: rule,
      expressionMatched: true
    )
    XCTAssertEqual(outcome, .match(rule: rule))
  }

  func test_tryToMatchOccurrence_shouldntFire_maxCountGTCount() async {
    let dependencyContainer = DependencyContainer()
    let coreDataManagerMock = CoreDataManagerFakeDataMock(internalOccurrenceCount: 1)
    let storage = StorageMock(coreDataManager: coreDataManagerMock)
    let evaluator = ExpressionEvaluator(factory: dependencyContainer)

    let rule = TriggerRule.stub()
      .setting(\.occurrence, to: .stub().setting(\.maxCount, to: 1))
    let outcome = await evaluator.tryToMatchOccurrence(
      from: rule,
      expressionMatched: true
    )

    XCTAssertEqual(outcome, .noMatch(source: .occurrence, experimentId: rule.experiment.id))
  }

  func test_tryToMatchOccurrence_shouldFire_maxCountEqualToCount() async {
    let coreDataManagerMock = CoreDataManagerFakeDataMock(internalOccurrenceCount: 0)
    let storage = StorageMock(coreDataManager: coreDataManagerMock)

    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage = storage

    let evaluator = ExpressionEvaluator(factory: dependencyContainer)

    let occurrence: TriggerRuleOccurrence = .stub().setting(\.maxCount, to: 1)
    let rule = TriggerRule.stub()
      .setting(\.occurrence, to: occurrence)
    let outcome = await evaluator.tryToMatchOccurrence(
      from: rule,
      expressionMatched: true
    )

    XCTAssertEqual(outcome, .match(rule: rule, unsavedOccurrence: occurrence))
  }

  func test_tryToMatchOccurrence_shouldFire_maxCountLtCount() async {
    let dependencyContainer = DependencyContainer()
    let coreDataManagerMock = CoreDataManagerFakeDataMock(internalOccurrenceCount: 1)
    let storage = StorageMock(coreDataManager: coreDataManagerMock)
    let evaluator = ExpressionEvaluator(factory: dependencyContainer)

    let occurrence: TriggerRuleOccurrence = .stub().setting(\.maxCount, to: 4)
    let rule = TriggerRule.stub()
      .setting(\.occurrence, to: occurrence)
    let outcome = await evaluator.tryToMatchOccurrence(
      from: rule,
      expressionMatched: true
    )

    XCTAssertEqual(outcome, .match(rule: rule, unsavedOccurrence: occurrence))
  }

  // MARK: - evaluateExpression
  func testExpressionMatchesAll() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = ExpressionEvaluator(factory: dependencyContainer)

    let rule: TriggerRule = .stub()
      .setting(\.expression, to: nil)
      .setting(\.expressionJs, to: nil)
    let result = await evaluator.evaluateExpression(
      fromRule: rule,
      eventData: .stub()
    )

    XCTAssertEqual(result, .match(rule: rule))
  }

  // MARK: - Expression

  func testExpressionEvaluator_expressionTrue() async  {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = ExpressionEvaluator(factory: dependencyContainer)
    dependencyContainer.identityManager.mergeUserAttributes(["a": "b"])
    let rule: TriggerRule = .stub()
      .setting(\.expression, to: "user.a == \"b\"")
    let result = await evaluator.evaluateExpression(
      fromRule: rule,
      eventData: EventData(name: "ss", parameters: [:], createdAt: Date())
    )

    XCTAssertEqual(result, .match(rule: rule))
  }

  func testExpressionEvaluator_expression_withOccurrence() async  {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = ExpressionEvaluator(factory: dependencyContainer)
    dependencyContainer.identityManager.mergeUserAttributes(["a": "b"])
    let occurrence = TriggerRuleOccurrence(key: "a", maxCount: 1, interval: .infinity)
    let rule: TriggerRule = .stub()
      .setting(\.expression, to: "user.a == \"b\"")
      .setting(\.occurrence, to: occurrence)
    let result = await evaluator.evaluateExpression(
      fromRule: rule,
      eventData: EventData(name: "ss", parameters: [:], createdAt: Date())
    )

    XCTAssertEqual(result, .match(rule: rule, unsavedOccurrence: occurrence))
  }

  func testExpressionEvaluator_expressionParams() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = ExpressionEvaluator(factory: dependencyContainer)
    dependencyContainer.identityManager.mergeUserAttributes([:])
    let rule: TriggerRule = .stub()
      .setting(\.expression, to: "params.a == \"b\"")
    let result = await evaluator.evaluateExpression(
      fromRule: rule,
      eventData: EventData(name: "ss", parameters: ["a": "b"], createdAt: Date())
    )
    XCTAssertEqual(result, .match(rule: rule))
  }

  func testExpressionEvaluator_expressionDeviceTrue() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = ExpressionEvaluator(factory: dependencyContainer)
    dependencyContainer.identityManager.mergeUserAttributes([:])
    let rule: TriggerRule = .stub()
      .setting(\.expression, to: "device.platform == \"iOS\"")
    let result = await evaluator.evaluateExpression(
      fromRule: rule,
      eventData: EventData(name: "ss", parameters: ["a": "b"], createdAt: Date())
    )
    XCTAssertEqual(result, .match(rule: rule))
  }

  func testExpressionEvaluator_expressionDeviceFalse() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = ExpressionEvaluator(factory: dependencyContainer)
    dependencyContainer.identityManager.mergeUserAttributes([:])
    let rule: TriggerRule = .stub()
      .setting(\.expression, to: "device.platform == \"Android\"")
    let result = await evaluator.evaluateExpression(
      fromRule: rule,
      eventData: EventData(name: "ss", parameters: ["a": "b"], createdAt: Date())
    )
    XCTAssertEqual(result, .noMatch(source: .expression, experimentId: rule.experiment.id))
  }

  func testExpressionEvaluator_expressionFalse() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.storage.reset()
    let evaluator = ExpressionEvaluator(factory: dependencyContainer)
    dependencyContainer.identityManager.mergeUserAttributes([:])
    let rule: TriggerRule = .stub()
      .setting(\.expression, to: "a == \"b\"")
    let result = await evaluator.evaluateExpression(
      fromRule: rule,
      eventData: .stub()
    )
    XCTAssertEqual(result, .noMatch(source: .expression, experimentId: rule.experiment.id))
  }
  /*
   func testExpressionEvaluator_events() {
   let triggeredEvents: [String: [EventData]] = [
   "a": [.stub()]
   ]
   let storage = StorageMock(internalTriggeredEvents: triggeredEvents)
   let result = ExpressionEvaluator.evaluateExpression(
   fromRule: .stub()
   .setting(\.expression, to: "events[\"a\"][\"$count_24h\"] == 1"),
   eventData: .stub(),
   storage: storage
   )
   XCTAssertTrue(result)
   }*/

  // MARK: - ExpressionJS

  func testExpressionEvaluator_expressionJSTrue() async {
    let dependencyContainer = DependencyContainer()
    let evaluator = ExpressionEvaluator(factory: dependencyContainer)
    let rule: TriggerRule = .stub()
      .setting(\.expressionJs, to: "function superwallEvaluator(){ return true }; superwallEvaluator")
    let result = await evaluator.evaluateExpression(
      fromRule: rule,
      eventData: .stub()
    )
    XCTAssertEqual(result, .match(rule: rule))
  }

  func testExpressionEvaluator_expressionJSValues_true() async {
    let dependencyContainer = DependencyContainer()
    let evaluator = ExpressionEvaluator(factory: dependencyContainer)
    let rule: TriggerRule = .stub()
      .setting(\.expressionJs, to: "function superwallEvaluator(values) { return values.params.a ==\"b\" }; superwallEvaluator")
    let result = await evaluator.evaluateExpression(
      fromRule: rule,
      eventData: EventData(name: "ss", parameters: ["a": "b"], createdAt: Date())
    )
    XCTAssertEqual(result, .match(rule: rule))
  }

  func testExpressionEvaluator_expressionJSValues_false() async {
    let dependencyContainer = DependencyContainer()
    let evaluator = ExpressionEvaluator(factory: dependencyContainer)
    let rule: TriggerRule = .stub()
      .setting(\.expressionJs, to: "function superwallEvaluator(values) { return values.params.a ==\"b\" }; superwallEvaluator")
    let result = await evaluator.evaluateExpression(
      fromRule: rule,
      eventData: EventData(name: "ss", parameters: ["a": "b"], createdAt: Date())
    )
    XCTAssertEqual(result, .match(rule: rule))
  }

  func testExpressionEvaluator_expressionJSNumbers() async {
    let dependencyContainer = DependencyContainer()
    let evaluator = ExpressionEvaluator(factory: dependencyContainer)
    let rule: TriggerRule = .stub()
      .setting(\.expressionJs, to: "function superwallEvaluator(values) { return 1 == 1 }; superwallEvaluator")
    let result = await evaluator.evaluateExpression(
      fromRule: rule,
      eventData: .stub()
    )
    XCTAssertEqual(result, .match(rule: rule))
  }
  /*
   func testExpressionEvaluator_expressionJSValues_events() {
   let triggeredEvents: [String: [EventData]] = [
   "a": [.stub()]
   ]
   let storage = StorageMock(internalTriggeredEvents: triggeredEvents)
   let result = ExpressionEvaluator.evaluateExpression(
   fromRule: .stub()
   .setting(\.expressionJs, to: "function superwallEvaluator(values) { return values.events.a.$count_24h == 1 }; superwallEvaluator"),
   eventData: .stub(),
   storage: storage
   )
   XCTAssertTrue(result)
   }*/

  func testExpressionEvaluator_expressionJSEmpty() async {
    let dependencyContainer = DependencyContainer()
    let evaluator = ExpressionEvaluator(factory: dependencyContainer)
    let rule: TriggerRule = .stub()
      .setting(\.expressionJs, to: "")
    let result = await evaluator.evaluateExpression(
      fromRule: rule,
      eventData: .stub()
    )
    XCTAssertEqual(result, .noMatch(source: .expression, experimentId: rule.experiment.id))
  }
}
