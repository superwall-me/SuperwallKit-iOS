//
//  File.swift
//  
//
//  Created by Yusuf Tör on 06/09/2024.
//
// swiftlint:disable all

import Foundation
import XCTest
@testable import SuperwallKit

@available(iOS 14.0, *)
final class ExpressionLogicTests: XCTestCase {
  let dependencyContainer = DependencyContainer()

  func test_tryToMatchOccurrence_noMatch() async {
    let storage = StorageMock()
    let expressionLogic = ExpressionLogic(storage: storage)

    let rule = TriggerRule.stub()
      .setting(\.occurrence, to: .stub())
    let outcome = await expressionLogic.tryToMatchOccurrence(
      from: rule,
      expressionMatched: false
    )
    XCTAssertEqual(outcome, .noMatch(source: .expression, experimentId: rule.experiment.id))
  }

  func test_tryToMatchOccurrence_noOccurrenceRule() async {
    let storage = StorageMock()
    let expressionLogic = ExpressionLogic(storage: storage)

    let rule = TriggerRule.stub()
      .setting(\.occurrence, to: nil)
    let outcome = await expressionLogic.tryToMatchOccurrence(
      from: rule,
      expressionMatched: true
    )
    XCTAssertEqual(outcome, .match(audience: rule))
  }

  func test_tryToMatchOccurrence_shouldntFire_maxCountGTCount() async {
    let coreDataManagerMock = CoreDataManagerFakeDataMock(internalOccurrenceCount: 1)
    let storage = StorageMock(coreDataManager: coreDataManagerMock)
    let expressionLogic = ExpressionLogic(storage: storage)

    let rule = TriggerRule.stub()
      .setting(\.occurrence, to: .stub().setting(\.maxCount, to: 1))
    let outcome = await expressionLogic.tryToMatchOccurrence(
      from: rule,
      expressionMatched: true
    )

    XCTAssertEqual(outcome, .noMatch(source: .occurrence, experimentId: rule.experiment.id))
  }

  func test_tryToMatchOccurrence_shouldFire_maxCountEqualToCount() async {
    let coreDataManagerMock = CoreDataManagerFakeDataMock(internalOccurrenceCount: 0)
    let storage = StorageMock(coreDataManager: coreDataManagerMock)
    let expressionLogic = ExpressionLogic(storage: storage)

    let occurrence: TriggerAudienceOccurrence = .stub().setting(\.maxCount, to: 1)
    let rule = TriggerRule.stub()
      .setting(\.occurrence, to: occurrence)
    let outcome = await expressionLogic.tryToMatchOccurrence(
      from: rule,
      expressionMatched: true
    )

    XCTAssertEqual(outcome, .match(audience: rule, unsavedOccurrence: occurrence))
  }

  func test_tryToMatchOccurrence_shouldFire_maxCountLtCount() async {
    let coreDataManagerMock = CoreDataManagerFakeDataMock(internalOccurrenceCount: 1)
    let storage = StorageMock(coreDataManager: coreDataManagerMock)
    let expressionLogic = ExpressionLogic(storage: storage)

    let occurrence: TriggerAudienceOccurrence = .stub().setting(\.maxCount, to: 4)
    let rule = TriggerRule.stub()
      .setting(\.occurrence, to: occurrence)
    let outcome = await expressionLogic.tryToMatchOccurrence(
      from: rule,
      expressionMatched: true
    )

    XCTAssertEqual(outcome, .match(audience: rule, unsavedOccurrence: occurrence))
  }
}
