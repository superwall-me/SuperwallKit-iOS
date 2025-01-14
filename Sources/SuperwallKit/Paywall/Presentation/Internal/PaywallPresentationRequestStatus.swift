//
//  File.swift
//
//
//  Created by Yusuf Tör on 26/09/2022.
//

import Foundation

/// The status of the paywall request
public enum PaywallPresentationRequestStatus: String {
  /// The request will result in a paywall presentation.
  case presentation

  /// The request won't result in a paywall presentation.
  case noPresentation = "no_presentation"

  /// There was a timeout when trying to get the user's entitlements, identity
  /// or configuration from the server.
  case timeout
}

/// The reason to why the paywall couldn't present.
public enum PaywallPresentationRequestStatusReason: Error, CustomStringConvertible {
  /// Trying to present paywall when debugger is launched.
  case debuggerPresented

  /// There's already a paywall presented.
  case paywallAlreadyPresented

  /// The user is in a holdout group.
  case holdout(Experiment)

  /// No audiences defined in the campaign for the placement matched.
  case noAudienceMatch

  /// The placement provided was not found in any campaign on the dashboard.
  case placementNotFound

  /// There was an error getting the paywall view controller.
  case noPaywallViewController

  /// There isn't a view to present the paywall on.
  case noPresenter

  /// The config hasn't been retrieved from the server in time.
  case noConfig

  /// The entitlements timed out.
  ///
  /// This happens when the ``Superwall/entitlements``
  /// haven't been set within 5 seconds.
  case entitlementsTimeout

  public var description: String {
    switch self {
    case .debuggerPresented:
      return "debugger_presented"
    case .paywallAlreadyPresented:
      return "paywall_already_presented"
    case .holdout:
      return "holdout"
    case .noAudienceMatch:
      return "no_rule_match"
    case .placementNotFound:
      return "event_not_found"
    case .noPaywallViewController:
      return "no_paywall_view_controller"
    case .noPresenter:
      return "no_presenter"
    case .noConfig:
      return "no_config"
    case .entitlementsTimeout:
      return "entitlements_timeout"
    }
  }
}
