//
//  File.swift
//  
//
//  Created by Yusuf Tör on 02/07/2024.
//

import Foundation

extension Array where Element == Capability {
  func toJson() -> JSON {
    let encoder = JSONEncoder()
    var result: [[String: Any]] = []

    for capability in self {
      do {
        let data = try encoder.encode(capability)
        if let json = try JSONSerialization.jsonObject(
          with: data,
          options: []
        ) as? [String: Any] {
          result.append(json)
        }
      } catch {
        Logger.debug(
          logLevel: .debug,
          scope: .placements,
          message: "Could not encode capability \(capability.name)"
        )
      }
    }

    return JSON(result)
  }
}

extension Array where Element == Capability {
  func namesCommaSeparated() -> String {
    return self.map { $0.name }.joined(separator: ",")
  }
}
