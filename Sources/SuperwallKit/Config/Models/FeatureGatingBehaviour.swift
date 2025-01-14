//
//  File.swift
//  
//
//  Created by Jake Mor on 3/22/23.
//

import Foundation

/// An enum whose cases indicate whether the ``Superwall/register(placement:params:handler:feature:)``
/// `feature` block executes or not.
@objc(SWKFeatureGatingBehavior)
public enum FeatureGatingBehavior: Int, Codable, CustomStringConvertible, Sendable {
  /// Prevents the ``Superwall/register(placement:params:handler:feature:)`` `feature`
  /// block from executing on dismiss of the paywall unless the user has an active subscription.
  case gated

  /// Executes the ``Superwall/register(placement:params:handler:feature:)`` `feature`
  /// block on dismiss of the paywall regardless of whether the user has an active subscription or not.
  case nonGated

  enum CodingKeys: String, CodingKey {
    case gated = "GATED"
    case nonGated = "NON_GATED"
  }

  public var description: String {
    switch self {
    case .gated:
      return "GATED"
    case .nonGated:
      return "NON_GATED"
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawValue = try container.decode(String.self)
    let gatingType = CodingKeys(rawValue: rawValue) ?? .nonGated
    switch gatingType {
    case .nonGated:
      self = .nonGated
    case .gated:
      self = .gated
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(description)
  }
}
