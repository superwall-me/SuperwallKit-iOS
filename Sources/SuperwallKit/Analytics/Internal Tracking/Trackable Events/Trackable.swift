//
//  File.swift
//  
//
//  Created by Yusuf Tör on 20/04/2022.
//

import Foundation

/// A protocol that defines a placement that is trackable.
protocol Trackable {
  /// The string representation of the name.
  ///
  /// For  a `TrackableSuperwallPlacement`,  this is the raw value of an ``SuperwallPlacement`` assigned to it.
  var rawName: String { get }
  /// Parameters that can be used in audience filters. Do not include $ signs in parameter names as they will be dropped.
  var audienceFilterParams: [String: Any] { get }
  /// Determines whether the placement has the potential to trigger a paywall. Defaults to true.
  var canImplicitlyTriggerPaywall: Bool { get }

  /// Parameters that are marked with a $ when sent back to the server to be recognised as Superwall parameters.
  func getSuperwallParameters() async -> [String: Any]
}
