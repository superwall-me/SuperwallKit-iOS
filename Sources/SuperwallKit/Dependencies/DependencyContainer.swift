//
//  File.swift
//
//
//  Created by Yusuf Tör on 23/12/2022.
//
// swiftlint:disable function_body_length file_length

import UIKit
import Combine
import SystemConfiguration
import StoreKit

/// Contains all of the SDK's core utility objects that are normally directly injected as dependencies.
///
/// This conforms to protocol factory methods which can be used to make objects that have
/// dependencies injected into them.
///
class DependencyContainer {
  lazy var storeKitManager: StoreKitManager = self.makeStoreKitManager()
  lazy var receiptManager: ReceiptManager = self.makeReceiptManager()
  lazy var storage: Storage = self.makeStorage()
  lazy var network: Network = self.makeNetwork()
  lazy var paywallRequestManager: PaywallRequestManager = self.makePaywallRequestManager()
  lazy var paywallManager: PaywallManager = self.makePaywallManager()
  lazy var configManager: ConfigManager = self.makeConfigManager()
  lazy var api: Api = self.makeApi()
  lazy var deviceHelper: DeviceHelper = self.makeDeviceHelper()
  lazy var queue: EventsQueue = self.makeQueue()
  lazy var identityManager: IdentityManager = self.makeIdentityManager()
  lazy var sessionEventsManager: SessionEventsManager = self.makeSessionEventsManager()
  lazy var productsFetcher: ProductsFetcherSK1 = self.makeProductsFetcher()
  lazy var productsPurchaser: ProductPurchaserSK1 = self.makeProductsPurchaser()
  lazy var purchaseController: PurchaseController = self.makePurchaseController()
  lazy var appSessionManager: AppSessionManager = self.makeAppSessionManager()
  lazy var debugManager: DebugManager = self.makeDebugManager()
  lazy var transactionManager: TransactionManager = self.makeTransactionManager()
  lazy var delegateAdapter: SuperwallDelegateAdapter = self.makeDelegateAdapter()

  let options: SuperwallOptions
  private let controller: PurchaseController?

  init(
    purchaseController controller: PurchaseController? = nil,
    options: SuperwallOptions? = nil
  ) {
    self.controller = controller
    self.options = options ?? SuperwallOptions()
  }
}

// MARK: - Factory

extension DependencyContainer {
  private func makeProductsFetcher() -> ProductsFetcherSK1 {
    return ProductsFetcherSK1()
  }

  private func makeStoreKitManager() -> StoreKitManager {
    return StoreKitManager(factory: self)
  }

  private func makeReceiptManager() -> ReceiptManager {
    return ReceiptManager(factory: self)
  }

  private func makeStorage() -> Storage {
    return Storage(factory: self)
  }

  private func makeNetwork() -> Network {
    return Network(factory: self)
  }

  private func makePaywallRequestManager() -> PaywallRequestManager {
    return PaywallRequestManager(factory: self)
  }

  private func makePaywallManager() -> PaywallManager {
    return PaywallManager(factory: self)
  }

  private func makeConfigManager() -> ConfigManager {
    return ConfigManager(options: options, factory: self)
  }

  private func makeApi() -> Api {
    return Api(networkEnvironment: configManager.options.networkEnvironment)
  }

  private func makeDeviceHelper() -> DeviceHelper {
    return DeviceHelper(factory: self)
  }

  private func makeQueue() -> EventsQueue {
    return EventsQueue(factory: self)
  }

  private func makeIdentityManager() -> IdentityManager {
    return IdentityManager(factory: self)
  }

  private func makeSessionEventsManager() -> SessionEventsManager {
    return SessionEventsManager(factory: self)
  }

  private func makeProductsPurchaser() -> ProductPurchaserSK1 {
    return ProductPurchaserSK1(factory: self)
  }

  private func makePurchaseController() -> PurchaseController {
    return controller ?? AutomaticPurchaseController(factory: self)
  }

  private func makeAppSessionManager() -> AppSessionManager {
    return AppSessionManager(factory: self)
  }

  private func makeDebugManager() -> DebugManager {
    return DebugManager(factory: self)
  }

  private func makeTransactionManager() -> TransactionManager {
    return TransactionManager(factory: self)
  }

  private func makeDelegateAdapter() -> SuperwallDelegateAdapter {
    return SuperwallDelegateAdapter()
  }
}

// TODO: Consider making the below extensions protocols instead of factories

// MARK: - IdentityInfoFactory
extension DependencyContainer: IdentityInfoFactory {
  func makeIdentityInfo() -> IdentityInfo {
    return IdentityInfo(
      aliasId: identityManager.aliasId,
      appUserId: identityManager.appUserId
    )
  }
}

// MARK: - AppManagerDelegate
extension DependencyContainer: AppManagerDelegate {
  func didUpdateAppSession(_ appSession: AppSession) async {
    await sessionEventsManager.updateAppSession(appSession)
  }
}

// MARK: - CacheFactory
extension DependencyContainer: CacheFactory {
  func makeCache() -> PaywallViewControllerCache {
    return PaywallViewControllerCache(deviceLocaleString: deviceHelper.locale)
  }
}

// MARK: - DeviceInfofactory
extension DependencyContainer: DeviceHelperFactory {
  func makeDeviceInfo() -> DeviceInfo {
    return DeviceInfo(
      appInstalledAtString: deviceHelper.appInstalledAtString,
      locale: deviceHelper.locale
    )
  }

  func makeIsSandbox() -> Bool {
    return deviceHelper.isSandbox == "true"
  }

  func makeSessionDeviceAttributes() async -> [String: Any] {
    var attributes = await deviceHelper.getTemplateDevice()

    attributes["utcDate"] = nil
    attributes["localDate"] = nil
    attributes["localDate"] = nil
    attributes["localTime"] = nil
    attributes["utcTime"] = nil
    attributes["utcDateTime"] = nil
    attributes["localDateTime"] = nil

    return attributes
  }
}

// MARK: - DeviceInfofactory
extension DependencyContainer: LocaleIdentifierFactory {
  func makeLocaleIdentifier() -> String? {
    return configManager.options.localeIdentifier
  }
}

// MARK: - ViewControllerFactory
extension DependencyContainer: ViewControllerFactory {
  @MainActor
  func makePaywallViewController(
    for paywall: Paywall,
    withCache cache: PaywallViewControllerCache?,
    delegate: PaywallViewControllerDelegateAdapter?
  ) -> PaywallViewController {
    let messageHandler = PaywallMessageHandler(factory: self)
    let webView = SWWebView(
      isMac: deviceHelper.isMac,
      sessionEventsManager: sessionEventsManager,
      messageHandler: messageHandler
    )
    let paywallViewController = PaywallViewController(
      paywall: paywall,
      eventDelegate: Superwall.shared,
      delegate: delegate,
      deviceHelper: deviceHelper,
      factory: self,
      storage: storage,
      paywallManager: paywallManager,
      webView: webView,
      cache: cache
    )

    webView.delegate = paywallViewController
    messageHandler.delegate = paywallViewController

    return paywallViewController
  }

  @MainActor
  func makeDebugViewController(withDatabaseId id: String?) -> DebugViewController {
    let viewController = DebugViewController(factory: self)
    viewController.paywallDatabaseId = id
    viewController.modalPresentationStyle = .overFullScreen
    return viewController
  }
}

extension DependencyContainer: VariablesFactory {
  func makeJsonVariables(
    productVariables: [ProductVariable]?,
    computedPropertyRequests: [ComputedPropertyRequest],
    event: EventData?
  ) async -> JSON {
    let templateDeviceDict = await deviceHelper.getDeviceAttributes(
      since: event,
      computedPropertyRequests: computedPropertyRequests
    )

    return Variables(
      productVariables: productVariables,
      params: event?.parameters,
      userAttributes: identityManager.userAttributes,
      templateDeviceDictionary: templateDeviceDict
    ).templated()
  }
}

// MARK: - PaywallRequestFactory
extension DependencyContainer: RequestFactory {
  func makePaywallRequest(
    eventData: EventData? = nil,
    responseIdentifiers: ResponseIdentifiers,
    overrides: PaywallRequest.Overrides? = nil,
    isDebuggerLaunched: Bool,
    presentationSourceType: String?,
    retryCount: Int
  ) -> PaywallRequest {
    return PaywallRequest(
      eventData: eventData,
      responseIdentifiers: responseIdentifiers,
      overrides: overrides ?? PaywallRequest.Overrides(),
      isDebuggerLaunched: isDebuggerLaunched,
      presentationSourceType: presentationSourceType,
      retryCount: retryCount
    )
  }

  func makePresentationRequest(
    _ presentationInfo: PresentationInfo,
    paywallOverrides: PaywallOverrides? = nil,
    presenter: UIViewController? = nil,
    isDebuggerLaunched: Bool? = nil,
    subscriptionStatus: AnyPublisher<SubscriptionStatus, Never>? = nil,
    isPaywallPresented: Bool,
    type: PresentationRequestType
  ) -> PresentationRequest {
    return PresentationRequest(
      presentationInfo: presentationInfo,
      presenter: presenter,
      paywallOverrides: paywallOverrides,
      flags: .init(
        isDebuggerLaunched: isDebuggerLaunched ?? debugManager.isDebuggerLaunched,
        subscriptionStatus: subscriptionStatus ?? Superwall.shared.$subscriptionStatus.eraseToAnyPublisher(),
        isPaywallPresented: isPaywallPresented,
        type: type
      )
    )
  }
}

// MARK: - ApiFactory
extension DependencyContainer: ApiFactory {
  func makeHeaders(
    fromRequest request: URLRequest,
    isForDebugging: Bool,
    requestId: String
  ) async -> [String: String] {
    let key = isForDebugging ? storage.debugKey : storage.apiKey
    let auth = "Bearer \(key)"
    let headers = [
      "Authorization": auth,
      "X-Platform": "iOS",
      "X-Platform-Environment": "SDK",
      "X-App-User-ID": identityManager.appUserId ?? "",
      "X-Alias-ID": identityManager.aliasId,
      "X-URL-Scheme": deviceHelper.urlScheme,
      "X-Vendor-ID": deviceHelper.vendorId,
      "X-App-Version": deviceHelper.appVersion,
      "X-OS-Version": deviceHelper.osVersion,
      "X-Device-Model": deviceHelper.model,
      "X-Device-Locale": deviceHelper.locale,
      "X-Device-Language-Code": deviceHelper.languageCode,
      "X-Device-Currency-Code": deviceHelper.currencyCode,
      "X-Device-Currency-Symbol": deviceHelper.currencySymbol,
      "X-Device-Timezone-Offset": deviceHelper.secondsFromGMT,
      "X-App-Install-Date": deviceHelper.appInstalledAtString,
      "X-Radio-Type": deviceHelper.radioType,
      "X-Device-Interface-Style": deviceHelper.interfaceStyle,
      "X-SDK-Version": sdkVersion,
      "X-Request-Id": requestId,
      "X-Bundle-ID": deviceHelper.bundleId,
      "X-Low-Power-Mode": deviceHelper.isLowPowerModeEnabled,
      "X-Is-Sandbox": deviceHelper.isSandbox,
      "X-Subscription-Status": Superwall.shared.subscriptionStatus.description,
      "Content-Type": "application/json"
    ]

    return headers
  }
}

// MARK: - Rule Params
extension DependencyContainer: RuleAttributesFactory {
  func makeRuleAttributes(
    forEvent event: EventData?,
    withComputedProperties computedPropertyRequests: [ComputedPropertyRequest]
  ) async -> JSON {
    var userAttributes = identityManager.userAttributes
    userAttributes["isLoggedIn"] = identityManager.isLoggedIn

    let deviceAttributes = await deviceHelper.getDeviceAttributes(
      since: event,
      computedPropertyRequests: computedPropertyRequests
    )
    return JSON([
      "user": userAttributes,
      "device": deviceAttributes,
      "params": event?.parameters.dictionaryObject ?? ""
    ] as [String: Any])
  }
}

// MARK: - TriggerSessionManager
extension DependencyContainer: TriggerSessionManagerFactory {
  func makeTriggerSessionManager() -> TriggerSessionManager {
    // Separating delegate and sessionEventsManager to support testing.
    return TriggerSessionManager(
      delegate: sessionEventsManager,
      sessionEventsManager: sessionEventsManager,
      storage: storage,
      configManager: configManager,
      appSessionManager: appSessionManager,
      identityManager: identityManager
    )
  }

  func getTriggerSessionManager() -> TriggerSessionManager {
    return sessionEventsManager.triggerSession
  }
}

// MARK: - ConfigManagerFactory
extension DependencyContainer: ConfigManagerFactory {
  /// Gets the paywall response from the static config, if the device locale starts with "en" and no more specific version can be found.
  func makeStaticPaywall(
    withId paywallId: String?,
    isDebuggerLaunched: Bool
  ) -> Paywall? {
    if isDebuggerLaunched {
      return nil
    }
    let deviceInfo = makeDeviceInfo()
    return ConfigLogic.getStaticPaywall(
      withId: paywallId,
      config: configManager.config,
      deviceLocale: deviceInfo.locale
    )
  }
}

// MARK: - StoreTransactionFactory
extension DependencyContainer: StoreTransactionFactory {
  func makeStoreTransaction(from transaction: SK1Transaction) async -> StoreTransaction {
    let triggerSession = await sessionEventsManager.triggerSession.activeTriggerSession
    return StoreTransaction(
      transaction: SK1StoreTransaction(transaction: transaction),
      configRequestId: configManager.config?.requestId ?? "",
      appSessionId: appSessionManager.appSession.id,
      triggerSessionId: triggerSession?.id
    )
  }

  @available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  func makeStoreTransaction(from transaction: SK2Transaction) async -> StoreTransaction {
    let triggerSession = await sessionEventsManager.triggerSession.activeTriggerSession
    return StoreTransaction(
      transaction: SK2StoreTransaction(transaction: transaction),
      configRequestId: configManager.config?.requestId ?? "",
      appSessionId: appSessionManager.appSession.id,
      triggerSessionId: triggerSession?.id
    )
  }
}

// MARK: - Options Factory
extension DependencyContainer: OptionsFactory {
  func makeSuperwallOptions() -> SuperwallOptions {
    return configManager.options
  }
}

// MARK: - Triggers Factory
extension DependencyContainer: TriggerFactory {
  func makeTriggers() -> Set<String> {
    return Set(configManager.triggersByEventName.keys)
  }
}

// MARK: - Purchase Controller Factory
extension DependencyContainer: HasExternalPurchaseControllerFactory {
  func makeHasExternalPurchaseController() -> Bool {
    return purchaseController.isInternal == false
  }
}

// MARK: - Feature Flags Factory
extension DependencyContainer: FeatureFlagsFactory {
  func makeFeatureFlags() -> FeatureFlags? {
    return configManager.config?.featureFlags
  }
}

// MARK: - Computed Property Requests Factory
extension DependencyContainer: ComputedPropertyRequestsFactory {
  func makeComputedPropertyRequests() -> [ComputedPropertyRequest] {
    return configManager.config?.allComputedProperties ?? []
  }
}

// MARK: - Purchased Transactions Factory
extension DependencyContainer: PurchasedTransactionsFactory {
  func makePurchasingCoordinator() -> PurchasingCoordinator {
    return productsPurchaser.coordinator
  }
}

// MARK: - User Attributes Event Factory
extension DependencyContainer: UserAttributesEventFactory {
  func makeUserAttributesEvent() -> InternalSuperwallEvent.Attributes {
    return InternalSuperwallEvent.Attributes(
      appInstalledAtString: deviceHelper.appInstalledAtString,
      customParameters: identityManager.userAttributes
    )
  }
}

