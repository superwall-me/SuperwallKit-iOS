//
//  File.swift
//  
//
//  Created by Jake Mor on 8/26/21.
//
// swiftlint:disable force_unwrapping file_length type_body_length function_body_length

import UIKit
import Foundation
import StoreKit
import Combine

var primaryColor = UIColor(hexString: "#75FFF1")
var primaryButtonBackgroundColor = UIColor(hexString: "#203133")
var secondaryButtonBackgroundColor = UIColor(hexString: "#44494F")
var lightBackgroundColor = UIColor(hexString: "#181A1E")
var darkBackgroundColor = UIColor(hexString: "#0D0F12")

struct AlertOption {
  var title: String? = ""
  var action: (@MainActor () async -> Void)?
  var style: UIAlertAction.Style = .default
}

@MainActor
final class DebugViewController: UIViewController {
  var logoImageView: UIImageView = {
    let superwallLogo = UIImage(named: "SuperwallKit_superwall_logo", in: Bundle.module, compatibleWith: nil)!
    let imageView = UIImageView(image: superwallLogo)
    imageView.contentMode = .scaleAspectFit
    imageView.backgroundColor = .clear
    imageView.clipsToBounds = true
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.isHidden = false
    return imageView
  }()

  lazy var exitButton: SWBounceButton = {
    let button = SWBounceButton()
    let image = UIImage(named: "SuperwallKit_exit", in: Bundle.module, compatibleWith: nil)!
    button.setImage(image, for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.imageView?.tintColor = UIColor.white.withAlphaComponent(0.5)
    button.addTarget(self, action: #selector(pressedExitButton), for: .primaryActionTriggered)
    return button
  }()

  lazy var consoleButton: SWBounceButton = {
    let button = SWBounceButton()
    let image = UIImage(named: "SuperwallKit_debugger", in: Bundle.module, compatibleWith: nil)!
    button.setImage(image, for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.imageView?.tintColor = UIColor.white.withAlphaComponent(0.5)
    button.addTarget(self, action: #selector(pressedConsoleButton), for: .primaryActionTriggered)
    return button
  }()

  lazy var bottomButton: SWBounceButton = {
    let button = SWBounceButton()
    button.setTitle("Preview", for: .normal)
    button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
    button.backgroundColor = primaryButtonBackgroundColor
    button.setTitleColor(primaryColor, for: .normal)
    button.translatesAutoresizingMaskIntoConstraints = false

    let image = UIImage(named: "SuperwallKit_play_button", in: Bundle.module, compatibleWith: nil)!
    button.titleEdgeInsets = UIEdgeInsets(top: -1, left: 0, bottom: 0, right: 0)
    // button.imageEdgeInsets = UIEdgeInsets(top: 1, left: 5, bottom: -1, right: -3)
    button.setImage(image, for: .normal)
    button.imageView?.tintColor = primaryColor
    button.layer.cornerCurve = .continuous
    button.layer.cornerRadius = 64.0 / 3
    button.addTarget(self, action: #selector(pressedBottomButton), for: .primaryActionTriggered)
    return button
  }()

  lazy var previewPickerButton: SWBounceButton = {
    let button = SWBounceButton()
    button.setTitle("", for: .normal)
    button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
    button.backgroundColor = lightBackgroundColor
    button.setTitleColor(primaryColor, for: .normal)
    button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.imageView?.tintColor = primaryColor
    button.layer.cornerRadius = 10

    let image = UIImage(named: "SuperwallKit_down_arrow", in: Bundle.module, compatibleWith: nil)!
    button.semanticContentAttribute = .forceRightToLeft
    button.setImage(image, for: .normal)
    button.imageView?.tintColor = primaryColor
    button.addTarget(self, action: #selector(pressedPreview), for: .primaryActionTriggered)
    return button
  }()

  private let activityIndicator: UIActivityIndicatorView = {
    let view = UIActivityIndicatorView()
    view.hidesWhenStopped = true
    view.startAnimating()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.style = .large
    view.color = primaryColor
    return view
  }()

  lazy var previewContainerView: SWBounceButton = {
    let button = SWBounceButton()
    button.shouldAnimateLightly = true
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(pressedPreview), for: .primaryActionTriggered)
    return button
  }()

  var paywallDatabaseId: String?
	var paywallIdentifier: String?
  var paywall: Paywall?
  var paywalls: [Paywall] = []
  var previewViewContent: UIView?
  private var cancellable: AnyCancellable?
  private var initialLocaleIdentifier: String?

  private var storeKitManager: StoreKitManager {
    return factory.storeKitManager
  }

  private var network: Network {
    return factory.network
  }

  private var paywallRequestManager: PaywallRequestManager {
    return factory.paywallRequestManager
  }

  private var paywallManager: PaywallManager {
    return factory.paywallManager
  }

  private var debugManager: DebugManager {
    return factory.debugManager
  }
  private let factory: DependencyContainer

  init(factory: DependencyContainer) {
    self.factory = factory
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    initialLocaleIdentifier = Superwall.shared.options.localeIdentifier
    addSubviews()
    Task { await loadPreview() }
  }

  private func addSubviews() {
    view.addSubview(previewContainerView)
    view.addSubview(activityIndicator)
    view.addSubview(logoImageView)
    view.addSubview(consoleButton)
    view.addSubview(exitButton)
    view.addSubview(bottomButton)
    previewContainerView.addSubview(previewPickerButton)
    view.backgroundColor = lightBackgroundColor

    previewContainerView.clipsToBounds = false

    NSLayoutConstraint.activate([
      previewContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      previewContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      previewContainerView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 25),
      previewContainerView.bottomAnchor.constraint(equalTo: bottomButton.topAnchor, constant: -30),

      logoImageView.widthAnchor.constraint(equalTo: view.layoutMarginsGuide.widthAnchor, constant: -10),
      logoImageView.heightAnchor.constraint(equalToConstant: 20),
      logoImageView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 20),
      logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

      consoleButton.centerXAnchor.constraint(equalTo: bottomButton.leadingAnchor),
      consoleButton.centerYAnchor.constraint(equalTo: logoImageView.centerYAnchor),

      exitButton.centerXAnchor.constraint(equalTo: bottomButton.trailingAnchor),
      exitButton.centerYAnchor.constraint(equalTo: logoImageView.centerYAnchor),

      activityIndicator.centerYAnchor.constraint(equalTo: previewContainerView.centerYAnchor),
      activityIndicator.centerXAnchor.constraint(equalTo: previewContainerView.centerXAnchor),

      bottomButton.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),
      bottomButton.heightAnchor.constraint(equalToConstant: 64),
      bottomButton.widthAnchor.constraint(equalTo: view.layoutMarginsGuide.widthAnchor, constant: -40),
      bottomButton.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -10),

      previewPickerButton.centerXAnchor.constraint(equalTo: previewContainerView.centerXAnchor, constant: 0),
      previewPickerButton.heightAnchor.constraint(equalToConstant: 26),
      previewPickerButton.centerYAnchor.constraint(equalTo: previewContainerView.bottomAnchor)
    ])
  }

  func loadPreview() async {
    activityIndicator.startAnimating()
    previewViewContent?.removeFromSuperview()

    if paywalls.isEmpty {
      do {
        paywalls = try await network.getPaywalls()
        await finishLoadingPreview()
      } catch {
        Logger.debug(
          logLevel: .error,
          scope: .debugViewController,
          message: "Failed to Fetch Paywalls",
          error: error
        )
      }
    } else {
      await finishLoadingPreview()
    }
  }

	func finishLoadingPreview() async {
		var paywallId: String?

		if let paywallIdentifier = paywallIdentifier {
			paywallId = paywallIdentifier
		} else if let paywallDatabaseId = paywallDatabaseId {
			paywallId = paywalls.first(where: { $0.databaseId == paywallDatabaseId })?.identifier
			paywallIdentifier = paywallId
    } else {
      return
    }

    do {
      let request = factory.makePaywallRequest(
        eventData: nil,
        responseIdentifiers: .init(paywallId: paywallId),
        overrides: nil,
        isDebuggerLaunched: true,
        presentationSourceType: nil,
        retryCount: 6
      )
      var paywall = try await paywallRequestManager.getPaywall(from: request)

      let productVariables = await storeKitManager.getProductVariables(for: paywall)
      paywall.productVariables = productVariables

      self.paywall = paywall
      self.previewPickerButton.setTitle("\(paywall.name)", for: .normal)
      self.activityIndicator.stopAnimating()
      self.addPaywallPreview()
    } catch {
      Logger.debug(
        logLevel: .error,
        scope: .debugViewController,
        message: "No Paywall Response",
        info: nil,
        error: error
      )
    }
	}

  func addPaywallPreview() {
    guard let paywall = paywall else {
      return
    }

    let child = factory.makePaywallViewController(
      for: paywall,
      withCache: nil,
      delegate: nil
    )
    addChild(child)
    previewContainerView.insertSubview(child.view, at: 0)
    previewViewContent = child.view
    child.didMove(toParent: self)

    child.view.translatesAutoresizingMaskIntoConstraints = false
    child.view.isUserInteractionEnabled = false

    NSLayoutConstraint.activate([
      child.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0),
      child.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1.0),
      child.view.centerYAnchor.constraint(equalTo: previewContainerView.centerYAnchor),
      child.view.centerXAnchor.constraint(equalTo: previewContainerView.centerXAnchor)
    ])

    child.view.clipsToBounds = true
    child.view.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
    child.view.layer.borderWidth = 1.0
    child.view.layer.cornerRadius = 52
    child.view.alpha = 0.0

    let ratio = previewContainerView.frame.size.height / view.frame.size.height

    child.view.transform = CGAffineTransform.identity.scaledBy(
      x: ratio,
      y: ratio
    )
    child.view.layer.cornerCurve = .continuous

    UIView.animate(
      withDuration: 0.25,
      delay: 0.1
    ) {
      child.view.alpha = 1.0
    }
  }

  @objc func pressedPreview() {
    guard let id = paywallDatabaseId else { return }

    let options: [AlertOption] = paywalls.map { paywall in
      var name = paywall.name

      if id == paywall.databaseId {
        name = "\(name) ✓"
      }

      let alert = AlertOption(
        title: name,
        action: { [weak self] in
          self?.paywallDatabaseId = paywall.databaseId
          self?.paywallIdentifier = paywall.identifier
          Task { await self?.loadPreview() }
        },
        style: .default
      )
      return alert
    }

    presentAlert(
      title: nil,
      message: "Your Paywalls",
      options: options,
      on: previewPickerButton
    )
  }

  @objc func pressedExitButton() {
    Task {
      await debugManager.closeDebugger(animated: false)
    }
  }

  @objc func pressedConsoleButton() {
    let releaseVersionNumber = Bundle.main.releaseVersionNumber ?? ""
    let buildVersionNumber = Bundle.main.buildVersionNumber ?? ""
    presentAlert(
      title: nil,
      message: "Superwall v\(sdkVersion) | App v\(releaseVersionNumber) (\(buildVersionNumber))",
      options: [
        AlertOption(title: "Localization", action: showLocalizationPicker, style: .default),
        AlertOption(title: "Templates", action: showConsole, style: .default)
      ],
      on: consoleButton
    )
  }

	func showLocalizationPicker() async {
    let viewController = SWLocalizationViewController { [weak self] identifier in
      Superwall.shared.options.localeIdentifier = identifier
      Task { await self?.loadPreview() }
    }

		let navController = UINavigationController(rootViewController: viewController)
		await present(navController, animated: true)
	}

	func showConsole() async {
    guard let paywall = paywall else {
      Logger.debug(
        logLevel: .error,
        scope: .debugViewController,
        message: "Paywall is nil"
      )
      return
    }
    guard let (productsById, _) = try? await storeKitManager.getProducts(
      withIds: paywall.productIds,
      forPaywall: paywall.name
    ) else {
      return
    }

    var products: [StoreProduct] = []
    for id in paywall.productIds {
      if let product = productsById[id] {
        products.append(product)
      }
    }

    let viewController = SWConsoleViewController(products: products)
    let navController = UINavigationController(rootViewController: viewController)
    navController.modalPresentationStyle = .overFullScreen
    await present(navController, animated: true)
	}

  @objc func pressedBottomButton() {
    presentAlert(
      title: nil,
      message: "Which version?",
      options: [
        AlertOption(
          title: "With Free Trial",
          action: { [weak self] in
            self?.loadAndShowPaywall(freeTrialAvailable: true)
          },
          style: .default
        ),
        AlertOption(
          title: "Without Free Trial",
          action: {  [weak self] in
            self?.loadAndShowPaywall(freeTrialAvailable: false)
          },
          style: .default
        )
      ],
      on: bottomButton
    )
  }

  func loadAndShowPaywall(freeTrialAvailable: Bool = false) {
    guard let paywallIdentifier = paywallIdentifier else {
      return
    }

    bottomButton.setImage(nil, for: .normal)
    bottomButton.showLoading = true

    let inactiveSubscriptionPublisher = CurrentValueSubject<SubscriptionStatus, Never>(SubscriptionStatus.inactive)
      .eraseToAnyPublisher()
    let presentationRequest = factory.makePresentationRequest(
      .fromIdentifier(
        paywallIdentifier,
        freeTrialOverride: freeTrialAvailable
      ),
      paywallOverrides: nil,
      presenter: self,
      isDebuggerLaunched: true,
      subscriptionStatus: inactiveSubscriptionPublisher,
      isPaywallPresented: Superwall.shared.isPaywallPresented,
      type: .presentation
    )


    let publisher = PassthroughSubject<PaywallState, Never>()
    cancellable = publisher
      .receive(on: DispatchQueue.main)
      .sink { state in
        switch state {
        case .presented:
          self.bottomButton.showLoading = false

          let playButton = UIImage(named: "SuperwallKit_play_button", in: Bundle.module, compatibleWith: nil)!
          self.bottomButton.setImage(
            playButton,
            for: .normal
          )
        case .skipped(let reason):
          var errorMessage: String?

          switch reason {
          case .holdout:
            errorMessage = "The user was assigned to a holdout."
          case .noRuleMatch:
            errorMessage = "The user didn't match a rule."
          case .eventNotFound:
            errorMessage = "Couldn't find event."
          case .userIsSubscribed:
            errorMessage = "The user is subscribed."
          }
          self.presentAlert(
            title: "Paywall Skipped",
            message: errorMessage,
            on: self.view
          )
          self.bottomButton.showLoading = false

          let playButton = UIImage(named: "SuperwallKit_play_button", in: Bundle.module, compatibleWith: nil)!
          self.bottomButton.setImage(playButton, for: .normal)
          self.activityIndicator.stopAnimating()
        case .dismissed:
          break
        case .presentationError(let error):
          Logger.debug(
            logLevel: .error,
            scope: .debugViewController,
            message: "Failed to Show Paywall",
            info: nil
          )
          self.presentAlert(
            title: "Presentation Error",
            message: error.safeLocalizedDescription,
            on: self.view
          )
          self.bottomButton.showLoading = false

          let playButton = UIImage(named: "SuperwallKit_play_button", in: Bundle.module, compatibleWith: nil)!
          self.bottomButton.setImage(playButton, for: .normal)
          self.activityIndicator.stopAnimating()
        }
      }

    Task {
      await Superwall.shared.internallyPresent(presentationRequest, publisher)
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    paywallManager.resetCache()
    debugManager.isDebuggerLaunched = false
    Superwall.shared.options.localeIdentifier = initialLocaleIdentifier
  }
}

extension DebugViewController {
  func presentAlert(
    title: String?,
    message: String?,
    options: [AlertOption] = [],
    on sourceView: UIView
  ) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

    for option in options {
      let action = UIAlertAction(
        title: option.title,
        style: option.style
      ) { _ in
        Task {
          await option.action?()
        }
      }
      alertController.addAction(action)
    }

    alertController.popoverPresentationController?.sourceView = sourceView
    alertController.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
    alertController.view.tintColor = .black

    present(
      alertController,
      animated: true
    )
  }
}
