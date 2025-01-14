//
//  File.swift
//  
//
//  Created by Yusuf Tör on 11/10/2022.
//

import Foundation

/// Corresponds to the variables in the paywall editor.
/// Consists of a dictionary of product, user, and device data.
struct Variables: Encodable {
  let user: JSON
  let device: JSON
  let params: JSON
  var products: [ProductVariable] = []

  // These are needed for backwards compatibility with v3 paywalls.
  // MARK: Do not remove otherwise product attributes won't work.
  var primary: JSON = [:]
  var secondary: JSON = [:]
  var tertiary: JSON = [:]

  init(
    products: [ProductVariable]?,
    params: JSON?,
    userAttributes: [String: Any],
    templateDeviceDictionary: [String: Any]?
  ) {
    self.params = params ?? [:]
    self.user = JSON(userAttributes)
    self.device = JSON(templateDeviceDictionary ?? [:])
    guard let products = products else {
      return
    }

    // These are needed for backwards compatibility with v3 paywalls.
    // MARK: Do not remove otherwise product attributes won't work.
    for product in products {
      switch product.name {
      case "primary":
        primary = product.attributes
      case "secondary":
        secondary = product.attributes
      case "tertiary":
        tertiary = product.attributes
      default:
        break
      }
    }

    self.products = products
  }

  func templated() -> JSON {
    let template: [String: Any] = [
      "event_name": "template_variables",
      "variables": dictionary() ?? [:]
    ]
    return JSON(template)
  }
}
