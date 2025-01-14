//
//  File.swift
//  
//
//  Created by Yusuf Tör on 05/12/2022.
//

import XCTest
@testable import SuperwallKit
import Combine

final class ConfirmHoldoutAssignmentOperatorTests: XCTestCase {
  var cancellables: [AnyCancellable] = []

  func test_confirmHoldoutAssignment_notHoldout() async {
    let dependencyContainer = DependencyContainer()

    let configManager = ConfigManagerMock(
      options: SuperwallOptions(),
      storeKitManager: dependencyContainer.storeKitManager,
      storage: dependencyContainer.storage,
      network: dependencyContainer.network,
      paywallManager: dependencyContainer.paywallManager,
      deviceHelper: dependencyContainer.deviceHelper,
      entitlementsInfo: dependencyContainer.entitlementsInfo,
      factory: dependencyContainer
    )

    try? await Task.sleep(nanoseconds: 10_000_000)

    dependencyContainer.configManager = configManager

    let input = AudienceFilterEvaluationOutcome(
      triggerResult: .paywall(.init(id: "", groupId: "", variant: .init(id: "", type: .treatment, paywallId: "")))
    )

    let request = PresentationRequest.stub()
      .setting(\.flags.type, to: .presentation)
    Superwall.shared.confirmHoldoutAssignment(
      request: request,
      from: input,
      dependencyContainer: dependencyContainer
    )
    XCTAssertFalse(configManager.confirmedAssignment)
  }

  func test_confirmHoldoutAssignment_holdout_noConfirmableAssignments() async {
    let dependencyContainer = DependencyContainer()
    let configManager = ConfigManagerMock(
      options: SuperwallOptions(),
      storeKitManager: dependencyContainer.storeKitManager,
      storage: dependencyContainer.storage,
      network: dependencyContainer.network,
      paywallManager: dependencyContainer.paywallManager,
      deviceHelper: dependencyContainer.deviceHelper,
      entitlementsInfo: dependencyContainer.entitlementsInfo,
      factory: dependencyContainer
    )

    try? await Task.sleep(nanoseconds: 10_000_000)

    dependencyContainer.configManager = configManager

    let input = AudienceFilterEvaluationOutcome(
      triggerResult: .holdout(.init(id: "", groupId: "", variant: .init(id: "", type: .treatment, paywallId: "")))
    )
    let request = PresentationRequest.stub()
      .setting(\.flags.type, to: .presentation)
    Superwall.shared.confirmHoldoutAssignment(
      request: request,
      from: input,
      dependencyContainer: dependencyContainer
    )
    XCTAssertFalse(configManager.confirmedAssignment)
  }

  func test_confirmHoldoutAssignment_holdout_hasConfirmableAssignments() async {
    let dependencyContainer = DependencyContainer()
    let configManager = ConfigManagerMock(
      options: SuperwallOptions(),
      storeKitManager: dependencyContainer.storeKitManager,
      storage: dependencyContainer.storage,
      network: dependencyContainer.network,
      paywallManager: dependencyContainer.paywallManager,
      deviceHelper: dependencyContainer.deviceHelper,
      entitlementsInfo: dependencyContainer.entitlementsInfo,
      factory: dependencyContainer
    )
    try? await Task.sleep(nanoseconds: 10_000_000)

    dependencyContainer.configManager = configManager

    let input = AudienceFilterEvaluationOutcome(
      confirmableAssignment: .init(experimentId: "", variant: .init(id: "", type: .treatment, paywallId: "")),
      triggerResult: .holdout(.init(id: "", groupId: "", variant: .init(id: "", type: .treatment, paywallId: "")))
    )

    let request = PresentationRequest.stub()
      .setting(\.flags.type, to: .presentation)
    Superwall.shared.confirmHoldoutAssignment(
      request: request,
      from: input,
      dependencyContainer: dependencyContainer
    )
    XCTAssertTrue(configManager.confirmedAssignment)
  }

  func test_confirmHoldoutAssignment_holdout_getPresentationResult() async {
    let dependencyContainer = DependencyContainer()
    let configManager = ConfigManagerMock(
      options: SuperwallOptions(),
      storeKitManager: dependencyContainer.storeKitManager,
      storage: dependencyContainer.storage,
      network: dependencyContainer.network,
      paywallManager: dependencyContainer.paywallManager,
      deviceHelper: dependencyContainer.deviceHelper,
      entitlementsInfo: dependencyContainer.entitlementsInfo,
      factory: dependencyContainer
    )
    try? await Task.sleep(nanoseconds: 10_000_000)

    dependencyContainer.configManager = configManager

    let input = AudienceFilterEvaluationOutcome(
      confirmableAssignment: .init(experimentId: "", variant: .init(id: "", type: .treatment, paywallId: "")),
      triggerResult: .holdout(.init(id: "", groupId: "", variant: .init(id: "", type: .treatment, paywallId: "")))
    )

    let request = PresentationRequest.stub()
      .setting(\.flags.type, to: .getPresentationResult)
    Superwall.shared.confirmHoldoutAssignment(
      request: request,
      from: input,
      dependencyContainer: dependencyContainer
    )
    XCTAssertTrue(configManager.confirmedAssignment)
  }

  func test_confirmHoldoutAssignment_holdout_handleImplicitTrigger() async {
    let dependencyContainer = DependencyContainer()
    let configManager = ConfigManagerMock(
      options: SuperwallOptions(),
      storeKitManager: dependencyContainer.storeKitManager,
      storage: dependencyContainer.storage,
      network: dependencyContainer.network,
      paywallManager: dependencyContainer.paywallManager,
      deviceHelper: dependencyContainer.deviceHelper,
      entitlementsInfo: dependencyContainer.entitlementsInfo,
      factory: dependencyContainer
    )
    try? await Task.sleep(nanoseconds: 10_000_000)

    dependencyContainer.configManager = configManager

    let input = AudienceFilterEvaluationOutcome(
      confirmableAssignment: .init(experimentId: "", variant: .init(id: "", type: .treatment, paywallId: "")),
      triggerResult: .holdout(.init(id: "", groupId: "", variant: .init(id: "", type: .treatment, paywallId: "")))
    )

    let request = PresentationRequest.stub()
      .setting(\.flags.type, to: .handleImplicitTrigger)
    Superwall.shared.confirmHoldoutAssignment(
      request: request,
      from: input,
      dependencyContainer: dependencyContainer
    )
    XCTAssertTrue(configManager.confirmedAssignment)
  }

  func test_confirmHoldoutAssignment_holdout_paywallDeclineCheck() async {
    let dependencyContainer = DependencyContainer()
    let configManager = ConfigManagerMock(
      options: SuperwallOptions(),
      storeKitManager: dependencyContainer.storeKitManager,
      storage: dependencyContainer.storage,
      network: dependencyContainer.network,
      paywallManager: dependencyContainer.paywallManager,
      deviceHelper: dependencyContainer.deviceHelper,
      entitlementsInfo: dependencyContainer.entitlementsInfo,
      factory: dependencyContainer
    )
    try? await Task.sleep(nanoseconds: 10_000_000)

    dependencyContainer.configManager = configManager

    let input = AudienceFilterEvaluationOutcome(
      confirmableAssignment: .init(experimentId: "", variant: .init(id: "", type: .treatment, paywallId: "")),
      triggerResult: .holdout(.init(id: "", groupId: "", variant: .init(id: "", type: .treatment, paywallId: "")))
    )

    let request = PresentationRequest.stub()
      .setting(\.flags.type, to: .paywallDeclineCheck)
    Superwall.shared.confirmHoldoutAssignment(
      request: request,
      from: input,
      dependencyContainer: dependencyContainer
    )
    XCTAssertFalse(configManager.confirmedAssignment)
  }
}
