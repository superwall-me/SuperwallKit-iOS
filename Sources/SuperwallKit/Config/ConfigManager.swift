//
//  File.swift
//
//
//  Created by Yusuf Tör on 22/06/2022.
//
// swiftlint:disable type_body_length function_body_length file_length

import Combine
import UIKit

class ConfigManager {
  /// A publisher that emits just once only when `config` is non-`nil`.
  var hasConfig: AnyPublisher<Config, Error> {
    configState
      .compactMap { $0.getConfig() }
      .first()
      .eraseToAnyPublisher()
  }

  /// The configuration of the Superwall dashboard
  var configState = CurrentValueSubject<ConfigState, Error>(.retrieving)

  /// Convenience variable to access config.
  var config: Config? {
    return configState.value.getConfig()
  }

  /// Options for configuring the SDK.
  var options: SuperwallOptions

  /// A dictionary of triggers by their placement name.
  @DispatchQueueBacked
  var triggersByPlacementName: [String: Trigger] = [:]

  /// A memory store of assignments that are yet to be confirmed.
  ///
  /// When the trigger is fired, the assignment is confirmed and stored to disk.
  @DispatchQueueBacked
  var unconfirmedAssignments: [Experiment.ID: Experiment.Variant] = [:]

  var configRetryCount = 0

  private unowned let storeKitManager: StoreKitManager
  private unowned let storage: Storage
  private unowned let network: Network
  private unowned let paywallManager: PaywallManager
  private unowned let deviceHelper: DeviceHelper
  private unowned let entitlementsInfo: EntitlementsInfo
  let expressionEvaluator: CELEvaluator

  /// A task that is non-`nil` when preloading all paywalls.
  private var currentPreloadingTask: Task<Void, Never>?

  typealias Factory = RequestFactory
    & AudienceFilterAttributesFactory
    & ReceiptFactory
    & DeviceHelperFactory
  private let factory: Factory

  init(
    options: SuperwallOptions,
    storeKitManager: StoreKitManager,
    storage: Storage,
    network: Network,
    paywallManager: PaywallManager,
    deviceHelper: DeviceHelper,
    entitlementsInfo: EntitlementsInfo,
    factory: Factory
  ) {
    self.options = options
    self.storeKitManager = storeKitManager
    self.storage = storage
    self.network = network
    self.paywallManager = paywallManager
    self.deviceHelper = deviceHelper
    self.entitlementsInfo = entitlementsInfo
    self.factory = factory
    self.expressionEvaluator = CELEvaluator(
      storage: self.storage,
      factory: self.factory
    )
  }

  /// This refreshes config, requiring paywalls to reload and removing unused paywall view controllers.
  /// It fails quietly, falling back to the old config.
  func refreshConfiguration() async {
    // Make sure config already exists
    guard let oldConfig = config else {
      return
    }

    // Ensure the config refresh feature flag is enabled
    guard oldConfig.featureFlags.enableConfigRefresh == true else {
      return
    }

    do {
      let startAt = Date()
      let newConfig = try await network.getConfig { [weak self] attempt in
        self?.configRetryCount = attempt
      }
      let fetchDuration = Date().timeIntervalSince(startAt)

      // Remove all paywalls and paywall vcs that have either been removed or changed.
      let removedOrChangedPaywallIds = ConfigLogic.getRemovedOrChangedPaywallIds(
        oldConfig: oldConfig,
        newConfig: newConfig
      )
      await paywallManager.removePaywalls(withIds: removedOrChangedPaywallIds)

      await processConfig(newConfig, isFirstTime: false)
      configState.send(.retrieved(newConfig))

      let configRefresh = InternalSuperwallPlacement.ConfigRefresh(
        buildId: newConfig.buildId,
        retryCount: configRetryCount,
        cacheStatus: .notCached,
        fetchDuration: fetchDuration
      )
      await Superwall.shared.track(configRefresh)
      Task { await preloadPaywalls() }
    } catch {
      Logger.debug(
        logLevel: .warn,
        scope: .superwallCore,
        message: "Failed to refresh configuration.",
        info: nil,
        error: error
      )
    }
  }

  func fetchConfiguration() async {
    do {
      let startAt = Date()

      // Retrieve cached config and determine if refresh is enabled
      let cachedConfig = storage.get(LatestConfig.self)
      let enableConfigRefresh = cachedConfig?.featureFlags.enableConfigRefresh ?? false
      let timeout: TimeInterval = 1

      // Prepare tasks for fetching config and geoInfo concurrently
      // Return a tuple including the `isUsingCached` flag
      async let configResult: (config: Config, isUsingCached: Bool) = { [weak self] in
        guard let self = self else {
          throw CancellationError()
        }
        if let cachedConfig = cachedConfig,
          enableConfigRefresh {
          do {
            let result = try await self.fetchWithTimeout({
              try await self.network.getConfig(maxRetry: 0)
            },
            timeout: timeout)
            return (result, false)
          } catch {
            // Return the cached config and set isUsingCached to true
            return (cachedConfig, true)
          }
        } else {
          let config = try await self.network.getConfig { attempt in
            self.configRetryCount = attempt
            self.configState.send(.retrying)
          }
          return (config, false)
        }
      }()

      async let isUsingCachedGeo: Bool = { [weak self] in
        guard let self = self else {
          return false
        }
        let cachedGeoInfo = self.storage.get(LatestGeoInfo.self)

        if let cachedGeoInfo = cachedGeoInfo,
          enableConfigRefresh {
          do {
            let geoInfo = try await self.fetchWithTimeout({
              try await self.network.getGeoInfo(maxRetry: 0)
            },
            timeout: timeout)
            self.deviceHelper.geoInfo = geoInfo
            return false
          } catch {
            self.deviceHelper.geoInfo = cachedGeoInfo
            return true
          }
        } else {
          await self.deviceHelper.getGeoInfo()
          return false
        }
      }()

      let (config, isUsingCachedConfig) = try await configResult
      let configFetchDuration = Date().timeIntervalSince(startAt)
      let isUsingCachedGeoInfo = await isUsingCachedGeo

      let cacheStatus: InternalSuperwallPlacement.ConfigCacheStatus =
        isUsingCachedConfig ? .cached : .notCached
      Task {
        let configRefresh = InternalSuperwallPlacement.ConfigRefresh(
          buildId: config.buildId,
          retryCount: configRetryCount,
          cacheStatus: cacheStatus,
          fetchDuration: configFetchDuration
        )
        await Superwall.shared.track(configRefresh)
      }

      let deviceAttributes = await factory.makeSessionDeviceAttributes()
      await Superwall.shared.track(
        InternalSuperwallPlacement.DeviceAttributes(deviceAttributes: deviceAttributes)
      )

      await processConfig(config, isFirstTime: true)

      configState.send(.retrieved(config))

      Task {
        await preloadPaywalls()
      }
      if isUsingCachedGeoInfo {
        Task {
          await deviceHelper.getGeoInfo()
        }
      }
      if isUsingCachedConfig {
        Task {
          await refreshConfiguration()
        }
      }
    } catch {
      configState.send(completion: .failure(error))

      let configFallback = InternalSuperwallPlacement.ConfigFail(
        message: error.localizedDescription
      )
      await Superwall.shared.track(configFallback)

      Logger.debug(
        logLevel: .error,
        scope: .superwallCore,
        message: "Failed to Fetch Configuration",
        info: nil,
        error: error
      )
    }
  }

  private func fetchWithTimeout<T>(
    _ task: @escaping () async throws -> T,
    timeout: TimeInterval
  ) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
      group.addTask {
        try await task()
      }

      group.addTask {
        try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
        throw CancellationError()
      }

      do {
        let result = try await group.next()
        group.cancelAll()
        if let result = result {
          return result
        } else {
          throw CancellationError()
        }
      } catch {
        group.cancelAll()
        throw error
      }
    }
  }

  private func processConfig(
    _ config: Config,
    isFirstTime: Bool
  ) async {
    storage.save(
      config.featureFlags.disableVerbosePlacements, forType: DisableVerbosePlacements.self)
    storage.save(config, forType: LatestConfig.self)
    triggersByPlacementName = ConfigLogic.getTriggersByPlacementName(from: config.triggers)
    choosePaywallVariants(from: config.triggers)

    let entitlementsByProductId = ConfigLogic.extractEntitlements(from: config)
    entitlementsInfo.setEntitlementsFromConfig(entitlementsByProductId)

    // Load the products after entitlementsInfo is set because we need to map
    // purchased products to entitlements.
    await factory.loadPurchasedProducts()
    if isFirstTime {
      await checkForTouchesBeganTrigger(in: config.triggers)
    }
  }

  /// Reassigns variants and preloads paywalls again.
  func reset() {
    guard let config = configState.value.getConfig() else {
      return
    }
    unconfirmedAssignments.removeAll()
    choosePaywallVariants(from: config.triggers)
    Task { await preloadPaywalls() }
  }

  /// Swizzles the UIWindow's `sendEvent` to intercept the first `began` touch event if
  /// config's triggers contain `touches_began`.
  private func checkForTouchesBeganTrigger(in triggers: Set<Trigger>) async {
    if triggers.contains(where: { $0.placementName == SuperwallPlacement.touchesBegan.description }) {
      await UIWindow.swizzleSendEvent()
    }
  }

  // MARK: - Assignments

  private func choosePaywallVariants(from triggers: Set<Trigger>) {
    updateAssignments { confirmedAssignments in
      ConfigLogic.chooseAssignments(
        fromTriggers: triggers,
        confirmedAssignments: confirmedAssignments
      )
    }
  }

  /// Gets the assignments from the server and saves them to disk, overwriting any that already exist on disk/in memory.
  func getAssignments() async throws {
    let config =
      try await configState
      .compactMap { $0.getConfig() }
      .throwableAsync()

    let triggers = config.triggers

    guard !triggers.isEmpty else {
      return
    }

    do {
      let assignments = try await network.getAssignments()

      updateAssignments { confirmedAssignments in
        ConfigLogic.transferAssignmentsFromServerToDisk(
          assignments: assignments,
          triggers: triggers,
          confirmedAssignments: confirmedAssignments,
          unconfirmedAssignments: unconfirmedAssignments
        )
      }

      Task { await preloadPaywalls() }
    } catch {
      Logger.debug(
        logLevel: .error,
        scope: .configManager,
        message: "Error retrieving assignments.",
        error: error
      )
    }
  }

  /// Sends an assignment confirmation to the server and updates on-device assignments.
  func confirmAssignment(_ assignment: ConfirmableAssignment) {
    let postback: AssignmentPostback = .create(from: assignment)
    Task { await network.confirmAssignments(postback) }

    updateAssignments { confirmedAssignments in
      ConfigLogic.move(
        assignment,
        from: unconfirmedAssignments,
        to: confirmedAssignments
      )
    }
  }

  /// Performs a given operation on the confirmed assignments, before updating both confirmed
  /// and unconfirmed assignments.
  ///
  /// - Parameters:
  ///   - operation: Provided logic that takes confirmed assignments by ID and returns updated assignments.
  private func updateAssignments(
    using operation: ([Experiment.ID: Experiment.Variant]) -> ConfigLogic.AssignmentOutcome
  ) {
    var confirmedAssignments = storage.getConfirmedAssignments()

    let updatedAssignments = operation(confirmedAssignments)
    unconfirmedAssignments = updatedAssignments.unconfirmed
    confirmedAssignments = updatedAssignments.confirmed

    storage.saveConfirmedAssignments(confirmedAssignments)
  }

  // MARK: - Preloading Paywalls
  private func getTreatmentPaywallIds(from triggers: Set<Trigger>) -> Set<String> {
    guard let config = configState.value.getConfig() else {
      return []
    }
    let preloadableTriggers = ConfigLogic.filterTriggers(
      triggers,
      removing: config.preloadingDisabled
    )
    if preloadableTriggers.isEmpty {
      return []
    }
    let confirmedAssignments = storage.getConfirmedAssignments()
    return ConfigLogic.getActiveTreatmentPaywallIds(
      forTriggers: preloadableTriggers,
      confirmedAssignments: confirmedAssignments,
      unconfirmedAssignments: unconfirmedAssignments
    )
  }

  /// Preloads paywalls.
  ///
  /// A developer can disable preloading of paywalls by setting ``SuperwallOptions/shouldPreloadPaywalls``.
  private func preloadPaywalls() async {
    guard Superwall.shared.options.paywalls.shouldPreload else {
      return
    }
    await preloadAllPaywalls()
  }

  /// Preloads paywalls referenced by triggers.
  func preloadAllPaywalls() async {
    currentPreloadingTask = Task { [weak self, currentPreloadingTask] in
      guard let self = self else {
        return
      }
      // Wait until the previous task is finished before continuing.
      await currentPreloadingTask?.value

      guard
        let config = try? await self.configState
          .compactMap({ $0.getConfig() })
          .throwableAsync()
      else {
        return
      }
      let triggers = ConfigLogic.filterTriggers(
        config.triggers,
        removing: config.preloadingDisabled
      )
      let confirmedAssignments = self.storage.getConfirmedAssignments()
      var paywallIds = await ConfigLogic.getAllActiveTreatmentPaywallIds(
        fromTriggers: triggers,
        confirmedAssignments: confirmedAssignments,
        unconfirmedAssignments: self.unconfirmedAssignments,
        expressionEvaluator: expressionEvaluator
      )
      // Do not preload the presented paywall. This is because if config refreshes, we
      // don't want to refresh the presented paywall until it's dismissed and presented again.
      if let presentedPaywallId = await self.paywallManager.presentedViewController?.paywall.identifier {
        paywallIds.remove(presentedPaywallId)
      }
      await self.preloadPaywalls(withIdentifiers: paywallIds)
    }
  }

  /// Preloads paywalls referenced by the provided triggers.
  func preloadPaywalls(for placementNames: Set<String>) async {
    guard
      let config =
        try? await configState
        .compactMap({ $0.getConfig() })
        .throwableAsync()
    else {
      return
    }
    let triggersToPreload = config.triggers.filter { placementNames.contains($0.placementName) }
    let triggerPaywallIdentifiers = getTreatmentPaywallIds(from: triggersToPreload)
    await preloadPaywalls(
      withIdentifiers: triggerPaywallIdentifiers
    )
  }

  /// Preloads paywalls referenced by triggers.
  private func preloadPaywalls(withIdentifiers paywallIdentifiers: Set<String>) async {
    await withTaskGroup(of: Void.self) { group in
      for identifier in paywallIdentifiers {
        group.addTask { [weak self] in
          guard let self = self else {
            return
          }
          let request = self.factory.makePaywallRequest(
            placementData: nil,
            responseIdentifiers: .init(paywallId: identifier),
            overrides: nil,
            isDebuggerLaunched: false,
            presentationSourceType: nil
          )
          guard let paywall = try? await self.paywallManager.getPaywall(from: request) else {
            return
          }

          await self.paywallManager.attemptToPreloadArchive(from: paywall)

          _ = try? await self.paywallManager.getViewController(
            for: paywall,
            isDebuggerLaunched: request.isDebuggerLaunched,
            isForPresentation: true,
            isPreloading: true,
            delegate: nil
          )
        }
      }
    }
  }
}
