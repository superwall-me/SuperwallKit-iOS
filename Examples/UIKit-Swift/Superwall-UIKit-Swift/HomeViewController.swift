//
//  HomeViewController.swift
//  SuperwallUIKitExample
//
//  Created by Yusuf Tör on 05/04/2022.
//
// swiftlint:disable force_cast

import UIKit
import SuperwallKit
import Combine

final class HomeViewController: UIViewController {
  @IBOutlet private var subscriptionLabel: UILabel!
  private var subscribedCancellable: AnyCancellable?
  private var cancellable: AnyCancellable?

  static func fromStoryboard() -> HomeViewController {
    let storyboard = UIStoryboard(
      name: "Main",
      bundle: nil
    )
    let controller = storyboard.instantiateViewController(
      withIdentifier: "HomeViewController"
    ) as! HomeViewController

    return controller
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.isNavigationBarHidden = false
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Get notified when active entitlements changed.
    subscribedCancellable = Superwall.shared.entitlements.$status
    .receive(on: DispatchQueue.main)
    .sink { [weak self] status in
      switch status {
      case .unknown:
        self?.subscriptionLabel.text = "Loading active entitlements."
      case .inactive:
        self?.subscriptionLabel.text = "You do not have any active entitlements so the paywall will always show when clicking the button."
      case .active(let entitlements):
        if entitlements.first(where: { $0.id == "Max" }) != nil {
          self?.subscriptionLabel.text = "The \"Max\" entitlement is currently active. The audience filter is configured to not show a paywall because this is the highest level of entitlement a user can have. For the purposes of this app, delete and reinstall the app to clear entitlements."
        } else if entitlements.first(where: { $0.id == "Pro" }) != nil {
          self?.subscriptionLabel.text = "The \"Pro\" entitlement is currently active. The audience filter is configured to show a paywall to allow the user to upgrade to the \"Max\" entitlement, which is the highest level of entitlement a user can have. For the purposes of this app, delete and reinstall the app to clear entitlements."
        }
      }
    }

    navigationItem.hidesBackButton = true
  }

  @IBAction private func logOut() {
    Superwall.shared.reset()
    _ = self.navigationController?.popToRootViewController(animated: true)
  }

  @IBAction private func launchFeature() {
    let handler = PaywallPresentationHandler()
    handler.onDismiss { paywallInfo, paywallResult in
      print("The paywall dismissed. PaywallInfo: \(paywallInfo), PaywallResult: \(paywallResult)")
    }
    handler.onPresent { paywallInfo in
      print("The paywall presented. PaywallInfo:", paywallInfo)
    }
    handler.onError { error in
      print("The paywall presentation failed with error \(error)")
    }
    handler.onSkip { reason in
      switch reason {
      case .holdout(let experiment):
        print("Paywall not shown because user is in a holdout group in Experiment: \(experiment.id)")
      case .noAudienceMatch:
        print("Paywall not shown because user doesn't match any audience.")
      case .placementNotFound:
        print("Paywall not shown because this placement isn't part of a campaign.")
      }
    }

    Superwall.shared.register(placement: "campaign_trigger", handler: handler) {
      // code in here can be remotely configured to execute. Either
      // (1) always after presentation or
      // (2) only if the user pays
      // code is always executed if no paywall is configured to show
      self.presentAlert(
        title: "Feature Launched",
        message: "Wrap your awesome features in register calls like this to remotely paywall your app. You can remotely decide whether these are paid features."
      )
    }
  }

  private func presentAlert(title: String, message: String) {
    let alertController = UIAlertController(
      title: title,
      message: message,
      preferredStyle: .alert
    )
    let okAction = UIAlertAction(title: "OK", style: .default) { _ in }
    alertController.addAction(okAction)
    alertController.popoverPresentationController?.sourceView = view
    self.present(alertController, animated: true)
  }
}
