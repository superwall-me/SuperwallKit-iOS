//
//  Variant.swift
//  Paywall
//
//  Created by Yusuf Tör on 02/03/2022.
//

import Foundation

enum Variant: Decodable, Hashable {
  case treatment(VariantTreatment)
  case holdout(VariantHoldout)

  enum Keys: String, CodingKey {
    case variantType
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: Variant.Keys.self)
    let variantType = try values.decode(String.self, forKey: .variantType)
    switch variantType {
    case "HOLDOUT":
      let holdout = try VariantHoldout(from: decoder)
      self = .holdout(holdout)
    case "TREATMENT":
      let treatment = try VariantTreatment(from: decoder)
      self = .treatment(treatment)
    default:
      // TODO: Handle unknowns better
      let holdout = try VariantHoldout(from: decoder)
      self = .holdout(holdout)
    }
  }
}

extension Variant: Stubbable {
  static func stub() -> Variant {
    return Variant.holdout(
      VariantHoldout(variantId: "7")
    )
  }
}
