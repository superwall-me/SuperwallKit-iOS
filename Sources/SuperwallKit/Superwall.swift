import Foundation
import StoreKit
import Combine

/// The primary class for integrating Superwall into your application. It provides access to all its featured via static functions and variables.
@objcMembers
public final class Superwall: NSObject {
  // MARK: - Public Properties
  /// The delegate of the Superwall instance. The delegate is responsible for handling callbacks from the SDK in response to certain events that happen on the paywall.
  @MainActor
  public static var delegate: SuperwallDelegate? {
    get {
      return shared.delegateAdapter.swiftDelegate
    }
    set {
      shared.delegateAdapter.swiftDelegate = newValue
    }
  }

  /// The delegate of the Superwall instance. The delegate is responsible for handling callbacks from the SDK in response to certain events that happen on the paywall.
  @MainActor
  @available(swift, obsoleted: 1.0)
  @objc(delegate)
  public static var objcDelegate: SuperwallDelegateObjc? {
    get {
      return shared.delegateAdapter.objcDelegate
    }
    set {
      shared.delegateAdapter.objcDelegate = newValue
    }
  }

  @MainActor
  let delegateAdapter = SuperwallDelegateAdapter()

  /// Properties stored about the user, set using ``SuperwallKit/Superwall/setUserAttributes(_:)``.
  public static var userAttributes: [String: Any] {
    return shared.identityManager.userAttributes
  }

  /// The presented paywall view controller.
  @MainActor
  public static var presentedViewController: UIViewController? {
    return PaywallManager.shared.presentedViewController
  }

  /// A convenience variable to access and change the paywall options that you passed to ``SuperwallKit/Superwall/configure(apiKey:delegate:options:)-65jyx``.
  public static var options: SuperwallOptions {
    return shared.configManager.options
  }

  /// The ``PaywallInfo`` object of the most recently presented view controller.
  @MainActor
  public static var latestPaywallInfo: PaywallInfo? {
    let presentedPaywallInfo = PaywallManager.shared.presentedViewController?.paywallInfo
    return presentedPaywallInfo ?? shared.latestDismissedPaywallInfo
  }
  /// The current user's id.
  ///
  /// If you haven't called ``SuperwallKit/Superwall/logIn(userId:)`` or ``SuperwallKit/Superwall/createAccount(userId:)``,
  /// this value will return an anonymous user id which is cached to disk
  public static var userId: String {
    return IdentityManager.shared.userId
  }

  /// Indicates whether the user is logged in to Superwall.
  ///
  /// If you have previously called ``SuperwallKit/Superwall/logIn(userId:)`` or
  /// ``SuperwallKit/Superwall/createAccount(userId:)``, this will return true.
  ///
  /// - Returns: A boolean indicating whether the user is logged in or not.
  public static var isLoggedIn: Bool {
    return IdentityManager.shared.isLoggedIn
  }

  // MARK: - Internal Properties
  /// The ``PaywallInfo`` object stored from the latest paywall that was dismissed.
  var latestDismissedPaywallInfo: PaywallInfo?

  /// The shared instance of superwall.
  static var shared = Superwall()

  /// Used to store any track function that doesn't directly return a publisher.
  ///
  /// Cancellables are removed from here on completion of tracking publisher
  static var trackCancellables: Set<AnyCancellable> = []

  /// The publisher from the last paywall presentation.
  var presentationPublisher: AnyCancellable?

  /// The request that triggered the last successful paywall presentation.
  var lastSuccessfulPresentationRequest: PresentationRequest?

  /// The window that presents the paywall.
  var presentingWindow: UIWindow?

  /// Determines whether a paywall has been presented in the session.
  var paywallWasPresentedThisSession = false

  /// The presented paywall view controller.
  @MainActor
  var paywallViewController: PaywallViewController? {
    return PaywallManager.shared.presentedViewController
  }

  /// Determines whether a paywall is being presented.
  @MainActor
  var isPaywallPresented: Bool {
    return paywallViewController != nil
  }

  /// Determines whether the user has an active subscription. Performed on the main thread.
  @MainActor
  var isUserSubscribed: Bool {
    return Superwall.shared.delegateAdapter.isUserSubscribed() == true
  }

  /// The config manager.
  var configManager: ConfigManager = .shared

  /// The identity manager.
  var identityManager: IdentityManager = .shared

  @MainActor
  private let transactionManager = TransactionManager()

  /// Handles restoration logic
  @MainActor
  private lazy var restorationHandler = RestorationHandler()

  // MARK: - Private Functions
  private override init() {}

  private init(
    apiKey: String?,
    swiftDelegate: SuperwallDelegate? = nil,
    objcDelegate: SuperwallDelegateObjc? = nil,
    options: SuperwallOptions? = nil
  ) {
    super.init()
    guard let apiKey = apiKey else {
      return
    }

    // This task runs on a background thread, even if called from a main thread.
    // This is because the function isn't marked to run on the main thread,
    // therefore, we don't need to make this detached.
    Task {
      Storage.shared.configure(apiKey: apiKey)

      // Initialise session events manager and app session manager on main thread
      // _ = SessionEventsManager.shared
      await MainActor.run {
        _ = AppSessionManager.shared
        self.delegateAdapter.configure(
          swiftDelegate: swiftDelegate,
          objcDelegate: objcDelegate
        )
      }

      Storage.shared.recordAppInstall()
      await self.configManager.fetchConfiguration(withOptions: options)
      await self.identityManager.configure()
    }
  }

  // MARK: - Configuration
  /// Configures a shared instance of ``SuperwallKit/Superwall`` for use throughout your app.
  ///
  /// Call this as soon as your app finishes launching in `application(_:didFinishLaunchingWithOptions:)`. For a tutorial on the best practices for implementing the delegate, we recommend checking out our <doc:GettingStarted> article.
  /// - Parameters:
  ///   - apiKey: Your Public API Key that you can get from the Superwall dashboard settings. If you don't have an account, you can [sign up for free](https://superwall.com/sign-up).
  ///   - delegate: A class that conforms to ``SuperwallDelegate``. The delegate methods receive callbacks from the SDK in response to certain events on the paywall.
  ///   - options: A ``SuperwallOptions`` object which allows you to customise the appearance and behavior of the paywall.
  /// - Returns: The newly configured ``SuperwallKit/Superwall`` instance.
  @discardableResult
  public static func configure(
    apiKey: String,
    delegate: SuperwallDelegate? = nil,
    options: SuperwallOptions? = nil
  ) -> Superwall {
    guard Storage.shared.apiKey.isEmpty else {
      Logger.debug(
        logLevel: .warn,
        scope: .superwallCore,
        message: "Superwall.configure called multiple times. Please make sure you only call this once on app launch."
      )
      return shared
    }
    shared = Superwall(
      apiKey: apiKey,
      swiftDelegate: delegate,
      objcDelegate: nil,
      options: options
    )
    return shared
  }

  /// Objective-C only function that configures a shared instance of ``SuperwallKit/Superwall`` for use throughout your app.
  ///
  /// Call this as soon as your app finishes launching in `application(_:didFinishLaunchingWithOptions:)`. For a tutorial on the best practices for implementing the delegate, we recommend checking out our <doc:GettingStarted> article.
  /// - Parameters:
  ///   - apiKey: Your Public API Key that you can get from the Superwall dashboard settings. If you don't have an account, you can [sign up for free](https://superwall.com/sign-up).
  ///   - delegate: A class that conforms to ``SuperwallDelegate``. The delegate methods receive callbacks from the SDK in response to certain events on the paywall.
  ///   - options: A ``SuperwallOptions`` object which allows you to customise the appearance and behavior of the paywall.
  /// - Returns: The newly configured ``SuperwallKit/Superwall`` instance.
  @discardableResult
  @available(swift, obsoleted: 1.0)
  public static func configure(
    apiKey: String,
    delegate: SuperwallDelegateObjc? = nil,
    options: SuperwallOptions? = nil
  ) -> Superwall {
    guard Storage.shared.apiKey.isEmpty else {
      Logger.debug(
        logLevel: .warn,
        scope: .superwallCore,
        message: "Superwall.configure called multiple times. Please make sure you only call this once on app launch."
      )
      return shared
    }
    shared = Superwall(
      apiKey: apiKey,
      swiftDelegate: nil,
      objcDelegate: delegate,
      options: options
    )
    return shared
  }

  // MARK: - Preloading

  /// Preloads all paywalls that the user may see based on campaigns and triggers turned on in your Superwall dashboard.
  ///
  /// To use this, first set ``PaywallOptions/shouldPreload``  to `false` when configuring the SDK. Then call this function when you would like preloading to begin.
  ///
  /// Note: This will not reload any paywalls you've already preloaded via ``SuperwallKit/Superwall/preloadPaywalls(forEvents:)``.
  public static func preloadAllPaywalls() {
    Task.detached(priority: .userInitiated) {
      await shared.configManager.preloadAllPaywalls()
    }
  }

  /// Preloads paywalls for specific event names.
  ///
  /// To use this, first set ``PaywallOptions/shouldPreload``  to `false` when configuring the SDK. Then call this function when you would like preloading to begin.
  ///
  /// Note: This will not reload any paywalls you've already preloaded.
  public static func preloadPaywalls(forEvents eventNames: Set<String>) {
    Task.detached(priority: .userInitiated) {
      await shared.configManager.preloadPaywalls(for: eventNames)
    }
  }

  // MARK: - Deep Links
  /// Handles a deep link sent to your app to open a preview of your paywall.
  ///
  /// You can preview your paywall on-device before going live by utilizing paywall previews. This uses a deep link to render a preview of a paywall you've configured on the Superwall dashboard on your device. See <doc:InAppPreviews> for more.
  public static func handleDeepLink(_ url: URL) {
    Task.detached(priority: .utility) {
      await track(InternalSuperwallEvent.DeepLink(url: url))
    }
    Task {
      await SWDebugManager.shared.handle(deepLinkUrl: url)
    }
  }

  // MARK: - Overrides

	/// Overrides the default device locale for testing purposes.
  ///
  /// You can also preview your paywall in different locales using the in-app debugger. See <doc:InAppPreviews> for more.
	///  - Parameter localeIdentifier: The locale identifier for the language you would like to test.
	public static func localizationOverride(localeIdentifier: String? = nil) {
		LocalizationManager.shared.selectedLocale = localeIdentifier
	}
}

// MARK: - PaywallViewControllerDelegate
extension Superwall: PaywallViewControllerDelegate {
  @MainActor
  func eventDidOccur(
    _ paywallEvent: PaywallWebEvent,
    on paywallViewController: PaywallViewController
  ) async {
    // TODO: log this
    switch paywallEvent {
    case .closed:
      dismiss(
        paywallViewController,
        state: .closed
      )
    case .initiatePurchase(let productId):
      await transactionManager.purchase(
        productId,
        from: paywallViewController
      )
    case .initiateRestore:
      await restorationHandler.tryToRestore(paywallViewController)
    case .openedURL(let url):
      delegateAdapter.willOpenURL(url: url)
    case .openedUrlInSafari(let url):
      delegateAdapter.willOpenURL(url: url)
    case .openedDeepLink(let url):
      delegateAdapter.willOpenDeepLink(url: url)
    case .custom(let string):
      delegateAdapter.handleCustomPaywallAction(withName: string)
    }
  }
}