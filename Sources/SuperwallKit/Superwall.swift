// swiftlint:disable file_length type_body_length

import Combine
import Foundation
import StoreKit

/// The primary class for integrating Superwall into your application. After configuring via
/// ``configure(apiKey:purchaseController:options:completion:)-52tke``, it provides access to
/// all its features via instance functions and variables.
@objcMembers
public final class Superwall: NSObject, ObservableObject {
  // MARK: - Public Properties
  /// The delegate that handles Superwall lifecycle events.
  public var delegate: SuperwallDelegate? {
    get {
      return dependencyContainer.delegateAdapter.swiftDelegate
    }
    set {
      dependencyContainer.delegateAdapter.swiftDelegate = newValue

      let configAttributes = dependencyContainer.makeConfigAttributes()
      Task {
        await track(configAttributes)
      }
    }
  }

  /// A `Task` that is associated with purchasing. This is used to prevent multiple purchases
  /// from occurring.
  private var purchaseTask: Task<Void, Never>?

  /// The Objective-C delegate that handles Superwall lifecycle events.
  @available(swift, obsoleted: 1.0)
  @objc(delegate)
  public var objcDelegate: SuperwallDelegateObjc? {
    get {
      return dependencyContainer.delegateAdapter.objcDelegate
    }
    set {
      dependencyContainer.delegateAdapter.objcDelegate = newValue

      let configAttributes = dependencyContainer.makeConfigAttributes()
      Task {
        await track(configAttributes)
      }
    }
  }

  /// Specifies the detail of the logs returned from the SDK to the console.
  public var logLevel: LogLevel {
    get {
      return options.logging.level
    }
    set {
      options.logging.level = newValue

      let configAttributes = dependencyContainer.makeConfigAttributes()
      Task {
        await track(configAttributes)
      }
    }
  }

  /// Sets the device locale identifier to use when evaluating audience filters and getting localized paywalls.
  ///
  /// This defaults to the `autoupdatingCurrent` locale identifier. However, you can set
  /// this to any locale identifier to override it. E.g. `en_GB`. This is typically used for testing
  /// purposes.
  ///
  /// You can also preview your paywall in different locales using
  /// [In-App Previews](https://docs.superwall.com/docs/in-app-paywall-previews).
  public var localeIdentifier: String? {
    get {
      return options.localeIdentifier
    }
    set {
      options.localeIdentifier = newValue

      let configAttributes = dependencyContainer.makeConfigAttributes()
      Task {
        await track(configAttributes)
      }
    }
  }

  /// Properties stored about the user, set using ``setUserAttributes(_:)-1wql2``.
  public var userAttributes: [String: Any] {
    return dependencyContainer.identityManager.userAttributes
  }

  /// The current user's id.
  ///
  /// If you haven't called ``identify(userId:options:)``,
  /// this value will return an anonymous user id which is cached to disk
  public var userId: String {
    return dependencyContainer.identityManager.userId
  }

  /// Indicates whether the user is logged in to Superwall.
  ///
  /// If you have previously called ``identify(userId:options:)``, this will
  /// return `true`.
  ///
  /// - Returns: A boolean indicating whether the user is logged in or not.
  public var isLoggedIn: Bool {
    return dependencyContainer.identityManager.isLoggedIn
  }

  /// The presented paywall view controller.
  public var presentedViewController: UIViewController? {
    return dependencyContainer.paywallManager.presentedViewController
  }

  /// The ``PaywallInfo`` object of the most recently presented view controller.
  public var latestPaywallInfo: PaywallInfo? {
    let presentedPaywallInfo = dependencyContainer.paywallManager.presentedViewController?.info
    return presentedPaywallInfo ?? presentationItems.paywallInfo
  }

  /// A published property that indicates the configuration status of the SDK.
  ///
  /// This is ``ConfigurationStatus/pending`` when the SDK is yet to finish
  /// configuring. Upon successful configuration, it will change to ``ConfigurationStatus/configured``.
  /// On failure it will change to ``ConfigurationStatus/failed``.
  ///
  /// If you're using Combine or SwiftUI, you can subscribe or bind to this to get notified when the status changes.
  @Published
  public var configurationStatus: ConfigurationStatus = .pending

  /// The ``Entitlement``s tied to the device.
  public var entitlements: EntitlementsInfo {
    return dependencyContainer.entitlementsInfo
  }

  /// The configured shared instance of ``Superwall``.
  ///
  /// - Warning: You must call ``configure(apiKey:purchaseController:options:completion:)-52tke``
  /// to initialize ``Superwall`` before using this.
  @objc(sharedInstance)
  public static var shared: Superwall {
    guard let superwall = superwall else {
      #if DEBUG
        // Code only executes when tests are running in a debug environment.
        // This avoids lots of irrelevent error messages printed to console about Superwall not
        // being configured, which slows down the tests.
        if ProcessInfo.processInfo.arguments.contains("SUPERWALL_UNIT_TESTS") {
          let superwall = Superwall()
          self.superwall = superwall
          return superwall
        }
      #endif
      Logger.debug(
        logLevel: .error,
        scope: .superwallCore,
        message: "Superwall has not been configured. Please call Superwall.configure()"
      )
      assertionFailure("Superwall has not been configured. Please call Superwall.configure()")
      return Superwall()
    }
    return superwall
  }

  /// A variable that is only `true` if ``shared`` is available for use.
  /// Gets set to `true` immediately after
  /// ``configure(apiKey:purchaseController:options:completion:)-52tke`` is
  /// called.
  @DispatchQueueBacked
  public private(set) static var isInitialized = false

  // MARK: - Non-public Properties
  private static var superwall: Superwall?

  /// The presented paywall view controller.
  var paywallViewController: PaywallViewController? {
    return dependencyContainer.paywallManager.presentedViewController
  }

  /// A convenience variable to access and change the paywall options that you passed
  /// to ``configure(apiKey:purchaseController:options:completion:)-52tke``.
  var options: SuperwallOptions {
    return dependencyContainer.configManager.options
  }

  /// Items involved in the presentation of paywalls.
  let presentationItems = PresentationItems()

  /// Determines whether a paywall is being presented.
  public var isPaywallPresented: Bool {
    paywallViewController != nil
  }

  /// Handles all dependencies.
  let dependencyContainer: DependencyContainer

  /// Used to serially execute register calls.
  var previousRegisterTask: Task<Void, Never>?

  // MARK: - Private Functions
  init(dependencyContainer: DependencyContainer = DependencyContainer()) {
    self.dependencyContainer = dependencyContainer
    super.init()
  }

  private convenience init(
    apiKey: String,
    purchaseController: PurchaseController? = nil,
    options: SuperwallOptions? = nil,
    completion: (() -> Void)?
  ) {
    let dependencyContainer = DependencyContainer(
      purchaseController: purchaseController,
      options: options
    )
    self.init(dependencyContainer: dependencyContainer)

    addListeners()

    // This task runs on a background thread, even if called from a main thread.
    // This is because the function isn't marked to run on the main thread,
    // therefore, we don't need to make this detached.
    Task {
      Task {
        #if os(iOS) || os(macOS) || os(visionOS)
          if #available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *) {
            await dependencyContainer.attributionPoster.getAdServicesTokenIfNeeded()
          }
        #endif
      }

      dependencyContainer.storage.configure(apiKey: apiKey)

      dependencyContainer.storage.recordAppInstall(trackPlacement: track)

      async let fetchConfig: () = await dependencyContainer.configManager.fetchConfiguration()
      async let configureIdentity: () = await dependencyContainer.identityManager.configure()

      _ = await (fetchConfig, configureIdentity)

      await track(
        InternalSuperwallPlacement.ConfigAttributes(
          options: dependencyContainer.configManager.options,
          hasExternalPurchaseController: purchaseController != nil,
          hasDelegate: delegate != nil
        )
      )

      await MainActor.run {
        completion?()
      }
    }
  }

  /// Listens to config.
  private func addListeners() {
    dependencyContainer.configManager.configState
      .receive(on: DispatchQueue.main)
      .subscribe(
        Subscribers.Sink(
          receiveCompletion: { _ in },
          receiveValue: { [weak self] state in
            switch state {
            case .retrieving:
              self?.configurationStatus = .pending
            case .failed:
              self?.configurationStatus = .failed
            case .retrieved:
              self?.configurationStatus = .configured
            case .retrying:
              break
            }
          }
        ))
  }

  // MARK: - Configuration
  /// Configures a shared instance of ``Superwall`` for use throughout your app.
  ///
  /// Call this as soon as your app finishes launching in `application(_:didFinishLaunchingWithOptions:)`.
  /// Check out [Configuring the SDK](https://docs.superwall.com/docs/configuring-the-sdk) for information about
  /// how to configure the SDK.
  ///
  /// - Parameters:
  ///   - apiKey: Your Public API Key that you can get from the Superwall dashboard settings. If you don't have
  ///   an account, you can [sign up for free](https://superwall.com/sign-up).
  ///   - purchaseController: An optional object that conforms to ``PurchaseController``. Implement this if you'd
  ///   like to handle all subscription-related logic yourself. You'll need to also set the ``subscriptionStatus`` every time the user's
  ///   entitlements change. You can read more about that in [Purchases and Entitlements](https://docs.superwall.com/docs/advanced-configuration).
  ///   If `nil`, Superwall will handle all subscription-related logic itself.  Defaults to `nil`.
  ///   - options: An optional ``SuperwallOptions`` object which allows you to customise the appearance and behavior
  ///   of the paywall.
  ///   - completion: An optional completion handler that lets you know when Superwall has finished configuring.
  ///   Alternatively, you can subscribe to the published variable ``configurationStatus`` for a more explicit representation of the SDK's configuration status.
  /// - Returns: The configured ``Superwall`` instance.
  @discardableResult
  public static func configure(
    apiKey: String,
    purchaseController: PurchaseController? = nil,
    options: SuperwallOptions? = nil,
    completion: (() -> Void)? = nil
  ) -> Superwall {
    guard superwall == nil else {
      Logger.debug(
        logLevel: .warn,
        scope: .superwallCore,
        message:
          "Superwall.configure called multiple times. Please make sure you only call this once on app launch."
      )
      completion?()
      return shared
    }
    superwall = Superwall(
      apiKey: apiKey,
      purchaseController: purchaseController,
      options: options,
      completion: completion
    )

    Logger.debug(
      logLevel: .debug,
      scope: .superwallCore,
      message: "SDK Version - \(sdkVersion)"
    )

    isInitialized = true

    return shared
  }

  /// Objective-C-only function that configures a shared instance of ``Superwall`` for use throughout your app.
  ///
  /// Call this as soon as your app finishes launching in `application(_:didFinishLaunchingWithOptions:)`. Check out
  /// [Configuring the SDK](https://docs.superwall.com/docs/configuring-the-sdk) for information about how to configure the SDK.
  /// - Parameters:
  ///   - apiKey: Your Public API Key that you can get from the Superwall dashboard settings. If you don't have an account, you
  ///   can [sign up for free](https://superwall.com/sign-up).
  ///   - purchaseController: An optional object that conforms to ``PurchaseControllerObjc``. Implement this if you'd
  ///   like to handle all subscription-related logic yourself. You'll need to also set the ``entitlements`` every time the user's
  ///   entitlements change. You can read more about that in [Purchases and Entitlements](https://docs.superwall.com/docs/advanced-configuration).
  ///   If `nil`, Superwall will handle all subscription-related logic itself.  Defaults to `nil`.
  ///   - options: A ``SuperwallOptions`` object which allows you to customise the appearance and behavior of the paywall.
  ///   - completion: An optional completion handler that lets you know when Superwall has finished configuring.
  /// - Returns: The configured ``Superwall`` instance.
  @discardableResult
  @available(swift, obsoleted: 1.0)
  public static func configure(
    apiKey: String,
    purchaseController: PurchaseControllerObjc? = nil,
    options: SuperwallOptions? = nil,
    completion: (() -> Void)? = nil
  ) -> Superwall {
    return objcConfigure(
      apiKey: apiKey,
      purchaseController: purchaseController,
      options: options,
      completion: completion
    )
  }

  /// Gets an array of all confirmed experiment assignments.
  ///
  /// - Returns: An array of ``ConfirmedAssignment`` objects.
  public func getAssignments() -> [ConfirmedAssignment] {
    let confirmedAssignments = dependencyContainer.storage.getConfirmedAssignments()
    return confirmedAssignments.map {
      ConfirmedAssignment(experimentId: $0.key, variant: $0.value)
    }
  }

  /// Confirms all experiment assignments and returns them in an array.
  ///
  /// This tracks ``SuperwallEvent/confirmAllAssignments`` in the delegate.
  ///
  /// Note that the assignments may be different when a placement is registered due to changes
  /// in user, placement, or device parameters used in audience filters.
  ///
  /// - Returns: An array of ``ConfirmedAssignment`` objects.
  public func confirmAllAssignments() async -> [ConfirmedAssignment] {
    let confirmAllAssignments = InternalSuperwallPlacement.ConfirmAllAssignments()
    await track(confirmAllAssignments)

    guard let triggers = dependencyContainer.configManager.config?.triggers else {
      return []
    }

    let storedAssignments = dependencyContainer.storage.getConfirmedAssignments()
    var assignments = Set(
      storedAssignments.map {
        ConfirmedAssignment(experimentId: $0.key, variant: $0.value)
      })

    for trigger in triggers {
      let eventData = PlacementData(
        name: trigger.placementName,
        parameters: [:],
        createdAt: Date()
      )

      let presentationRequest = dependencyContainer.makePresentationRequest(
        .explicitTrigger(eventData),
        paywallOverrides: nil,
        isPaywallPresented: false,
        type: .confirmAllAssignments
      )

      if let assignment = await confirmAssignments(presentationRequest) {
        assignments.insert(assignment)
      }
    }
    return Array(assignments)
  }

  /// Confirms all experiment assignments and returns them in an array.
  ///
  /// This tracks ``SuperwallEvent/confirmAllAssignments`` in the delegate.
  ///
  /// Note that the assignments may be different when a placement is registered due to changes
  /// in user, placement, or device parameters used in audience filters.
  ///
  /// - Parameter completion: A completion block that accepts an array of ``ConfirmedAssignment`` objects.
  public func confirmAllAssignments(completion: (([ConfirmedAssignment]) -> Void)? = nil) {
    Task {
      let result = await confirmAllAssignments()
      completion?(result)
    }
  }

  /// Objective-C-only function that configures a shared instance of ``Superwall`` for use throughout your app.
  ///
  /// Call this as soon as your app finishes launching in `application(_:didFinishLaunchingWithOptions:)`. Check out
  /// [Configuring the SDK](https://docs.superwall.com/docs/configuring-the-sdk) for information about how to
  /// configure the SDK.
  ///
  /// - Parameters:
  ///   - apiKey: Your Public API Key that you can get from the Superwall dashboard settings. If you don't have an account, you
  ///   can [sign up for free](https://superwall.com/sign-up).
  /// - Returns: The configured ``Superwall`` instance.
  @discardableResult
  @available(swift, obsoleted: 1.0)
  public static func configure(apiKey: String) -> Superwall {
    // Convenience method for objc
    return objcConfigure(apiKey: apiKey)
  }

  private static func objcConfigure(
    apiKey: String,
    purchaseController: PurchaseControllerObjc? = nil,
    options: SuperwallOptions? = nil,
    completion: (() -> Void)? = nil
  ) -> Superwall {
    guard superwall == nil else {
      Logger.debug(
        logLevel: .warn,
        scope: .superwallCore,
        message:
          "Superwall.configure called multiple times. Please make sure you only call this once on app launch."
      )
      completion?()
      return shared
    }

    // Force StoreKit 1 for Objective-C if they're using a purchase controller
    // or observing transactions.
    let options = options ?? SuperwallOptions()
    if purchaseController != nil || options.shouldObservePurchases {
      options.storeKitVersion = .storeKit1
    }

    superwall = Superwall(
      apiKey: apiKey,
      purchaseController: purchaseController.flatMap {
        PurchaseControllerObjcAdapter(objcController: $0)
      },
      options: options,
      completion: completion
    )
    return shared
  }

  /// Gets the ``StoreProduct``s for given product identifiers.
  ///
  /// - Parameter identifiers: A set of product identifiers.
  /// - Returns: A `Set` of ``StoreProduct``s.
  public func products(for identifiers: Set<String>) async -> Set<StoreProduct> {
    // Await config because we must have entitlements before fetching products.
    _ = try? await dependencyContainer.configManager.configState
      .compactMap { $0.getConfig() }
      .throwableAsync()

    let products = try? await dependencyContainer.productsManager.products(identifiers: identifiers)
    return products ?? []
  }

  /// Gets the ``StoreProduct``s for given product identifiers.
  ///
  /// - Parameters:
  ///   - identifiers: A set of product identifiers.
  ///   - completion: A completion block that accepts a `Set` of ``StoreProduct`` objects.
  public func products(
    for identifiers: Set<String>,
    completion: @escaping (Set<StoreProduct>) -> Void
  ) async {
    Task {
      let products = await products(for: identifiers)
      completion(products)
    }
  }

  // MARK: - Preloading

  /// Preloads all paywalls that the user may see based on campaigns and triggers turned on in your Superwall dashboard.
  ///
  /// To use this, first set ``PaywallOptions/shouldPreload``  to `false` when configuring the SDK. Then call this
  /// function when you would like preloading to begin.
  ///
  /// Note: This will not reload any paywalls you've already preloaded via ``preloadPaywalls(forPlacements:)``.
  public func preloadAllPaywalls() {
    Task { [weak self] in
      await self?.dependencyContainer.configManager.preloadAllPaywalls()
    }
  }

  /// Preloads paywalls for specific placements.
  ///
  /// To use this, first set ``PaywallOptions/shouldPreload``  to `false` when configuring the SDK. Then call this
  /// function when you would like preloading to begin.
  ///
  /// Note: This will not reload any paywalls you've already preloaded.
  /// - Parameter placements: A set of names of events whose paywalls you want to preload.
  public func preloadPaywalls(forPlacements placements: Set<String>) {
    Task { [weak self] in
      await self?.dependencyContainer.configManager.preloadPaywalls(for: placements)
    }
  }

  /// **For internal use only. Do not use this.**
  public func setPlatformWrapper(
    _ platformWrapper: String,
    version: String
  ) {
    dependencyContainer.deviceHelper.platformWrapper = platformWrapper
    dependencyContainer.deviceHelper.platformWrapperVersion = version

    Task {
      let deviceAttributes = await dependencyContainer.makeSessionDeviceAttributes()
      let deviceAttributesPlacement = InternalSuperwallPlacement.DeviceAttributes(
        deviceAttributes: deviceAttributes)
      await track(deviceAttributesPlacement)
    }
  }

  /// Sets the user interface style, which overrides the system setting. Set to `nil` to revert
  /// back to using the system setting.
  public func setInterfaceStyle(to interfaceStyle: InterfaceStyle?) {
    dependencyContainer.deviceHelper.interfaceStyleOverride = interfaceStyle
    Task {
      let deviceAttributes = await dependencyContainer.makeSessionDeviceAttributes()
      await Superwall.shared.track(
        InternalSuperwallPlacement.DeviceAttributes(deviceAttributes: deviceAttributes)
      )
    }
  }

  // MARK: - Deep Links
  /// Handles a deep link sent to your app to open a preview of your paywall.
  ///
  /// You can preview your paywall on-device before going live by utilizing paywall previews. This uses a deep link to render a
  /// preview of a paywall you've configured on the Superwall dashboard on your device. See
  /// [In-App Previews](https://docs.superwall.com/docs/in-app-paywall-previews) for
  /// more.
  ///
  /// - Parameters:
  ///   - url: The URL of the deep link.
  /// - Returns: A `Bool` that is `true` if the deep link was handled.
  @discardableResult
  public func handleDeepLink(_ url: URL) -> Bool {
    Task {
      await track(InternalSuperwallPlacement.DeepLink(url: url))
    }
    return dependencyContainer.debugManager.handle(deepLinkUrl: url)
  }

  // MARK: - Paywall Spinner
  /// Toggles the paywall loading spinner on and off.
  ///
  /// Useful for when you want to do display a spinner when doing asynchronous work inside
  /// ``SuperwallDelegate/handleCustomPaywallAction(withName:)-b8fk``.
  /// - Parameters:
  ///   - isHidden: Toggles the paywall loading spinner on and off.
  public func togglePaywallSpinner(isHidden: Bool) {
    Task { @MainActor in
      guard let paywallViewController = dependencyContainer.paywallManager.presentedViewController
      else {
        return
      }
      paywallViewController.togglePaywallSpinner(isHidden: isHidden)
    }
  }

  // MARK: - Reset
  /// Resets the `userId`, on-device paywall assignments, and data stored
  /// by Superwall.
  public func reset() {
    reset(duringIdentify: false)
  }

  /// Asynchronously resets. Presentation of paywalls is suspended until reset completes.
  func reset(duringIdentify: Bool) {
    dependencyContainer.identityManager.reset(duringIdentify: duringIdentify)
    dependencyContainer.storage.reset()
    dependencyContainer.paywallManager.resetCache()
    presentationItems.reset()
    dependencyContainer.configManager.reset()
    Task {
      await Superwall.shared.track(InternalSuperwallPlacement.Reset())

      #if os(iOS) || os(macOS) || os(visionOS)
        if #available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *) {
          await dependencyContainer.attributionPoster.getAdServicesTokenIfNeeded()
        }
      #endif
    }
  }

  // MARK: - External Purchasing

  /// Initiates a purchase of a `SKProduct`.
  ///
  /// Use this function to purchase a ``StoreProduct``, regardless of whether you
  /// have a paywall or not. Superwall will handle the purchase with `StoreKit`
  /// and return the ``PurchaseResult``. You'll see the data associated with the
  /// purchase on the Superwall dashboard.
  ///
  /// - Parameter product: The ``StoreProduct`` you wish to purchase.
  /// - Returns: A ``PurchaseResult``.
  /// - Note: You only need to finish the transaction after this if you're providing a ``PurchaseController``
  /// when configuring the SDK. Otherwise ``Superwall`` will handle this for you.
  public func purchase(_ product: StoreProduct) async -> PurchaseResult {
    return await dependencyContainer.transactionManager.purchase(.purchaseFunc(product))
  }

  /// Initiates a purchase of a `SKProduct`.
  ///
  /// Use this function to purchase any `SKProduct`, regardless of whether you
  /// have a paywall or not. Superwall will handle the purchase with `StoreKit`
  /// and return the ``PurchaseResult``. You'll see the data associated with the
  /// purchase on the Superwall dashboard.
  ///
  /// - Parameter product: The `SKProduct` you wish to purchase.
  /// - Returns: A ``PurchaseResult``.
  /// - Note: You only need to finish the transaction after this if you're providing a ``PurchaseController``
  /// when configuring the SDK. Otherwise ``Superwall`` will handle this for you.
  public func purchase(_ product: SKProduct) async -> PurchaseResult {
    if options.shouldObservePurchases {
      Logger.debug(
        logLevel: .error,
        scope: .superwallCore,
        message: "You cannot make purchases using Superwall.shared.purchase(_:) while the "
          + "SuperwallOption shouldObservePurchases is set to true."
      )
      return .cancelled
    }
    let storeProduct = StoreProduct(sk1Product: product)
    return await dependencyContainer.transactionManager.purchase(.purchaseFunc(storeProduct))
  }

  /// Initiates a purchase of a StoreKit 2 `Product`.
  ///
  /// Use this function to purchase any StoreKit 2 `Product`, regardless of whether you
  /// have a paywall or not. Superwall will handle the purchase with `StoreKit`
  /// and return the ``PurchaseResult``. You'll see the data associated with the
  /// purchase on the Superwall dashboard.
  ///
  /// - Parameter product: The StoreKit 2 `Product` you wish to purchase.
  /// - Returns: A ``PurchaseResult``.
  /// - Note: You only need to finish the transaction after this if you're providing a ``PurchaseController``
  /// when configuring the SDK. Otherwise ``Superwall`` will handle this for you.
  @available(iOS 15.0, *)
  public func purchase(_ product: StoreKit.Product) async -> PurchaseResult {
    let storeProduct = StoreProduct(sk2Product: product)
    return await dependencyContainer.transactionManager.purchase(.purchaseFunc(storeProduct))
  }

  /// Initiates a purchase of a `SKProduct`.
  ///
  /// Use this function to purchase any `SKProduct`, regardless of whether you
  /// have a paywall or not. Superwall will handle the purchase with `StoreKit`
  /// and return the ``PurchaseResult``. You'll see the data associated with the
  /// purchase on the Superwall dashboard.
  ///
  /// - Parameters:
  ///   - product: The `SKProduct` you wish to purchase.
  ///   - completion: A completion block that is called when the purchase completes.
  ///   This accepts a ``PurchaseResult``.
  /// - Note: You only need to finish the transaction after this if you're providing a ``PurchaseController``
  /// when configuring the SDK. Otherwise ``Superwall`` will handle this for you.
  public func purchase(
    _ product: StoreProduct,
    completion: @escaping (PurchaseResult) -> Void
  ) {
    Task {
      let result = await purchase(product)
      await MainActor.run {
        completion(result)
      }
    }
  }

  /// Initiates a purchase of a `SKProduct`.
  ///
  /// Use this function to purchase any `SKProduct`, regardless of whether you
  /// have a paywall or not. Superwall will handle the purchase with `StoreKit`
  /// and return the ``PurchaseResult``. You'll see the data associated with the
  /// purchase on the Superwall dashboard.
  ///
  /// - Parameters:
  ///   - product: The `SKProduct` you wish to purchase.
  ///   - completion: A completion block that is called when the purchase completes.
  ///   This accepts a ``PurchaseResult``.
  /// - Note: You only need to finish the transaction after this if you're providing a ``PurchaseController``
  /// when configuring the SDK. Otherwise ``Superwall`` will handle this for you.
  @available(iOS 15.0, *)
  public func purchase(
    _ product: StoreKit.Product,
    completion: @escaping (PurchaseResult) -> Void
  ) {
    Task {
      let result = await purchase(product)
      await MainActor.run {
        completion(result)
      }
    }
  }

  /// Initiates a purchase of a `SKProduct`.
  ///
  /// Use this function to purchase any `SKProduct`, regardless of whether you
  /// have a paywall or not. Superwall will handle the purchase with `StoreKit`
  /// and return the ``PurchaseResult``. You'll see the data associated with the
  /// purchase on the Superwall dashboard.
  ///
  /// - Parameters:
  ///   - product: The `SKProduct` you wish to purchase.
  ///   - completion: A completion block that is called when the purchase completes.
  ///   This accepts a ``PurchaseResult``.
  /// - Note: You only need to finish the transaction after this if you're providing a ``PurchaseController``
  /// when configuring the SDK. Otherwise ``Superwall`` will handle this for you.
  public func purchase(
    _ product: SKProduct,
    completion: @escaping (PurchaseResult) -> Void
  ) {
    Task {
      let result = await purchase(product)
      await MainActor.run {
        completion(result)
      }
    }
  }

  /// Objective-C-only method. Initiates a purchase of a `SKProduct`.
  ///
  /// Use this function to purchase any `SKProduct`, regardless of whether you
  /// have a paywall or not. Superwall will handle the purchase with `StoreKit`
  /// and return the ``PurchaseResult``. You'll see the data associated with the
  /// purchase on the Superwall dashboard.
  ///
  /// - Parameters:
  ///   - product: The `SKProduct` you wish to purchase.
  ///   - completion: A completion block that is called when the purchase completes.
  ///   This accepts a ``PurchaseResult``.
  /// - Note: You only need to finish the transaction after this if you're providing a ``PurchaseController``
  /// when configuring the SDK. Otherwise ``Superwall`` will handle this for you.
  @available(swift, obsoleted: 1.0)
  @available(iOS 15.0, *)
  public func purchase(
    _ product: StoreKit.Product,
    completion: @escaping (PurchaseResultObjc) -> Void
  ) {
    purchase(product) { result in
      let objcResult = result.toObjc()
      completion(objcResult)
    }
  }

  /// Objective-C-only method. Initiates a purchase of a `SKProduct`.
  ///
  /// Use this function to purchase any `SKProduct`, regardless of whether you
  /// have a paywall or not. Superwall will handle the purchase with `StoreKit`
  /// and return the ``PurchaseResult``. You'll see the data associated with the
  /// purchase on the Superwall dashboard.
  ///
  /// - Parameters:
  ///   - product: The `SKProduct` you wish to purchase.
  ///   - completion: A completion block that is called when the purchase completes.
  ///   This accepts a ``PurchaseResult``.
  /// - Note: You only need to finish the transaction after this if you're providing a ``PurchaseController``
  /// when configuring the SDK. Otherwise ``Superwall`` will handle this for you.
  @available(swift, obsoleted: 1.0)
  public func purchase(
    _ product: SKProduct,
    completion: @escaping (PurchaseResultObjc) -> Void
  ) {
    purchase(product) { result in
      let objcResult = result.toObjc()
      completion(objcResult)
    }
  }

  /// Restores purchases.
  ///
  /// - Note: This could prompt the user to log in to their App Store account, so should only be performed
  /// on request of the user. Typically with a button in settings or near your purchase UI.
  /// - Returns: A ``RestorationResult`` object that defines if the restoration was successful or not.
  /// - Warning: A successful restoration does not mean that the user is subscribed, only that
  /// the restore  did not fail due to some error. If you aren't using a ``PurchaseController``, the user will
  /// see an alert if ``Superwall/subscriptionStatus`` is not ``SubscriptionStatus/active``
  /// after returning this value.
  public func restorePurchases() async -> RestorationResult {
    // Await config because we must have entitlements before restoring.
    _ = try? await dependencyContainer.configManager.configState
      .compactMap { $0.getConfig() }
      .throwableAsync()
    let result = await dependencyContainer.transactionManager.tryToRestore(.external)
    return result
  }

  /// Restores purchases.
  ///
  /// - Note: This could prompt the user to log in to their App Store account, so should only be performed
  /// on request of the user. Typically with a button in settings or near your purchase UI.
  /// - Parameter completion: A completion block that is called when the restoration completes.
  ///   This accepts a ``RestorationResult``.
  /// - Warning: A successful restoration does not mean that the user is subscribed, only that
  /// the restore  did not fail due to some error. If you aren't using a ``PurchaseController``, the user will
  /// see an alert if ``Superwall/subscriptionStatus`` is not ``SubscriptionStatus/active``
  /// after returning this value.
  public func restorePurchases(completion: @escaping (RestorationResult) -> Void) {
    Task {
      let result = await restorePurchases()
      await MainActor.run {
        completion(result)
      }
    }
  }

  /// Objective-C-only method. Restores purchases.
  ///
  /// - Note: This could prompt the user to log in to their App Store account, so should only be performed
  /// on request of the user. Typically with a button in settings or near your purchase UI.
  /// - Parameter completion: A completion block that is called when the restoration completes.
  ///   This accepts a ``RestorationResultObjc``.
  /// - Warning: A successful restoration does not mean that the user is subscribed, only that
  /// the restore  did not fail due to some error. If you aren't using a ``PurchaseController``, the user will
  /// see an alert if ``Superwall/subscriptionStatus`` is not ``SubscriptionStatus/active``
  /// after returning this value.
  @available(swift, obsoleted: 1.0)
  public func restorePurchases(completion: @escaping (RestorationResultObjc) -> Void) {
    restorePurchases { result in
      completion(result.toObjc())
    }
  }
}

// MARK: - PaywallViewControllerDelegate
extension Superwall: PaywallViewControllerEventDelegate {
  @MainActor
  func eventDidOccur(
    _ paywallEvent: PaywallWebEvent,
    on paywallViewController: PaywallViewController
  ) async {
    Logger.debug(
      logLevel: .debug,
      scope: .paywallViewController,
      message: "Event Did Occur",
      info: ["event": paywallEvent]
    )

    switch paywallEvent {
    case .closed:
      dismiss(
        paywallViewController,
        result: .declined,
        closeReason: .manualClose
      )
    case .initiatePurchase(let productId):
      if purchaseTask != nil {
        return
      }
      purchaseTask = Task {
        await dependencyContainer.transactionManager.purchase(
          .internal(productId, paywallViewController)
        )
        purchaseTask = nil
      }
      await purchaseTask?.value
    case .initiateRestore:
      await dependencyContainer.transactionManager.tryToRestore(.internal(paywallViewController))
    case .openedURL(let url):
      dependencyContainer.delegateAdapter.paywallWillOpenURL(url: url)
    case .openedUrlInSafari(let url):
      dependencyContainer.delegateAdapter.paywallWillOpenURL(url: url)
    case .openedDeepLink(let url):
      dependencyContainer.delegateAdapter.paywallWillOpenDeepLink(url: url)
    case .custom(let string):
      dependencyContainer.delegateAdapter.handleCustomPaywallAction(withName: string)
    case let .customPlacement(name: name, params: params):
      Task {
        let paramsDict = params.dictionaryValue
        let customPlacement = InternalSuperwallPlacement.CustomPlacement(
          paywallInfo: paywallViewController.info,
          name: name,
          params: paramsDict
        )
        await Superwall.shared.track(customPlacement)
      }
    }
  }
}
