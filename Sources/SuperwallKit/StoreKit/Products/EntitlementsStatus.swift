//
//  File.swift
//  SuperwallKit
//
//  Created by Yusuf Tör on 25/10/2024.
//

import Foundation

/// An enum representing the entitlement status of the user.
public enum EntitlementStatus: Equatable, Codable {
  /// The entitlement status is unknown.
  case unknown

  /// The user doesn't have any active entitlements.
  case inactive

  /// The user has active entitlements.
  case active(Set<Entitlement>)

  public static func == (lhs: EntitlementStatus, rhs: EntitlementStatus) -> Bool {
    switch (lhs, rhs) {
    case (.unknown, .unknown), (.inactive, .inactive):
      return true
    case let (.active(lhsSet), .active(rhsSet)):
      return lhsSet == rhsSet
    default:
      return false
    }
  }

  func toObjc() -> EntitlementStatusObjc {
    switch self {
    case .active:
      return .active
    case .inactive:
      return .inactive
    case .unknown:
      return .unknown
    }
  }
}

// MARK: - CustomStringConvertible
extension EntitlementStatus: CustomStringConvertible {
  public var description: String {
    switch self {
    case .active:
      return "ACTIVE"
    case .inactive:
      return "INACTIVE"
    case .unknown:
      return "UNKNOWN"
    }
  }
}

/// An enum representing the entitlement status of the user.
@objc(SWKEntitlementStatus)
public enum EntitlementStatusObjc: Int {
  /// The entitlement status is unknown.
  case unknown

  /// The user doesn't have any active entitlements.
  case inactive

  /// The user has active entitlements.
  case active
}

// MARK: - CustomStringConvertible
extension EntitlementStatusObjc: CustomStringConvertible {
  public var description: String {
    switch self {
    case .active:
      return "ACTIVE"
    case .inactive:
      return "INACTIVE"
    case .unknown:
      return "UNKNOWN"
    }
  }
}
