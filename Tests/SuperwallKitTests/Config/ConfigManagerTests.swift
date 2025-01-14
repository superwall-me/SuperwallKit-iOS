//
//  File.swift
//  
//
//  Created by Yusuf Tör on 23/06/2022.
//
// swiftlint:disable all

@testable import SuperwallKit
import XCTest

@available(iOS 14.0, *)
final class ConfigManagerTests: XCTestCase {
  func test_refreshConfiguration() async {
    let dependencyContainer = DependencyContainer()
    let network = NetworkMock(
      options: SuperwallOptions(),
      factory: dependencyContainer
    )
    let newConfig: Config = .stub()
      .setting(\.buildId, to: "123")
    network.configReturnValue = .success(newConfig)

    let configManager = ConfigManager(
      options: SuperwallOptions(),
      storeKitManager: dependencyContainer.storeKitManager,
      storage: dependencyContainer.storage,
      network: network,
      paywallManager: dependencyContainer.paywallManager,
      deviceHelper: dependencyContainer.deviceHelper,
      entitlementsInfo: dependencyContainer.entitlementsInfo,
      factory: dependencyContainer
    )

    let oldConfig: Config = .stub()
      .setting(\.buildId, to: "abc")
    configManager.configState.send(.retrieved(oldConfig))

    await configManager.refreshConfiguration()

    XCTAssertEqual(configManager.config?.buildId, "123")
  }

  func test_configEncodedCorrectly() async {
    let dependencyContainer = DependencyContainer()

    let paywall = Paywall.stub()
      .setting(\.products, to: [.init(name: "abc", type: .appStore(.init(store: .appStore, id: "abc")), entitlements: [.stub()])])
    let config: Config = Config(
      buildId: "buildId",
      triggers: [
        .init(
          placementName: "event",
          audiences: [.stub()]
        )
      ],
      paywalls: [paywall],
      logLevel: 2,
      locales: ["fr"],
      appSessionTimeout: 2202,
      featureFlags: .stub(),
      preloadingDisabled: .stub(),
      attribution: .init(appleSearchAds: .init(enabled: true)),
      products: paywall.products
    )
    dependencyContainer.storage.save(config, forType: LatestConfig.self)
    let newConfig = dependencyContainer.storage.get(LatestConfig.self)
    XCTAssertEqual(config, newConfig)
  }

  // MARK: - Confirm Assignments
  func test_confirmAssignment() async {
    let experimentId = "abc"
    let variantId = "def"
    let variant: Experiment.Variant = .init(id: variantId, type: .treatment, paywallId: "jkl")
    let assignment = ConfirmableAssignment(
      experimentId: experimentId,
      variant: variant
    )
    let dependencyContainer = DependencyContainer()
    let network = NetworkMock(
      options: SuperwallOptions(),
      factory: dependencyContainer
    )
    let storage = StorageMock()
    let configManager = ConfigManager(
      options: SuperwallOptions(),
      storeKitManager: dependencyContainer.storeKitManager,
      storage: storage,
      network: network,
      paywallManager: dependencyContainer.paywallManager,
      deviceHelper: dependencyContainer.deviceHelper, 
      entitlementsInfo: dependencyContainer.entitlementsInfo,
      factory: dependencyContainer
    )
    configManager.confirmAssignment(assignment)

    let milliseconds = 200
    let nanoseconds = UInt64(milliseconds * 1_000_000)
    try? await Task.sleep(nanoseconds: nanoseconds)

    XCTAssertTrue(network.assignmentsConfirmed)
    XCTAssertEqual(storage.getConfirmedAssignments()[experimentId], variant)
    XCTAssertNil(configManager.unconfirmedAssignments[experimentId])
  }

  // MARK: - Load Assignments

  func test_loadAssignments_noConfig() async {
    let dependencyContainer = DependencyContainer()
    let network = NetworkMock(
      options: SuperwallOptions(),
      factory: dependencyContainer
    )
    let storage = StorageMock()
    let configManager = ConfigManager(
      options: SuperwallOptions(),
      storeKitManager: dependencyContainer.storeKitManager,
      storage: storage,
      network: network,
      paywallManager: dependencyContainer.paywallManager,
      deviceHelper: dependencyContainer.deviceHelper,
      entitlementsInfo: dependencyContainer.entitlementsInfo,
      factory: dependencyContainer
    )

    let expectation = expectation(description: "No assignments")
    expectation.isInverted = true
    Task {
      try? await configManager.getAssignments()
      expectation.fulfill()
    }

    await fulfillment(of: [expectation], timeout: 1)

    XCTAssertTrue(storage.getConfirmedAssignments().isEmpty)
    XCTAssertTrue(configManager.unconfirmedAssignments.isEmpty)
  }

  func test_loadAssignments_noTriggers() async {
    let dependencyContainer = DependencyContainer()
    let network = NetworkMock(
      options: SuperwallOptions(),
      factory: dependencyContainer
    )
    let storage = StorageMock()
    let configManager = ConfigManager(
      options: SuperwallOptions(),
      storeKitManager: dependencyContainer.storeKitManager,
      storage: storage,
      network: network,
      paywallManager: dependencyContainer.paywallManager,
      deviceHelper: dependencyContainer.deviceHelper, 
      entitlementsInfo: dependencyContainer.entitlementsInfo,
      factory: dependencyContainer
    )
    configManager.configState.send(.retrieved(.stub()
      .setting(\.triggers, to: [])))

    try? await configManager.getAssignments()

    XCTAssertTrue(storage.getConfirmedAssignments().isEmpty)
    XCTAssertTrue(configManager.unconfirmedAssignments.isEmpty)
  }

  func test_loadAssignments_saveAssignmentsFromServer() async {
    let dependencyContainer = DependencyContainer()
    let network = NetworkMock(
      options: SuperwallOptions(),
      factory: dependencyContainer
    )
    let storage = StorageMock()
    let configManager = ConfigManager(
      options: SuperwallOptions(),
      storeKitManager: dependencyContainer.storeKitManager,
      storage: storage,
      network: network,
      paywallManager: dependencyContainer.paywallManager,
      deviceHelper: dependencyContainer.deviceHelper,
      entitlementsInfo: dependencyContainer.entitlementsInfo,
      factory: dependencyContainer
    )

    let variantId = "variantId"
    let experimentId = "experimentId"

    let assignments: [Assignment] = [
      Assignment(experimentId: experimentId, variantId: variantId)
    ]
    network.assignments = assignments

    let variantOption: VariantOption = .stub()
      .setting(\.id, to: variantId)
    configManager.configState.send(.retrieved(.stub()
      .setting(\.triggers, to: [
        .stub()
        .setting(\.audiences, to: [
          .stub()
          .setting(\.experiment.id, to: experimentId)
          .setting(\.experiment.variants, to: [
            variantOption
          ])
        ])
      ])
    ))

    try? await configManager.getAssignments()

    try? await Task.sleep(nanoseconds: 1_000_000)

    XCTAssertEqual(storage.getConfirmedAssignments()[experimentId], variantOption.toExperimentVariant())
    XCTAssertTrue(configManager.unconfirmedAssignments.isEmpty)
  }
}
