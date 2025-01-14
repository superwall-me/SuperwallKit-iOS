//
//  File.swift
//  
//
//  Created by Yusuf Tör on 27/09/2022.
//

import Foundation

/// The reason the paywall presentation was skipped.
public enum PaywallSkippedReason: Error, Sendable, Equatable, CustomStringConvertible {
  /// The user was assigned to a holdout.
  ///
  /// A holdout is a control group which you can analyse against
  /// who don't receive any paywall when they match an audience.
  ///
  /// It's useful for testing a paywall's inclusion vs its exclusion.
  case holdout(Experiment)

  /// No audience was matched for this placement.
  case noAudienceMatch

  /// This placement was not found on the dashboard.
  ///
  /// Please make sure you have added the placement to a campaign on the dashboard and
  /// double check its spelling.
  case placementNotFound

  public var description: String {
    switch self {
    case .placementNotFound:
      return "The paywall was skipped because the placement is not part of a campaign."
    case .holdout:
      return "The paywall was skipped because the user is part of a holdout."
    case .noAudienceMatch:
      return "The paywall was skipped because the user doesn't match any audience."
    }
  }

  public static func == (lhs: PaywallSkippedReason, rhs: PaywallSkippedReason) -> Bool {
    switch (lhs, rhs) {
    case (.noAudienceMatch, .noAudienceMatch),
      (.placementNotFound, .placementNotFound):
      return true
    case let (.holdout(experiment1), .holdout(experiment2)):
      return experiment1 == experiment2
    default:
      return false
    }
  }

  func toObjc() -> PaywallSkippedReasonObjc {
    switch self {
    case .holdout:
      return .holdout
    case .noAudienceMatch:
      return .noAudienceMatch
    case .placementNotFound:
      return .placementNotFound
    }
  }

  // MARK: - Graveyard

  /// This event was not found on the dashboard.
  ///
  /// Please make sure you have added the placement to a campaign on the dashboard and
  /// double check its spelling.
  @available(*, unavailable, renamed: "placementNotFound")
  case eventNotFound

  /// No matching rule was found for this event so no paywall will be shown.
  @available(*, unavailable, renamed: "noAudienceMatch")
  case noRuleMatch
}

/// Objective-C-only enum. Specifies the reason the paywall presentation was skipped.
@objc(SWKPaywallSkippedReason)
public enum PaywallSkippedReasonObjc: Int, Error, Sendable, Equatable, CustomStringConvertible {
  /// The user was assigned to a holdout group.
  case holdout

  /// No audience was matched for this placement.
  case noAudienceMatch

  /// This placement was not found on the dashboard.
  ///
  /// Please make sure you have added the placement to a campaign on the dashboard and
  /// double check its spelling.
  case placementNotFound

  /// The presentation wasn't skipped.
  case none

  public var description: String {
    switch self {
    case .placementNotFound:
      return "The paywall was skipped because the placement is not part of a campaign."
    case .holdout:
      return "The paywall was skipped because the user is part of a holdout."
    case .noAudienceMatch:
      return "The paywall was skipped because the user doesn't match any audience."
    case .none:
      return "The paywall was not skipped."
    }
  }
}
