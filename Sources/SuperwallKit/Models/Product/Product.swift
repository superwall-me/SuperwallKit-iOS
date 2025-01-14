//
//  ProductType.swift
//  Superwall
//
//  Created by Yusuf Tör on 01/03/2022.
//

import Foundation

/// The type of product.
@objc(SWKProductType)
public enum ProductType: Int, Codable, Sendable {
  /// The primary product of the paywall.
  case primary

  /// The secondary product of the paywall.
  case secondary

  /// The tertiary product of the paywall.
  case tertiary

  enum InternalProductType: String, Codable {
    case primary
    case secondary
    case tertiary
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    switch self {
    case .primary:
      try container.encode(InternalProductType.primary.rawValue)
    case .secondary:
      try container.encode(InternalProductType.secondary.rawValue)
    case .tertiary:
      try container.encode(InternalProductType.tertiary.rawValue)
    }
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawValue = try container.decode(String.self)
    guard let internalProductType = InternalProductType(rawValue: rawValue) else {
      throw DecodingError.typeMismatch(
        InternalProductType.self,
          .init(
            codingPath: [],
            debugDescription: "Didn't find a primary, secondary, or tertiary product type."
          )
      )
    }
    switch internalProductType {
    case .primary:
      self = .primary
    case .secondary:
      self = .secondary
    case .tertiary:
      self = .tertiary
    }
  }
}

// MARK: - CustomStringConvertible
extension ProductType: CustomStringConvertible {
  public var description: String {
    switch self {
    case .primary:
      return InternalProductType.primary.rawValue
    case .secondary:
      return InternalProductType.secondary.rawValue
    case .tertiary:
      return InternalProductType.tertiary.rawValue
    }
  }
}
