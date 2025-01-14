//
//  TriggerRule.swift
//  Superwall
//
//  Created by Yusuf Tör on 02/03/2022.
//

import Foundation

struct UnmatchedAudience: Equatable {
  enum Source: String {
    case expression = "EXPRESSION"
    case occurrence = "OCCURRENCE"
  }
  let source: Source
  let experimentId: String
}

extension UnmatchedAudience: Stubbable {
  static func stub() -> UnmatchedAudience {
    return UnmatchedAudience(
      source: .expression,
      experimentId: "1"
    )
  }
}

struct MatchedItem {
  let audience: TriggerRule
  let unsavedOccurrence: TriggerAudienceOccurrence?
}

extension MatchedItem: Stubbable {
  static func stub() -> MatchedItem {
    return MatchedItem(
      audience: .stub(),
      unsavedOccurrence: nil
    )
  }
}

enum TriggerAudienceOutcome: Equatable {
  static func == (lhs: TriggerAudienceOutcome, rhs: TriggerAudienceOutcome) -> Bool {
    switch (lhs, rhs) {
    case let (.match(item1), .match(item2)):
      return item1.audience == item2.audience
        && item1.unsavedOccurrence == item2.unsavedOccurrence
    case let (.noMatch(unmatchedAudience1), .noMatch(unmatchedAudience2)):
      return unmatchedAudience1.source == unmatchedAudience2.source
        && unmatchedAudience1.experimentId == unmatchedAudience2.experimentId
    default:
      return false
    }
  }

  case noMatch(UnmatchedAudience)
  case match(MatchedItem)

  static func noMatch(
    source: UnmatchedAudience.Source,
    experimentId: String
  ) -> TriggerAudienceOutcome {
    return .noMatch(.init(source: source, experimentId: experimentId))
  }

  static func match(
    audience: TriggerRule,
    unsavedOccurrence: TriggerAudienceOccurrence? = nil
  ) -> TriggerAudienceOutcome {
    return .match(.init(audience: audience, unsavedOccurrence: unsavedOccurrence))
  }
}

struct TriggerRule: Codable, Hashable, Equatable {
  var experiment: RawExperiment
  var expression: String?
  var occurrence: TriggerAudienceOccurrence?
  let computedPropertyRequests: [ComputedPropertyRequest]
  var preload: TriggerPreload

  struct TriggerPreload: Codable, Hashable {
    enum TriggerPreloadBehavior: String, Codable {
      case ifTrue = "IF_TRUE"
      case always = "ALWAYS"
      case never = "NEVER"
    }
    let behavior: TriggerPreloadBehavior

    enum CodingKeys: String, CodingKey {
      case behavior
      case requiresReEvaluation
    }

    init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)

      let behavior = try values.decode(TriggerPreloadBehavior.self, forKey: .behavior)
      let requiresReevaluation =
        try values.decodeIfPresent(Bool.self, forKey: .requiresReEvaluation) ?? false
      if requiresReevaluation {
        self.behavior = .always
      } else {
        self.behavior = behavior
      }
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)

      try container.encode(behavior, forKey: .behavior)
      try container.encode(behavior == .always, forKey: .requiresReEvaluation)
    }

    init(behavior: TriggerPreloadBehavior) {
      self.behavior = behavior
    }
  }

  enum CodingKeys: String, CodingKey {
    case experimentGroupId
    case experimentId
    case expressionCel
    case variants
    case occurrence
    case computedPropertyRequests = "computedProperties"
    case preload
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    let experimentId = try values.decode(String.self, forKey: .experimentId)
    let experimentGroupId = try values.decode(String.self, forKey: .experimentGroupId)
    let variants = try values.decode([VariantOption].self, forKey: .variants)

    experiment = RawExperiment(
      id: experimentId,
      groupId: experimentGroupId,
      variants: variants
    )

    expression = try values.decodeIfPresent(String.self, forKey: .expressionCel)
    occurrence = try values.decodeIfPresent(TriggerAudienceOccurrence.self, forKey: .occurrence)
    preload = try values.decode(TriggerPreload.self, forKey: .preload)

    let throwableComputedProperties =
      try values.decodeIfPresent(
        [Throwable<ComputedPropertyRequest>].self,
        forKey: .computedPropertyRequests
      ) ?? []
    computedPropertyRequests = throwableComputedProperties.compactMap { try? $0.result.get() }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(experiment.id, forKey: .experimentId)
    try container.encode(experiment.groupId, forKey: .experimentGroupId)
    try container.encode(experiment.variants, forKey: .variants)
    try container.encodeIfPresent(expression, forKey: .expressionCel)
    try container.encodeIfPresent(occurrence, forKey: .occurrence)
    try container.encode(preload, forKey: .preload)

    if !computedPropertyRequests.isEmpty {
      try container.encode(computedPropertyRequests, forKey: .computedPropertyRequests)
    }
  }

  init(
    experiment: RawExperiment,
    expression: String?,
    occurrence: TriggerAudienceOccurrence? = nil,
    computedPropertyRequests: [ComputedPropertyRequest],
    preload: TriggerPreload
  ) {
    self.experiment = experiment
    self.expression = expression
    self.occurrence = occurrence
    self.computedPropertyRequests = computedPropertyRequests
    self.preload = preload
  }
}

extension TriggerRule: Stubbable {
  static func stub() -> TriggerRule {
    return TriggerRule(
      experiment: RawExperiment(
        id: "1",
        groupId: "2",
        variants: [
          .init(
            type: .holdout,
            id: "3",
            percentage: 20,
            paywallId: nil
          )
        ]
      ),
      expression: nil,
      occurrence: nil,
      computedPropertyRequests: [],
      preload: .init(behavior: .always)
    )
  }
}
