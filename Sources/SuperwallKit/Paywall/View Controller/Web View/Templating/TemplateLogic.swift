//
//  File.swift
//
//
//  Created by Yusuf Tör on 11/10/2022.
//

import Foundation

enum TemplateLogic {
  /// Turns input variables into a base64 encoded template to be passed to the
  /// webview.
  static func getBase64EncodedTemplates(
    from paywall: Paywall,
    placement: PlacementData?,
    receiptManager: ReceiptManager,
    factory: VariablesFactory
  ) async -> String {
    let productsTemplate = ProductTemplate(
      eventName: "products",
      products: TemplatingProductItem.create(from: paywall.products)
    )

    // Dynamically set isSubscribed for each product
    var productVariables = paywall.productVariables ?? []

    for product in paywall.products {
      if let index = productVariables.firstIndex(where: { $0.name == product.name }) {
        let isSubscribed = await receiptManager.isSubscribed(to: product.id)
        productVariables[index].attributes["isSubscribed"] = JSON(isSubscribed)
      }
    }

    let variablesTemplate = await factory.makeJsonVariables(
      products: productVariables,
      computedPropertyRequests: paywall.computedPropertyRequests,
      placement: placement
    )

    let freeTrialTemplate = FreeTrialTemplate(
      eventName: "template_substitutions_prefix",
      prefix: paywall.isFreeTrialAvailable ? "freeTrial" : nil
    )

    let encodedTemplates = [
      utf8Encoded(productsTemplate),
      utf8Encoded(variablesTemplate),
      utf8Encoded(freeTrialTemplate)
    ]

    let templatesString = "[" + encodedTemplates.joined(separator: ",") + "]"
    let templatesData = templatesString.data(using: .utf8)

    return templatesData?.base64EncodedString() ?? ""
  }

  private static func utf8Encoded<T: Encodable>(_ input: T) -> String {
    if let data = try? JSONEncoder().encode(input) {
      return String(data: data, encoding: .utf8) ?? "{}"
    } else {
      return "{}"
    }
  }
}
