//
//  File.swift
//
//
//  Created by Yusuf Tör on 14/08/2024.
//

import Foundation

struct ExecutionContext: Codable {
  let variables: PassableMap
  let computed: [String: [PassableValue]]
  let device: [String: [PassableValue]]
  let expression: String
}

struct PassableMap: Codable {
  let map: [String: PassableValue]
}

indirect enum PassableValue: Codable {
  case list([PassableValue])
  case map([String: PassableValue])
  case function(value: String, args: PassableValue?)
  case int(Int)
  case uint(UInt64)
  case float(Double)
  case string(String)
  case bytes(Data)
  case bool(Bool)
  case timestamp(Int64)
  case null

  private enum CodingKeys: String, CodingKey {
    case list, map, function, int, uint, float, string, bytes, bool, timestamp, null
    case type, value, args
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    // Decode the type first
    let type = try container.decode(String.self, forKey: .type)

    switch type {
    case "list":
      let listValue = try container.decode([PassableValue].self, forKey: .value)
      self = .list(listValue)
    case "map":
      let mapValue = try container.decode([String: PassableValue].self, forKey: .value)
      self = .map(mapValue)
    case "function":
      let functionValue = try container.decode(String.self, forKey: .value)
      let args = try container.decodeIfPresent(PassableValue.self, forKey: .args)
      self = .function(value: functionValue, args: args)
    case "int":
      let intValue = try container.decode(Int.self, forKey: .value)
      self = .int(intValue)
    case "uint":
      let uintValue = try container.decode(UInt64.self, forKey: .value)
      self = .uint(uintValue)
    case "float":
      let floatValue = try container.decode(Double.self, forKey: .value)
      self = .float(floatValue)
    case "string":
      let stringValue = try container.decode(String.self, forKey: .value)
      self = .string(stringValue)
    case "bytes":
      let bytesValue = try container.decode(Data.self, forKey: .value)
      self = .bytes(bytesValue)
    case "bool":
      let boolValue = try container.decode(Bool.self, forKey: .value)
      self = .bool(boolValue)
    case "timestamp":
      let timestampValue = try container.decode(Int64.self, forKey: .value)
      self = .timestamp(timestampValue)
    case "null":
      self = .null
    default:
      throw DecodingError.typeMismatch(
        PassableValue.self,
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Unknown type: \(type)"
        )
      )
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    // Add type and value keys for each case
    switch self {
    case .list(let value):
      try container.encode("list", forKey: .type)
      try container.encode(value, forKey: .value)
    case .map(let value):
      try container.encode("map", forKey: .type)
      try container.encode(value, forKey: .value)
    case let .function(value, args):
      try container.encode("function", forKey: .type)
      var functionContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .value)
      try functionContainer.encode(value, forKey: .value)
      try functionContainer.encode(args, forKey: .args)
    case .int(let value):
      try container.encode("int", forKey: .type)
      try container.encode(value, forKey: .value)
    case .uint(let value):
      try container.encode("uint", forKey: .type)
      try container.encode(value, forKey: .value)
    case .float(let value):
      try container.encode("float", forKey: .type)
      try container.encode(value, forKey: .value)
    case .string(let value):
      try container.encode("string", forKey: .type)
      try container.encode(value, forKey: .value)
    case .bytes(let value):
      try container.encode("bytes", forKey: .type)
      try container.encode(value, forKey: .value)
    case .bool(let value):
      try container.encode("bool", forKey: .type)
      try container.encode(value, forKey: .value)
    case .timestamp(let value):
      try container.encode("timestamp", forKey: .type)
      try container.encode(value, forKey: .value)
    case .null:
      try container.encode("null", forKey: .type)
      try container.encodeNil(forKey: .value)
    }
  }
}
