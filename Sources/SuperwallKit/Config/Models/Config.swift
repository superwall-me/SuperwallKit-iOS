//
//  Config.swift
//  Superwall
//
//  Created by Yusuf Tör on 02/03/2022.
//

import Foundation

struct Config: Codable, Equatable {
  var buildId: String
  var triggers: Set<Trigger>
  var paywalls: [Paywall]
  var logLevel: Int
  var locales: Set<String>
  var appSessionTimeout: Milliseconds
  var featureFlags: FeatureFlags
  var preloadingDisabled: PreloadingDisabled
  var requestId: String?
  var attribution: Attribution?
  var products: [Product]
  var allComputedProperties: [ComputedPropertyRequest] {
    return triggers.flatMap {
      $0.audiences.flatMap {
        $0.computedPropertyRequests
      }
    }
  }

  enum CodingKeys: String, CodingKey {
    case requestId
    case buildId
    case triggers = "triggerOptions"
    case paywalls = "paywallResponses"
    case logLevel
    case localization
    case appSessionTimeout = "appSessionTimeoutMs"
    case featureFlags = "toggles"
    case preloadingDisabled = "disablePreload"
    case attribution = "attributionOptions"
    case products = "products"
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)

    buildId = try values.decode(String.self, forKey: .buildId)
    triggers = try values.decode(Set<Trigger>.self, forKey: .triggers)
    paywalls = try values.decode([Paywall].self, forKey: .paywalls)
    logLevel = try values.decode(Int.self, forKey: .logLevel)
    appSessionTimeout = try values.decode(Milliseconds.self, forKey: .appSessionTimeout)
    featureFlags = try FeatureFlags(from: decoder)
    preloadingDisabled = try values.decode(PreloadingDisabled.self, forKey: .preloadingDisabled)
    attribution = try values.decodeIfPresent(Attribution.self, forKey: .attribution)

    let localization = try values.decode(LocalizationConfig.self, forKey: .localization)
    locales = Set(localization.locales.map { $0.locale })
    requestId = try values.decodeIfPresent(String.self, forKey: .requestId)

    let appStoreProductItems = try values.decodeIfPresent(
      [Throwable<Product>].self,
      forKey: .products
    ) ?? []
    products = appStoreProductItems.compactMap { try? $0.result.get() }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(buildId, forKey: .buildId)
    try container.encode(triggers, forKey: .triggers)
    try container.encode(paywalls, forKey: .paywalls)
    try container.encode(logLevel, forKey: .logLevel)
    try container.encode(appSessionTimeout, forKey: .appSessionTimeout)
    try container.encode(preloadingDisabled, forKey: .preloadingDisabled)
    try container.encodeIfPresent(attribution, forKey: .attribution)

    if !products.isEmpty {
      try container.encode(products, forKey: .products)
    }

    let localizationConfig = LocalizationConfig(locales: locales.map { LocalizationConfig.LocaleConfig(locale: $0) })
    try container.encode(localizationConfig, forKey: .localization)

    try featureFlags.encode(to: encoder)
    try container.encodeIfPresent(requestId, forKey: .requestId)
  }

  init(
    buildId: String,
    triggers: Set<Trigger>,
    paywalls: [Paywall],
    logLevel: Int,
    locales: Set<String>,
    appSessionTimeout: Milliseconds,
    featureFlags: FeatureFlags,
    preloadingDisabled: PreloadingDisabled,
    attribution: Attribution,
    products: [Product]
  ) {
    self.buildId = buildId
    self.triggers = triggers
    self.paywalls = paywalls
    self.logLevel = logLevel
    self.locales = locales
    self.appSessionTimeout = appSessionTimeout
    self.featureFlags = featureFlags
    self.preloadingDisabled = preloadingDisabled
    self.attribution = attribution
    self.products = products
  }
}

// MARK: - Stubbable
extension Config: Stubbable {
  static func stub() -> Config {
    return Config(
      buildId: "poWduJZYQbCA8QbWLrjJC",
      triggers: [.stub()],
      paywalls: [.stub()],
      logLevel: 0,
      locales: [],
      appSessionTimeout: 3600000,
      featureFlags: .stub(),
      preloadingDisabled: .stub(),
      attribution: .init(appleSearchAds: .init(enabled: true)),
      products: []
    )
  }
}
