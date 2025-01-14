//
//  TriggerLogicTests.swift
//
//
//  Created by Yusuf Tör on 09/03/2022.
//
// swiftlint:disable all

import XCTest

@testable import SuperwallKit

@available(iOS 14, *)
class AssignmentLogicTests: XCTestCase {
  func testGetOutcome_holdout() async throws {
    // MARK: Given
    let eventName = "opened_application"
    let variantId = "7"
    let variantOption = VariantOption.stub()
      .setting(\.type, to: .holdout)
      .setting(\.id, to: variantId)
    let rawExperiment = RawExperiment.stub()
      .setting(
        \.variants, to: [variantOption]
      )
    let triggerRule = TriggerRule(
      experiment: rawExperiment,
      expression: nil,
      computedPropertyRequests: [],
      preload: .init(behavior: .always)
    )
    let trigger = Trigger(
      placementName: eventName,
      audiences: [triggerRule]
    )
    let eventData = PlacementData(
      name: eventName,
      parameters: [:],
      createdAt: Date()
    )
    let triggers = [eventName: trigger]

    let dependencyContainer = DependencyContainer()
    let variant = variantOption.toExperimentVariant()
    dependencyContainer.configManager.unconfirmedAssignments = [
      rawExperiment.id: variant
    ]
    let storage = StorageMock()

    // MARK: When
    let assignmentLogic = AudienceLogic(
      configManager: dependencyContainer.configManager,
      storage: storage,
      factory: dependencyContainer
    )
    let outcome = await assignmentLogic.evaluateAudienceFilters(
      forPlacement: eventData,
      triggers: triggers
    )

    // MARK: Then
    guard case let .holdout(returnedExperiment) = outcome.triggerResult else {
      return XCTFail("Incorrect outcome. Expected a holdout")
    }
    XCTAssertEqual(returnedExperiment.id, rawExperiment.id)
    XCTAssertEqual(returnedExperiment.groupId, rawExperiment.groupId)
    XCTAssertEqual(returnedExperiment.id, rawExperiment.id)

    let expectedConfirmableAssignments = ConfirmableAssignment(
      experimentId: triggerRule.experiment.id,
      variant: variant
    )
    let confirmableAssignments = outcome.confirmableAssignment!
    XCTAssertEqual(confirmableAssignments, expectedConfirmableAssignments)
  }

  func testGetOutcome_presentIdentifier_unconfirmedAssignmentsOnly() async throws {
    // MARK: Given
    let eventName = "opened_application"
    let variantId = "7"
    let paywallId = "omnis-id-ab"
    let variantOption = VariantOption.stub()
      .setting(\.type, to: .treatment)
      .setting(\.paywallId, to: paywallId)
      .setting(\.id, to: variantId)
    let rawExperiment = RawExperiment.stub()
      .setting(
        \.variants, to: [variantOption]
      )
    let triggerRule = TriggerRule(
      experiment: rawExperiment,
      expression: nil,
      computedPropertyRequests: [],
      preload: .init(behavior: .always)
    )
    let trigger = Trigger(
      placementName: eventName,
      audiences: [triggerRule]
    )
    let eventData = PlacementData(
      name: eventName,
      parameters: [:],
      createdAt: Date()
    )
    let triggers = [eventName: trigger]

    let dependencyContainer = DependencyContainer()
    let variant = variantOption.toExperimentVariant()
    dependencyContainer.configManager.unconfirmedAssignments = [
      rawExperiment.id: variant
    ]
    let storage = StorageMock()
    let assignmentLogic = AudienceLogic(
      configManager: dependencyContainer.configManager,
      storage: storage,
      factory: dependencyContainer
    )

    // MARK: When
    let outcome = await assignmentLogic.evaluateAudienceFilters(
      forPlacement: eventData,
      triggers: triggers
    )

    // MARK: Then
    guard case let .paywall(experiment: returnedExperiment) = outcome.triggerResult else {
      return XCTFail("Incorrect outcome. Expected a holdout")
    }
    XCTAssertEqual(returnedExperiment.id, rawExperiment.id)
    XCTAssertEqual(returnedExperiment.groupId, rawExperiment.groupId)
    XCTAssertEqual(returnedExperiment.variant.paywallId, paywallId)
    XCTAssertEqual(returnedExperiment.id, rawExperiment.id)

    let expectedConfirmableAssignments = ConfirmableAssignment(
      experimentId: triggerRule.experiment.id,
      variant: variant
    )
    let confirmableAssignments = outcome.confirmableAssignment!
    XCTAssertEqual(confirmableAssignments, expectedConfirmableAssignments)
  }

  func testGetOutcome_presentIdentifier_confirmedAssignmentsOnly() async throws {
    // MARK: Given
    let eventName = "opened_application"
    let variantId = "7"
    let paywallId = "omnis-id-ab"
    let variantOption = VariantOption.stub()
      .setting(\.type, to: .treatment)
      .setting(\.paywallId, to: paywallId)
      .setting(\.id, to: variantId)
    let rawExperiment = RawExperiment.stub()
      .setting(
        \.variants, to: [variantOption]
      )
    let triggerRule = TriggerRule(
      experiment: rawExperiment,
      expression: nil,
      computedPropertyRequests: [],
      preload: .init(behavior: .always)
    )
    let trigger = Trigger(
      placementName: eventName,
      audiences: [triggerRule]
    )
    let eventData = PlacementData(
      name: eventName,
      parameters: [:],
      createdAt: Date()
    )
    let triggers = [eventName: trigger]

    let dependencyContainer = DependencyContainer()
    let variant = variantOption.toExperimentVariant()
    let storage = StorageMock(confirmedAssignments: [rawExperiment.id: variant])
    let assignmentLogic = AudienceLogic(
      configManager: dependencyContainer.configManager,
      storage: storage,
      factory: dependencyContainer
    )

    // MARK: When
    let outcome = await assignmentLogic.evaluateAudienceFilters(
      forPlacement: eventData,
      triggers: triggers
    )

    // MARK: Then
    guard case let .paywall(experiment: returnedExperiment) = outcome.triggerResult else {
      return XCTFail("Incorrect outcome. Expected a holdout")
    }
    XCTAssertEqual(returnedExperiment.id, rawExperiment.id)
    XCTAssertEqual(returnedExperiment.groupId, rawExperiment.groupId)
    XCTAssertEqual(returnedExperiment.variant.paywallId, paywallId)
    XCTAssertEqual(returnedExperiment.id, rawExperiment.id)

    let confirmableAssignments = outcome.confirmableAssignment
    XCTAssertNil(confirmableAssignments)
  }

  func testGetOutcome_presentIdentifier_confirmedAssignmentsAndUnconfirmedAssignmentsRaceCondition()
    async throws
  {
    // MARK: Given
    let eventName = "opened_application"
    let variantId = "7"
    let paywallId = "omnis-id-ab"
    let variantOption = VariantOption.stub()
      .setting(\.type, to: .treatment)
      .setting(\.paywallId, to: paywallId)
      .setting(\.id, to: variantId)
    let rawExperiment = RawExperiment.stub()
      .setting(
        \.variants, to: [variantOption]
      )
    let triggerRule = TriggerRule(
      experiment: rawExperiment,
      expression: nil,
      computedPropertyRequests: [],
      preload: .init(behavior: .always)
    )
    let trigger = Trigger(
      placementName: eventName,
      audiences: [triggerRule]
    )
    let eventData = PlacementData(
      name: eventName,
      parameters: [:],
      createdAt: Date()
    )
    let triggers = [eventName: trigger]

    let dependencyContainer = DependencyContainer()
    let variant = variantOption.toExperimentVariant()
    let variant2 =
      variantOption
      .setting(\.paywallId, to: "123")
      .toExperimentVariant()
    let storage = StorageMock(confirmedAssignments: [rawExperiment.id: variant])
    dependencyContainer.configManager.unconfirmedAssignments = [
      rawExperiment.id: variant2
    ]
    let assignmentLogic = AudienceLogic(
      configManager: dependencyContainer.configManager,
      storage: storage,
      factory: dependencyContainer
    )

    // MARK: When
    let outcome = await assignmentLogic.evaluateAudienceFilters(
      forPlacement: eventData,
      triggers: triggers
    )

    // MARK: Then
    guard case let .paywall(experiment: returnedExperiment) = outcome.triggerResult else {
      return XCTFail("Incorrect outcome. Expected a holdout")
    }
    XCTAssertEqual(returnedExperiment.id, rawExperiment.id)
    XCTAssertEqual(returnedExperiment.groupId, rawExperiment.groupId)
    XCTAssertEqual(returnedExperiment.variant.paywallId, paywallId)
    XCTAssertEqual(returnedExperiment.id, rawExperiment.id)

    let confirmableAssignments = outcome.confirmableAssignment
    XCTAssertNil(confirmableAssignments)
  }

  func testGetOutcome_noRuleMatch() async throws {
    // MARK: Given
    let eventName = "opened_application"
    let variantId = "7"
    let paywallId = "omnis-id-ab"
    let variantOption = VariantOption.stub()
      .setting(\.type, to: .treatment)
      .setting(\.paywallId, to: paywallId)
      .setting(\.id, to: variantId)
    let rawExperiment = RawExperiment.stub()
      .setting(
        \.variants, to: [variantOption]
      )
    let triggerRule = TriggerRule(
      experiment: rawExperiment,
      expression: "params.a == \"c\"",
      computedPropertyRequests: [],
      preload: .init(behavior: .always)
    )
    let trigger = Trigger(
      placementName: eventName,
      audiences: [triggerRule]
    )
    let eventData = PlacementData(
      name: eventName,
      parameters: [:],
      createdAt: Date()
    )
    let triggers = [eventName: trigger]

    let dependencyContainer = DependencyContainer()
    let storage = StorageMock()
    let variant = variantOption.toExperimentVariant()
    dependencyContainer.configManager.unconfirmedAssignments = [
      rawExperiment.id: variant
    ]
    let assignmentLogic = AudienceLogic(
      configManager: dependencyContainer.configManager,
      storage: storage,
      factory: dependencyContainer
    )

    // MARK: When
    let outcome = await assignmentLogic.evaluateAudienceFilters(
      forPlacement: eventData,
      triggers: triggers
    )

    // MARK: Then
    guard case .noAudienceMatch = outcome.triggerResult else {
      return XCTFail("Incorrect outcome. Expected noAudienceMatch")
    }
    let confirmableAssignments = outcome.confirmableAssignment
    XCTAssertNil(confirmableAssignments)
  }

  func testGetOutcome_triggerNotFound() async throws {
    // MARK: Given
    let eventName = "opened_application"
    let variantId = "7"
    let paywallId = "omnis-id-ab"
    let variantOption = VariantOption.stub()
      .setting(\.type, to: .treatment)
      .setting(\.paywallId, to: paywallId)
      .setting(\.id, to: variantId)
    let rawExperiment = RawExperiment.stub()
      .setting(
        \.variants, to: [variantOption]
      )
    let triggerRule = TriggerRule(
      experiment: rawExperiment,
      expression: "params.a == \"c\"",
      computedPropertyRequests: [],
      preload: .init(behavior: .always)
    )
    let trigger = Trigger(
      placementName: eventName,
      audiences: [triggerRule]
    )
    let eventData = PlacementData(
      name: "other event",
      parameters: [:],
      createdAt: Date()
    )
    let triggers = [eventName: trigger]

    let dependencyContainer = DependencyContainer()
    let storage = StorageMock()
    let variant = variantOption.toExperimentVariant()
    dependencyContainer.configManager.unconfirmedAssignments = [
      rawExperiment.id: variant
    ]
    let assignmentLogic = AudienceLogic(
      configManager: dependencyContainer.configManager,
      storage: storage,
      factory: dependencyContainer
    )

    // MARK: When
    let outcome = await assignmentLogic.evaluateAudienceFilters(
      forPlacement: eventData,
      triggers: triggers
    )

    // MARK: Then
    guard case .placementNotFound = outcome.triggerResult else {
      return XCTFail("Incorrect outcome. Expected unknown event")
    }

    let confirmableAssignments = outcome.confirmableAssignment
    XCTAssertNil(confirmableAssignments)
  }
}
