//
//  TemplateDevice.swift
//  Superwall
//
//  Created by Yusuf Tör on 28/02/2022.
//

import Foundation

struct DeviceTemplate: Codable {
  var publicApiKey: String
  var platform: String
  var appUserId: String
  var aliases: [String]
  var vendorId: String
  var appVersion: String
  var appVersionPadded: String
  var osVersion: String
  var deviceModel: String
  var deviceLocale: String
  var preferredLocale: String
  var deviceLanguageCode: String
  var preferredLanguageCode: String
  var regionCode: String
  var preferredRegionCode: String
  var deviceCurrencyCode: String
  var deviceCurrencySymbol: String
  var interfaceType: String
  var timezoneOffset: Int
  var radioType: String
  var interfaceStyle: String
  var isLowPowerModeEnabled: Bool
  var bundleId: String
  var appInstallDate: String
  var isMac: Bool
  var daysSinceInstall: Int
  var minutesSinceInstall: Int
  var daysSinceLastPaywallView: Int?
  var minutesSinceLastPaywallView: Int?
  var totalPaywallViews: Int
  var utcDate: String
  var localDate: String
  var utcTime: String
  var localTime: String
  var utcDateTime: String
  var localDateTime: String
  var isSandbox: String
  var activeEntitlements: Set<String>
  var activeEntitlementObjects: Set<Entitlement>
  var activeProducts: Set<String>
  var entitlementStatus: String
  var isFirstAppOpen: Bool
  var sdkVersion: String
  var sdkVersionPadded: String
  var appBuildString: String
  var appBuildStringNumber: Int?
  var interfaceStyleMode: String
  var ipRegion: String?
  var ipRegionCode: String?
  var ipCountry: String?
  var ipCity: String?
  var ipContinent: String?
  var ipTimezone: String?
  var capabilities: String
  var capabilitiesConfig: JSON
  var platformWrapper: String?
  var platformWrapperVersion: String?

  func toDictionary() -> [String: Any] {
    guard let data = try? JSONEncoder().encode(self) else {
      return [:]
    }
    let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
    if let dictionary = jsonObject.flatMap({ $0 as? [String: Any] }) {
      return dictionary
    } else {
      return [:]
    }
  }
}
