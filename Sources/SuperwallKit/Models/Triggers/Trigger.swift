//
//  Trigger.swift
//  Superwall
//
//  Created by Yusuf Tör on 02/03/2022.
//

import Foundation

struct Trigger: Codable, Hashable, Equatable {
  enum CodingKeys: String, CodingKey {
    case audiences = "rules"
    case placementName = "eventName"
  }

  var placementName: String
  var audiences: [TriggerRule]
}

extension Trigger: Stubbable {
  static func stub() -> Trigger {
    return Trigger(
      placementName: "campaign_trigger",
      audiences: []
    )
  }
}
