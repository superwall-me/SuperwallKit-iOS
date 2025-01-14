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

/// Contains all of the SDK's core utility objects that are normally directly injected as dependencies.
///
/// This conforms to protocol factory methods which can be used to make objects that have
/// dependencies injected into them.
///
/// Objects only need `unowned` references to the dependencies injected into them because
/// `DependencyContainer` is owned by the `Superwall` class.
final class DependencyContainer {
  // swiftlint:disable implicitly_unwrapped_optional
  var configManager: ConfigManager!
  var identityManager: IdentityManager!
  var storeKitManager: StoreKitManager!
  var appSessionManager: AppSessionManager!
  var storage: Storage!
  var network: Network!
  var paywallManager: PaywallManager!
  var paywallRequestManager: PaywallRequestManager!
  var deviceHelper: DeviceHelper!
  var placementsQueue: PlacementsQueue!
  var debugManager: DebugManager!
  var api: Api!
  var transactionManager: TransactionManager!
  var delegateAdapter: SuperwallDelegateAdapter!
  var purchaseManager: PurchaseManager!
  var receiptManager: ReceiptManager!
  var purchaseController: PurchaseController!
  var productsManager: ProductsManager!
  var entitlementsInfo: EntitlementsInfo!
  var attributionPoster: AttributionPoster!
  // swiftlint:enable implicitly_unwrapped_optional
  let paywallArchiveManager = PaywallArchiveManager()

  init(
    purchaseController controller: PurchaseController? = nil,
    options: SuperwallOptions? = nil
  ) {
    delegateAdapter = SuperwallDelegateAdapter()
    storage = Storage(factory: self)
    entitlementsInfo = EntitlementsInfo(
      storage: storage,
      delegateAdapter: delegateAdapter
    )
    let options = options ?? SuperwallOptions()
    productsManager = ProductsManager(
      entitlementsInfo: entitlementsInfo,
      storeKitVersion: options.storeKitVersion
    )
    network = Network(
      options: options,
      factory: self
    )

    storeKitManager = StoreKitManager(productsManager: productsManager)

    purchaseController = controller ?? AutomaticPurchaseController(factory: self, entitlementsInfo: entitlementsInfo)

    receiptManager = ReceiptManager(
      storeKitVersion: options.storeKitVersion,
      productsManager: productsManager,
      receiptDelegate: purchaseController as? ReceiptDelegate
    )

    paywallRequestManager = PaywallRequestManager(
      storeKitManager: storeKitManager,
      network: network,
      factory: self
    )
    paywallManager = PaywallManager(
      factory: self,
      paywallRequestManager: paywallRequestManager
    )

    api = Api(networkEnvironment: options.networkEnvironment)

    deviceHelper = DeviceHelper(
      api: api,
      storage: storage,
      network: network,
      entitlementsInfo: entitlementsInfo,
      receiptManager: receiptManager,
      factory: self
    )

    configManager = ConfigManager(
      options: options,
      storeKitManager: storeKitManager,
      storage: storage,
      network: network,
      paywallManager: paywallManager,
      deviceHelper: deviceHelper,
      entitlementsInfo: entitlementsInfo,
      factory: self
    )

    attributionPoster = AttributionPoster(
      storage: storage,
      network: network,
      configManager: configManager
    )

    placementsQueue = PlacementsQueue(
      network: network,
      configManager: configManager
    )

    identityManager = IdentityManager(
      deviceHelper: deviceHelper,
      storage: storage,
      configManager: configManager
    )

    // Must be after session events
    appSessionManager = AppSessionManager(
      configManager: configManager,
      identityManager: identityManager,
      storage: storage,
      delegate: self
    )

    debugManager = DebugManager(
      storage: storage,
      factory: self
    )

    purchaseManager = PurchaseManager(
      storeKitVersion: options.storeKitVersion,
      storeKitManager: storeKitManager,
      receiptManager: receiptManager,
      identityManager: identityManager,
      storage: storage,
      factory: self
    )

    transactionManager = TransactionManager(
      storeKitManager: storeKitManager,
      receiptManager: receiptManager,
      purchaseController: purchaseController,
      placementsQueue: placementsQueue,
      purchaseManager: purchaseManager,
      productsManager: productsManager,
      factory: self
    )
  }
}

// MARK: - IdentityInfoFactory
extension DependencyContainer: IdentityInfoFactory {
  func makeIdentityInfo() -> IdentityInfo {
    return IdentityInfo(
      aliasId: identityManager.aliasId,
      appUserId: identityManager.appUserId
    )
  }
}

extension DependencyContainer: TransactionManagerFactory {
  func makeTransactionManager() -> TransactionManager {
    return transactionManager
  }
}

// MARK: - CacheFactory
extension DependencyContainer: CacheFactory {
  func makeCache() -> PaywallViewControllerCache {
    return PaywallViewControllerCache(deviceLocaleString: deviceHelper.locale)
  }
}

// MARK: - PaywallArchiveManagerFactory
extension DependencyContainer: PaywallArchiveManagerFactory {
  func makePaywallArchiveManager() -> PaywallArchiveManager {
    return paywallArchiveManager
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
    withPaywallArchiveManager archiveManager: PaywallArchiveManager?,
    delegate: PaywallViewControllerDelegateAdapter?
  ) -> PaywallViewController {
    let messageHandler = PaywallMessageHandler(
      receiptManager: receiptManager,
      factory: self
    )
    let webView = SWWebView(
      isMac: deviceHelper.isMac,
      messageHandler: messageHandler,
      isOnDeviceCacheEnabled: paywall.onDeviceCache == .enabled,
      factory: self
    )
    let paywallViewController = PaywallViewController(
      paywall: paywall,
      eventDelegate: Superwall.shared,
      delegate: delegate,
      deviceHelper: deviceHelper,
      factory: self,
      storage: storage,
      webView: webView,
      cache: cache,
      paywallArchiveManager: paywallArchiveManager
    )

    webView.delegate = paywallViewController
    messageHandler.delegate = paywallViewController

    return paywallViewController
  }

  @MainActor
  func makeDebugViewController(withDatabaseId id: String?) -> DebugViewController {
    let viewController = DebugViewController(
      storeKitManager: storeKitManager,
      network: network,
      paywallRequestManager: paywallRequestManager,
      paywallManager: paywallManager,
      debugManager: debugManager,
      factory: self
    )
    viewController.paywallDatabaseId = id
    viewController.modalPresentationStyle = .overFullScreen
    return viewController
  }
}

extension DependencyContainer: VariablesFactory {
  func makeJsonVariables(
    products: [ProductVariable]?,
    computedPropertyRequests: [ComputedPropertyRequest],
    placement: PlacementData?
  ) async -> JSON {
    let templateDeviceDict = await deviceHelper.getDeviceAttributes(
      since: placement,
      computedPropertyRequests: computedPropertyRequests
    )

    return Variables(
      products: products,
      params: placement?.parameters,
      userAttributes: identityManager.userAttributes,
      templateDeviceDictionary: templateDeviceDict
    ).templated()
  }
}

// MARK: - PaywallRequestFactory
extension DependencyContainer: RequestFactory {
  func makePaywallRequest(
    placementData: PlacementData? = nil,
    responseIdentifiers: ResponseIdentifiers,
    overrides: PaywallRequest.Overrides? = nil,
    isDebuggerLaunched: Bool,
    presentationSourceType: String?
  ) -> PaywallRequest {
    return PaywallRequest(
      placementData: placementData,
      responseIdentifiers: responseIdentifiers,
      overrides: overrides ?? PaywallRequest.Overrides(),
      isDebuggerLaunched: isDebuggerLaunched,
      presentationSourceType: presentationSourceType,
      retryCount: 6
    )
  }

  func makePresentationRequest(
    _ presentationInfo: PresentationInfo,
    paywallOverrides: PaywallOverrides? = nil,
    presenter: UIViewController? = nil,
    isDebuggerLaunched: Bool? = nil,
    isPaywallPresented: Bool,
    type: PresentationRequestType
  ) -> PresentationRequest {
    return PresentationRequest(
      presentationInfo: presentationInfo,
      presenter: presenter,
      paywallOverrides: paywallOverrides,
      flags: .init(
        isDebuggerLaunched: isDebuggerLaunched ?? debugManager.isDebuggerLaunched,
        entitlementStatus: entitlementsInfo.$status.eraseToAnyPublisher(),
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
      "X-Platform-Wrapper": deviceHelper.platformWrapper ?? "",
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
      "X-Static-Config-Build-Id": configManager.config?.buildId ?? "",
      "X-Current-Time": Date().isoString,
      "X-Retry-Count": "\(configManager.configRetryCount)",
      "X-Entitlements": Superwall.shared.entitlements.active.map { $0.id }.joined(),
      "Content-Type": "application/json"
    ]
    return headers
  }

  func makeDefaultComponents(host: EndpointHost) -> ApiHostConfig {
    return self.api.getConfig(host: host)
  }
}

// MARK: - Audience Filter Params
extension DependencyContainer: AudienceFilterAttributesFactory {
  func makeAudienceFilterAttributes(
    forPlacement placement: PlacementData?,
    withComputedProperties computedPropertyRequests: [ComputedPropertyRequest]
  ) async -> [String: Any] {
    var userAttributes = identityManager.userAttributes
    userAttributes["isLoggedIn"] = identityManager.isLoggedIn

    let deviceAttributes = await deviceHelper.getDeviceAttributes(
      since: placement,
      computedPropertyRequests: computedPropertyRequests
    )
    return [
      "user": userAttributes,
      "device": deviceAttributes,
      "params": placement?.parameters.dictionaryObject ?? ""
    ]
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
    return StoreTransaction(
      transaction: SK1StoreTransaction(transaction: transaction),
      configRequestId: configManager.config?.requestId ?? "",
      appSessionId: appSessionManager.appSession.id
    )
  }

  @available(iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  func makeStoreTransaction(from transaction: SK2Transaction) async -> StoreTransaction {
    return StoreTransaction(
      transaction: SK2StoreTransaction(transaction: transaction),
      configRequestId: configManager.config?.requestId ?? "",
      appSessionId: appSessionManager.appSession.id
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
    return Set(configManager.triggersByPlacementName.keys)
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
    return purchaseManager.coordinator
  }

  func purchase(product: StoreProduct) async -> PurchaseResult {
    return await purchaseManager.purchase(product: product)
  }

  func restorePurchases() async -> RestorationResult {
    return await purchaseManager.restorePurchases()
  }
}

// MARK: - User Attributes Placement Factory
extension DependencyContainer: UserAttributesPlacementFactory {
  func makeUserAttributesPlacement() -> InternalSuperwallPlacement.Attributes {
    return InternalSuperwallPlacement.Attributes(
      appInstalledAtString: deviceHelper.appInstalledAtString,
      audienceFilterParams: identityManager.userAttributes
    )
  }
}

// MARK: - Receipt Factory
extension DependencyContainer: ReceiptFactory {
  func loadPurchasedProducts() async {
    await receiptManager.loadPurchasedProducts()
  }

  func refreshSK1Receipt() async {
    return await receiptManager.refreshSK1Receipt()
  }

  func isFreeTrialAvailable(for product: StoreProduct) async -> Bool {
    return await receiptManager.isFreeTrialAvailable(for: product)
  }
}

// MARK: - Config Attributes Factory
extension DependencyContainer: ConfigAttributesFactory {
  func makeConfigAttributes() -> InternalSuperwallPlacement.ConfigAttributes {
    let hasSwiftDelegate = delegateAdapter.swiftDelegate != nil
    let hasObjcDelegate = delegateAdapter.objcDelegate != nil

    return InternalSuperwallPlacement.ConfigAttributes(
      options: configManager.options,
      hasExternalPurchaseController: purchaseController.isInternal == false,
      hasDelegate: hasSwiftDelegate || hasObjcDelegate
    )
  }
}
