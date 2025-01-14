//
//  TriggerInfo.swift
//  Superwall
//
//  Created by Yusuf Tör on 28/02/2022.
//
// swiftlint:disable type_name

import Foundation

/// A campaign experiment that was assigned to a user.
///
/// An experiment is part of a [Campaign Audience](https://docs.superwall.com/docs/campaign-rules)
/// defined in the Superwall dashboard. When an audience is matched, the user is
/// assigned to an experiment, which is a set of paywall variants determined
/// by probabilities. An experiment will result in a user seeing a paywall unless
/// they are in a holdout group.
///
/// To learn more, read [our docs](https://docs.superwall.com/docs/home#how-it-works).
@objc(SWKExperiment)
@objcMembers
public final class Experiment: NSObject, Codable, Sendable {
  public typealias ID = String

  @objc(SWKVariant)
  @objcMembers
  public final class Variant: NSObject, Codable, Sendable {
    @objc(SWKVariantType)
    public enum VariantType: Int, Codable, Hashable, Sendable {
      case treatment
      case holdout

      enum InternalVariantType: String, Codable {
        case treatment = "TREATMENT"
        case holdout = "HOLDOUT"
      }

      public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .treatment:
          try container.encode(InternalVariantType.treatment.rawValue)
        case .holdout:
          try container.encode(InternalVariantType.holdout.rawValue)
        }
      }

      public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        let internalVariantType = InternalVariantType(rawValue: rawValue) ?? .treatment
        switch internalVariantType {
        case .treatment:
          self = .treatment
        case .holdout:
          self = .holdout
        }
      }
    }

    /// The id of the experiment variant.
    public let id: String

    /// The type of variant: holdout or treatment.
    public let type: VariantType

    /// The identifier of the paywall variant. Only valid when the variant `type` is `treatment`.
    public let paywallId: String?

    init(id: String, type: VariantType, paywallId: String?) {
      self.id = id
      self.type = type
      self.paywallId = paywallId
    }

    public override func isEqual(_ object: Any?) -> Bool {
      guard let object = object as? Variant else {
        return false
      }
      return id == object.id
      && type == object.type
      && paywallId == object.paywallId
    }
  }
  /// The id of the experiment.
  public let id: Experiment.ID

  /// The id of the experiment group.
  public let groupId: String

  /// Information about the experiment variant.
  public let variant: Variant

  enum CodingKeys: String, CodingKey {
    case id = "experiment_id"
    case groupId = "trigger_experiment_group_id"
    case variantId = "variant_id"
    case variantType = "variant_type"
    case paywallId = "paywall_identifier"
  }

  init(
    id: String,
    groupId: String,
    variant: Variant
  ) {
    self.id = id
    self.groupId = groupId
    self.variant = variant
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(String.self, forKey: .id)
    groupId = try values.decode(String.self, forKey: .groupId)

    let id = try values.decode(String.self, forKey: .variantId)
    let type = try values.decode(Variant.VariantType.self, forKey: .variantType)
    let paywallId = try values.decode(String.self, forKey: .paywallId)

    variant = Variant(
      id: id,
      type: type,
      paywallId: paywallId
    )
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(groupId, forKey: .groupId)
    try container.encode(variant.id, forKey: .variantId)
    try container.encode(variant.type, forKey: .variantType)
    try container.encodeIfPresent(variant.paywallId, forKey: .paywallId)
  }

  /// A special experiment created for paywalls presented by ID. Only used internally.
  static func presentById(_ id: String) -> Experiment {
    return Experiment(
      id: id,
      groupId: "",
      variant: Variant(id: "", type: .treatment, paywallId: id)
    )
  }
}

// MARK: - Stubbable
extension Experiment: Stubbable {
  static func stub() -> Experiment {
    return .init(
      id: "a",
      groupId: "b",
      variant: .init(
        id: "c",
        type: .treatment,
        paywallId: "d"
      )
    )
  }
}
