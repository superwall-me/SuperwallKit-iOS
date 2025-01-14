//
//  File.swift
//  
//
//  Created by Yusuf Tör on 22/11/2022.
//

import Foundation

/// The result of tracking a placement.
///
/// Contains the possible cases resulting from tracking a placement.
@objc(SWKPresentationValue)
public enum PresentationValueObjc: Int, Sendable, Equatable {
  /// This placement was not found on the dashboard.
  ///
  /// Please make sure you have added the placement to a campaign on the dashboard and
  /// double check its spelling.
  case placementNotFound

  /// No matching audience was found for this placement so no paywall will be shown.
  case noAudienceMatch

  /// A matching audience was found and this user will be shown a paywall.
  case paywall

  /// A matching audience was found and this user was assigned to a holdout group so will not be shown a paywall.
  case holdout

  /// No view controller could be found to present on.
  case paywallNotAvailable

  /// The user is subscribed.
  ///
  /// This means ``Superwall/subscriptionStatus`` is set to `.active`. If you're
  /// letting Superwall handle subscription-related logic, it will be based on the on-device
  /// receipts. Otherwise it'll be based on the value you've set.
  ///
  /// By default, paywalls do not show to users who are already subscribed. You can override this
  /// behavior in the paywall editor.
  case userIsSubscribed
}

/// Information about the result of tracking a placement.
@objc(SWKPresentationResult)
@objcMembers
public final class PresentationResultObjc: NSObject, Sendable {
  /// The result of registering a placement.
  public let value: PresentationValueObjc

  /// A campaign experiment that was assigned to a user.
  ///
  /// This is non-`nil` when the `result` is a `holdout` or
  /// a `paywall`.
  public let experiment: Experiment?

  init(trackResult: PresentationResult) {
    switch trackResult {
    case .paywall(let experiment):
      self.value = .paywall
      self.experiment = experiment
    case .placementNotFound:
      self.value = .placementNotFound
      self.experiment = nil
    case .holdout(let experiment):
      self.value = .holdout
      self.experiment = experiment
    case .noAudienceMatch:
      self.value = .noAudienceMatch
      self.experiment = nil
    case .paywallNotAvailable:
      self.value = .paywallNotAvailable
      self.experiment = nil
    }
  }
}
