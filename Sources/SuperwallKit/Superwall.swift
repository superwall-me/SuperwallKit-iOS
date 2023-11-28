// swiftlint:disable file_length

import Foundation
import StoreKit
import Combine

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
    }
  }

  /// Specifies the detail of the logs returned from the SDK to the console.
  public var logLevel: LogLevel {
    get {
      return options.logging.level
    }
    set {
      options.logging.level = newValue
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

  /// A published property that indicates the subscription status of the user.
  ///
  /// If you're handling subscription-related logic yourself, you must set this
  /// property whenever the subscription status of a user changes.
  /// However, if you're letting Superwall handle subscription-related logic, its value will
  /// be synced with the user's purchases on device.
  ///
  /// Paywalls will not show until the subscription status has been established.
  /// On first install, it's value will default to `.unknown`. Afterwards, it'll default
  /// to its cached value.
  ///
  /// If you're using Combine or SwiftUI, you can subscribe or bind to it to get
  /// notified whenever the user's subscription status changes.
  ///
  /// Otherwise, you can check the delegate function
  /// ``SuperwallDelegate/subscriptionStatusDidChange(to:)-24teh``
  /// to receive a callback with the new value every time it changes.
  ///
  /// To learn more, see [Purchases and Subscription Status](https://docs.superwall.com/docs/advanced-configuration).
  @Published
  public var subscriptionStatus: SubscriptionStatus = .unknown

  /// A published property that is `true` when Superwall has finished configuring via
  /// ``configure(apiKey:purchaseController:options:completion:)-52tke``.
  ///
  /// If you're using Combine or SwiftUI, you can subscribe or bind to this to get
  /// notified when configuration has completed.
  ///
  /// Alternatively, you can use the completion handler from
  /// ``configure(apiKey:purchaseController:options:completion:)-52tke``.
  @Published
  public var isConfigured = false

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

    subscriptionStatus = dependencyContainer.storage.get(ActiveSubscriptionStatus.self) ?? .unknown

    addListeners()

    // This task runs on a background thread, even if called from a main thread.
    // This is because the function isn't marked to run on the main thread,
    // therefore, we don't need to make this detached.
    Task {
      dependencyContainer.storage.configure(apiKey: apiKey)

      dependencyContainer.storage.recordAppInstall(trackEvent: track)

      async let fetchConfig: () = await dependencyContainer.configManager.fetchConfiguration()
      async let configureIdentity: () = await dependencyContainer.identityManager.configure()

      _ = await (fetchConfig, configureIdentity)

      await MainActor.run {
        completion?()
      }
    }
  }

  /// Listens to config and the subscription status
  private func addListeners() {
    dependencyContainer.configManager.hasConfig
      .receive(on: DispatchQueue.main)
      .subscribe(Subscribers.Sink(
        receiveCompletion: { _ in },
        receiveValue: { [weak self] _ in
          self?.isConfigured = true
        }
      ))

    $subscriptionStatus
      .removeDuplicates()
      .dropFirst()
      .eraseToAnyPublisher()
      .receive(on: DispatchQueue.main)
      .subscribe(Subscribers.Sink(
        receiveCompletion: { _ in },
        receiveValue: { [weak self] newValue in
          guard let self = self else {
            return
          }
          self.dependencyContainer.storage.save(newValue, forType: ActiveSubscriptionStatus.self)

          Task {
            await self.dependencyContainer.delegateAdapter.subscriptionStatusDidChange(to: newValue)
            let event = InternalSuperwallEvent.SubscriptionStatusDidChange(subscriptionStatus: newValue)
            await self.track(event)
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
  ///   subscription status changes. You can read more about that in [Purchases and Subscription Status](https://docs.superwall.com/docs/advanced-configuration).
  ///   If `nil`, Superwall will handle all subscription-related logic itself.  Defaults to `nil`.
  ///   - options: An optional ``SuperwallOptions`` object which allows you to customise the appearance and behavior
  ///   of the paywall.
  ///   - completion: An optional completion handler that lets you know when Superwall has finished configuring.
  ///   Alternatively, you can subscribe to the published variable ``isConfigured``.
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
        message: "Superwall.configure called multiple times. Please make sure you only call this once on app launch."
      )
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
  ///   like to handle all subscription-related logic yourself. You'll need to also set the ``subscriptionStatus`` every time the user's
  ///   subscription status changes. You can read more about that in [Purchases and Subscription Status](https://docs.superwall.com/docs/advanced-configuration).
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
        message: "Superwall.configure called multiple times. Please make sure you only call this once on app launch."
      )
      return shared
    }
    superwall = Superwall(
      apiKey: apiKey,
      purchaseController: purchaseController.flatMap({ PurchaseControllerObjcAdapter(objcController: $0) }),
      options: options,
      completion: completion
    )
    return shared
  }

  // MARK: - Preloading

  /// Preloads all paywalls that the user may see based on campaigns and triggers turned on in your Superwall dashboard.
  ///
  /// To use this, first set ``PaywallOptions/shouldPreload``  to `false` when configuring the SDK. Then call this
  /// function when you would like preloading to begin.
  ///
  /// Note: This will not reload any paywalls you've already preloaded via ``preloadPaywalls(forEvents:)``.
  public func preloadAllPaywalls() {
    Task { [weak self] in
      await self?.dependencyContainer.configManager.preloadAllPaywalls()
    }
  }

  /// Preloads paywalls for specific event names.
  ///
  /// To use this, first set ``PaywallOptions/shouldPreload``  to `false` when configuring the SDK. Then call this
  /// function when you would like preloading to begin.
  ///
  /// Note: This will not reload any paywalls you've already preloaded.
  /// - Parameters:
  ///   - eventNames: A set of names of events whose paywalls you want to preload.
  public func preloadPaywalls(forEvents eventNames: Set<String>) {
    Task { [weak self] in
      await self?.dependencyContainer.configManager.preloadPaywalls(for: eventNames)
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
      await track(InternalSuperwallEvent.DeepLink(url: url))
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
      guard let paywallViewController = dependencyContainer.paywallManager.presentedViewController else {
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
          productId,
          from: paywallViewController
        )
        purchaseTask = nil
      }
      await purchaseTask?.value
    case .initiateRestore:
      await dependencyContainer.transactionManager.tryToRestore(from: paywallViewController)
    case .openedURL(let url):
      dependencyContainer.delegateAdapter.paywallWillOpenURL(url: url)
    case .openedUrlInSafari(let url):
      dependencyContainer.delegateAdapter.paywallWillOpenURL(url: url)
    case .openedDeepLink(let url):
      dependencyContainer.delegateAdapter.paywallWillOpenDeepLink(url: url)
    case .custom(let string):
      dependencyContainer.delegateAdapter.handleCustomPaywallAction(withName: string)
    }
  }
}
