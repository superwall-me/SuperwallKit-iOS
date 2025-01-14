//
//  File.swift
//  
//
//  Created by Yusuf Tör on 05/07/2022.
//

import Foundation

struct TriggerAudienceOccurrence: Codable, Hashable {
  struct RawInterval: Codable {
    enum IntervalType: String, Codable {
      case minutes = "MINUTES"
      case infinity = "INFINITY"

      init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(RawValue.self)
        self = IntervalType(rawValue: rawValue) ?? .infinity
      }

      func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
      }
    }
    let type: IntervalType
    let minutes: Int?
  }

  enum Interval: Decodable, Hashable {
    case infinity
    case minutes(Int)
  }
  let key: String
  var maxCount: Int
  let interval: Interval

  enum CodingKeys: String, CodingKey {
    case key
    case maxCount
    case interval
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    key = try values.decode(String.self, forKey: .key)
    maxCount = try values.decode(Int.self, forKey: .maxCount)

    let interval = try values.decode(RawInterval.self, forKey: .interval)
    if interval.type == .minutes,
      let minutes = interval.minutes {
      self.interval = .minutes(minutes)
    } else {
      self.interval = .infinity
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(key, forKey: .key)
    try container.encode(maxCount, forKey: .maxCount)

    switch interval {
    case .minutes(let minutes):
      let rawInterval = RawInterval(type: .minutes, minutes: minutes)
      try container.encode(rawInterval, forKey: .interval)
    case .infinity:
      let rawInterval = RawInterval(type: .infinity, minutes: nil)
      try container.encode(rawInterval, forKey: .interval)
    }
  }

  init(
    key: String,
    maxCount: Int,
    interval: Interval
  ) {
    self.key = key
    self.maxCount = maxCount
    self.interval = interval
  }
}

extension TriggerAudienceOccurrence: Stubbable {
  static func stub() -> TriggerAudienceOccurrence {
    return TriggerAudienceOccurrence(
      key: "abc",
      maxCount: 10,
      interval: .infinity
    )
  }
}
