//
//  File.swift
//  
//
//  Created by Yusuf Tör on 06/12/2022.
//

import XCTest
@testable import SuperwallKit
import Combine

final class ConfirmPaywallAssignmentOperatorTests: XCTestCase {
  var cancellables: [AnyCancellable] = []

  @MainActor
  func test_confirmPaywallAssignment_debuggerLaunched() async {
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

    let request = PresentationRequest.stub()
      .setting(\.flags.type, to: .presentation)
     Superwall.shared.confirmPaywallAssignment(
      ConfirmableAssignment(experimentId: "", variant: .init(id: "", type: .treatment, paywallId: "")), request: request,
      isDebuggerLaunched: true,
      dependencyContainer: dependencyContainer
     )
    XCTAssertFalse(configManager.confirmedAssignment)
  }

  @MainActor
  func test_confirmPaywallAssignment_noAssignment() async {
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

    let request = PresentationRequest.stub()
      .setting(\.flags.type, to: .presentation)
     Superwall.shared.confirmPaywallAssignment(
      nil,
      request: request,
      isDebuggerLaunched: false,
      dependencyContainer: dependencyContainer
     )
    XCTAssertFalse(configManager.confirmedAssignment)
  }

  @MainActor
  func test_confirmPaywallAssignment_confirmAssignment() async {
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

    let request = dependencyContainer.makePresentationRequest(
      .explicitTrigger(.stub()),
      isDebuggerLaunched: false,
      isPaywallPresented: false,
      type: .getPaywall(.stub())
    )

    Superwall.shared.confirmPaywallAssignment(
      ConfirmableAssignment(experimentId: "", variant: .init(id: "", type: .treatment, paywallId: "")),
      request: request,
      isDebuggerLaunched: false,
      dependencyContainer: dependencyContainer
     )
   XCTAssertTrue(configManager.confirmedAssignment)
  }

  @MainActor
  func test_confirmPaywallAssignment_getPresentationResult() async {
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

    let request = dependencyContainer.makePresentationRequest(
      .explicitTrigger(.stub()),
      isDebuggerLaunched: false,
      isPaywallPresented: false,
      type: .getPresentationResult
    )

    Superwall.shared.confirmPaywallAssignment(
      ConfirmableAssignment(experimentId: "", variant: .init(id: "", type: .treatment, paywallId: "")),
      request: request,
      isDebuggerLaunched: false,
      dependencyContainer: dependencyContainer
     )
   XCTAssertTrue(configManager.confirmedAssignment)
  }

  @MainActor
  func test_confirmPaywallAssignment_handleImplicitTrigger() async {
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

    let request = dependencyContainer.makePresentationRequest(
      .explicitTrigger(.stub()),
      isDebuggerLaunched: false,
      isPaywallPresented: false,
      type: .handleImplicitTrigger
    )

    Superwall.shared.confirmPaywallAssignment(
      ConfirmableAssignment(experimentId: "", variant: .init(id: "", type: .treatment, paywallId: "")),
      request: request,
      isDebuggerLaunched: false,
      dependencyContainer: dependencyContainer
     )
    XCTAssertTrue(configManager.confirmedAssignment)
  }

  @MainActor
  func test_confirmPaywallAssignment_paywallDeclineCheck() async {
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

    let request = dependencyContainer.makePresentationRequest(
      .explicitTrigger(.stub()),
      isDebuggerLaunched: false,
      isPaywallPresented: false,
      type: .paywallDeclineCheck
    )

    Superwall.shared.confirmPaywallAssignment(
      ConfirmableAssignment(experimentId: "", variant: .init(id: "", type: .treatment, paywallId: "")),
      request: request,
      isDebuggerLaunched: false,
      dependencyContainer: dependencyContainer
     )
    XCTAssertFalse(configManager.confirmedAssignment)
  }
}
