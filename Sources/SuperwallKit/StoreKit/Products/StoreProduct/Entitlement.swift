//
//  File.swift
//  
//
//  Created by Yusuf Tör on 06/08/2024.
//

import Foundation

/// An enum whose types specify the store which the product belongs to.
@objc(SWKEntitlementType)
public enum EntitlementType: Int, Codable, Sendable {
  /// An Apple App Store product.
  case serviceLevel

  private enum CodingKeys: String, CodingKey {
    case serviceLevel = "SERVICE_LEVEL"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawValue = try container.decode(String.self)
    let type = CodingKeys(rawValue: rawValue)
    switch type {
    case .serviceLevel:
      self = .serviceLevel
    case .none:
      throw DecodingError.valueNotFound(
        String.self,
        .init(
          codingPath: [],
          debugDescription: "Unsupported entitlement type."
        )
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .serviceLevel:
      try container.encode(CodingKeys.serviceLevel.rawValue)
    }
  }
}

/// An entitlement that represents a subscription tier in your app.
@objc(SWKEntitlement)
@objcMembers
public final class Entitlement: NSObject, Codable, Sendable {
  /// The identifier for the entitlement.
  public let id: String

  /// The type of entitlement.
  public let type: EntitlementType

  private enum CodingKeys: String, CodingKey {
    case id = "identifier"
    case type
  }

  init(
    id: String,
    type: EntitlementType = .serviceLevel
  ) {
    self.id = id
    self.type = type
  }

  static var `default`: Entitlement {
    return .init(id: "default")
  }

  public init(
    id: String
  ) {
    self.id = id
    self.type = .serviceLevel
  }

  // Override isEqual to define equality based on `id` and `type`
  public override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? Entitlement else {
      return false
    }
    return self.id == other.id && self.type == other.type
  }

  public override var hash: Int {
    var hasher = Hasher()
    hasher.combine(id)
    hasher.combine(type)
    return hasher.finalize()
  }
}

// MARK: - Stubbable
extension Entitlement: Stubbable {
  static func stub() -> Entitlement {
    return Entitlement(
      id: "test",
      type: .serviceLevel
    )
  }
}
