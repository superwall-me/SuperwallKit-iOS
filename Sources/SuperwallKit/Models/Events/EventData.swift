//
//  PlacementData.swift
//  Superwall
//
//  Created by Yusuf Tör on 02/03/2022.
//

import Foundation

/// Data associated with a placement. This could be any sort of placement (user initiated, superwall), which may or may not trigger a paywall.
struct PlacementData: Codable, Equatable {
  /// SDK generated ID for placement
  var id = UUID().uuidString

  /// The name of the placement
  var name: String

  /// Parameters associated with the placement
  var parameters: JSON

  /// When the placement was created
  var createdAt: Date

  /// A `JSON` version of `PlacementData`
  var jsonData: JSON {
    return [
      "event_id": JSON(id),
      "event_name": JSON(name),
      "parameters": parameters,
      "created_at": JSON(createdAt.isoString)
    ]
  }
}

extension PlacementData: Stubbable {
  static func stub() -> PlacementData {
    return PlacementData(
      name: "opened_application",
      parameters: [:],
      createdAt: Date()
    )
  }
}
