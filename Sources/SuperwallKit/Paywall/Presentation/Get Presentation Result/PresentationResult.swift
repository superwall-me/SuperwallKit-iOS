//
//  File.swift
//  
//
//  Created by Yusuf Tör on 03/03/2023.
//

import Foundation

/// The result of a tracking a placement.
///
/// Contains the possible cases resulting from tracking a placement.
public enum PresentationResult: Sendable, Equatable {
  /// This placement was not found on the dashboard.
  ///
  /// Please make sure you have added the placement to a campaign on the dashboard and
  /// double check its spelling.
  case placementNotFound

  /// No matching audience was found for this placement so no paywall will be shown.
  case noAudienceMatch

  /// A matching audience was found and this user will be shown a paywall.
  ///
  /// - Parameters:
  ///   - experiment: The experiment associated with the placement.
  case paywall(Experiment)

  /// A matching audience was found and this user was assigned to a holdout group so will not be shown a paywall.
  ///
  /// - Parameters:
  ///   - experiment: The experiment associated with the placement.
  case holdout(Experiment)

  /// The paywall is unavailable. This could be because there's no internet, no view controller to
  /// present from, or the paywall is already presented.
  case paywallNotAvailable

  // MARK: - Graveyard
  /// This event was not found on the dashboard.
  ///
  /// Please make sure you have added the placement to a campaign on the dashboard and
  /// double check its spelling.
  @available(*, unavailable, renamed: "placementNotFound")
  case eventNotFound

  /// No matching audience was found for this placement so no paywall will be shown.
  @available(*, unavailable, renamed: "noAudienceMatch")
  case noRuleMatch
}
