//
//  File.swift
//  SuperwallKit
//
//  Created by Yusuf Tör on 18/10/2024.
//

import Foundation

enum EvaluationResult: Codable {
  case success(PassableValue)
  case failure(String)

  private enum CodingKeys: String, CodingKey {
    case ok = "Ok"
    case error = "Err"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    if let okValue = try? container.decode(PassableValue.self, forKey: .ok) {
      self = .success(okValue)
    } else if let errValue = try? container.decode(String.self, forKey: .error) {
      self = .failure(errValue)
    } else {
      throw DecodingError.typeMismatch(
        EvaluationResult.self,
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Unknown result type"
        )
      )
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case .success(let value):
      try container.encode(value, forKey: .ok)
    case .failure(let message):
      try container.encode(message, forKey: .error)
    }
  }
}
