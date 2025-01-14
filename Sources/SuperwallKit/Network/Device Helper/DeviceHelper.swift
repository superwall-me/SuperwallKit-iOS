//
//  File.swift
//
//  Created by Jake Mor on 8/10/21.
//
// swiftlint:disable type_body_length file_length function_body_length

import UIKit
import Foundation
import SystemConfiguration
#if canImport(CoreTelephony)
import CoreTelephony
#endif

class DeviceHelper {
  var locale: String {
    let localeIdentifier = factory.makeLocaleIdentifier()
    return localeIdentifier ?? Locale.autoupdatingCurrent.identifier
  }

  var preferredLocale: String {
    guard let preferredIdentifier = Locale.preferredLanguages.first else {
      return locale
    }
    return Locale(identifier: preferredIdentifier).identifier
  }

  var geoInfo: GeoInfo?

  let appInstalledAtString: String

  private let reachability: SCNetworkReachability?
  var reachabilityFlags: SCNetworkReachabilityFlags? {
    guard let reachability = reachability else {
      return nil
    }
    var flags = SCNetworkReachabilityFlags()
    SCNetworkReachabilityGetFlags(reachability, &flags)

    return flags
  }

  let appVersion = Bundle.main.releaseVersionNumber ?? ""

  let osVersion: String = {
    let systemVersion = ProcessInfo.processInfo.operatingSystemVersion
    return String(
      format: "%ld.%ld.%ld",
      arguments: [systemVersion.majorVersion, systemVersion.minorVersion, systemVersion.patchVersion]
    )
  }()

  let isMac: Bool = {
    var output = false
    if #available(iOS 14.0, *) {
      output = ProcessInfo.processInfo.isiOSAppOnMac
    }
    return output
  }()

  let model: String = {
    UIDevice.modelName
  }()

  let vendorId: String = {
    UIDevice.current.identifierForVendor?.uuidString ?? ""
  }()

  var languageCode: String {
    if #available(iOS 16, *) {
      return Locale.autoupdatingCurrent.language.languageCode?.identifier ?? ""
    } else {
      return Locale.autoupdatingCurrent.languageCode ?? ""
    }
  }

  var preferredLanguageCode: String {
    guard let preferredIdentifier = Locale.preferredLanguages.first else {
      return languageCode
    }
    if #available(iOS 16, *) {
      return Locale(identifier: preferredIdentifier).language.languageCode?.identifier ?? ""
    } else {
      return Locale(identifier: preferredIdentifier).languageCode ?? ""
    }
  }

  private var regionCode: String {
    if #available(iOS 16, *) {
      return Locale.autoupdatingCurrent.language.region?.identifier ?? ""
    } else {
      return Locale.autoupdatingCurrent.regionCode ?? ""
    }
  }

  var preferredRegionCode: String {
    guard let preferredIdentifier = Locale.preferredLanguages.first else {
      return regionCode
    }
    if #available(iOS 16, *) {
      return Locale(identifier: preferredIdentifier).language.region?.identifier ?? ""
    } else {
      return Locale(identifier: preferredIdentifier).regionCode ?? ""
    }
  }

  var currencyCode: String {
    Locale.autoupdatingCurrent.currencyCode ?? ""
  }

  var currencySymbol: String {
    Locale.autoupdatingCurrent.currencySymbol ?? ""
  }

  var secondsFromGMT: String {
    "\(Int(TimeZone.current.secondsFromGMT()))"
  }

  var isFirstAppOpen: Bool {
    return !storage.didTrackFirstSession
  }

  var radioType: String {
    guard let flags = reachabilityFlags else {
      return "No Internet"
    }

    let isReachable = flags.contains(.reachable)
    let isWWAN = flags.contains(.isWWAN)

    if isReachable {
      if isWWAN {
        return "Cellular"
      } else {
        return "Wifi"
      }
    } else {
      return "No Internet"
    }
  }

  var interfaceStyleOverride: InterfaceStyle?

  var interfaceStyle: String {
    if let interfaceStyleOverride = interfaceStyleOverride {
      return interfaceStyleOverride.description
    }
    #if os(visionOS)
    return "Unknown"
    #else
    let style = UIScreen.main.traitCollection.userInterfaceStyle
    switch style {
    case .unspecified:
      return "Unspecified"
    case .light:
      return "Light"
    case .dark:
      return "Dark"
    default:
      return "Unknown"
    }
    #endif
	}

  var platformWrapper: String?

  var platformWrapperVersion: String?

  var isLowPowerModeEnabled: String {
    return ProcessInfo.processInfo.isLowPowerModeEnabled ? "true" : "false"
  }

  let bundleId: String = {
    return Bundle.main.bundleIdentifier ?? ""
  }()

  /// Returns true if built for the simulator or using TestFlight.
  let isSandbox: String = {
    #if targetEnvironment(simulator)
      return "true"
    #else

    guard let url = Bundle.main.appStoreReceiptURL else {
      return "false"
    }

    return "\(url.path.contains("sandboxReceipt"))"
    #endif
  }()

  /// The first URL scheme defined in the Info.plist. Assumes there's only one.
  let urlScheme: String = {
    guard let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] else {
      return ""
    }

    var result = ""
    if let urlTypeDictionary = urlTypes.first,
      let urlSchemes = urlTypeDictionary["CFBundleURLSchemes"] as? [String],
      let urlScheme = urlSchemes.first {
      result = urlScheme
    }

    return result
  }()

  let appBuildString: String = {
    guard let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String else {
      return ""
    }
    return build
  }()

  let interfaceType: String = {
    #if compiler(>=5.9.2)
    if #available(iOS 17.0, *) {
      if UIDevice.current.userInterfaceIdiom == .vision {
        return "vision"
      }
    }
    #endif
    // Ignore the exhaustive message because we need to be able to let devs using lower versions
    // of xcode to build and they don't have vision support.
    switch UIDevice.current.userInterfaceIdiom {
    case .pad:
      return "ipad"
    case .phone:
      return "iphone"
    case .mac:
      return "mac"
    case .carPlay:
      return "carplay"
    case .tv:
      return "tv"
    case .unspecified:
      fallthrough
    @unknown default:
      return "unspecified"
    }
  }()

  private let appInstallDate: Date? = {
    guard let urlToDocumentsFolder = FileManager.default.urls(
      for: .documentDirectory,
      in: .userDomainMask
    ).last else {
      return nil
    }

    guard let installDate = try? FileManager.default.attributesOfItem(
      atPath: urlToDocumentsFolder.path
    )[FileAttributeKey.creationDate] as? Date else {
      return nil
    }
    return installDate
  }()

  private let sdkVersionPadded: String
  private let appVersionPadded: String

  private var daysSinceInstall: Int {
    let fromDate = appInstallDate ?? Date()
    let toDate = Date()
    let numberOfDays = Calendar.current.dateComponents([.day], from: fromDate, to: toDate)
    return numberOfDays.day ?? 0
  }

  private let localDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = Calendar.current.timeZone
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()

  private let utcDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }()

  private let utcTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()

  private let localDateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = Calendar.current.timeZone
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return formatter
  }()

  private let localTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = Calendar.current.timeZone
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()

  private var localDateString: String {
    return localDateFormatter.string(from: Date())
  }

  private var localTimeString: String {
    return localTimeFormatter.string(from: Date())
  }

  private var localDateTimeString: String {
    return localDateTimeFormatter.string(from: Date())
  }

  private var utcDateString: String {
    return utcDateFormatter.string(from: Date())
  }

  private var utcTimeString: String {
    return utcTimeFormatter.string(from: Date())
  }

  private var utcDateTimeString: String {
    return rfc3339DateFormatter.string(from: Date())
  }

  private var minutesSinceInstall: Int {
    let fromDate = appInstallDate ?? Date()
    let toDate = Date()
    let numberOfMinutes = Calendar.current.dateComponents([.minute], from: fromDate, to: toDate)
    return numberOfMinutes.minute ?? 0
  }

  private var daysSinceLastPaywallView: Int? {
    guard let fromDate = storage.get(LastPaywallView.self) else {
      return nil
    }
    let toDate = Date()
    let numberOfDays = Calendar.current.dateComponents([.day], from: fromDate, to: toDate)
    return numberOfDays.day
  }

  private var minutesSinceLastPaywallView: Int? {
    guard let fromDate = storage.get(LastPaywallView.self) else {
      return nil
    }
    let toDate = Date()
    let numberOfMinutes = Calendar.current.dateComponents([.minute], from: fromDate, to: toDate)
    return numberOfMinutes.minute
  }

  private var totalPaywallViews: Int {
    return storage.get(TotalPaywallViews.self) ?? 0
  }

  func getDeviceAttributes(
    since placement: PlacementData?,
    computedPropertyRequests: [ComputedPropertyRequest]
  ) async -> [String: Any] {
    var dictionary = await getTemplateDevice()

    let computedProperties = await getComputedDevicePropertiesSincePlacement(
      placement,
      requests: computedPropertyRequests
    )
    dictionary += computedProperties

    return dictionary
  }

  private func getComputedDevicePropertiesSincePlacement(
    _ placement: PlacementData?,
    requests computedPropertyRequests: [ComputedPropertyRequest]
  ) async -> [String: Any] {
    var output: [String: Any] = [:]

    for computedPropertyRequest in computedPropertyRequests {
      if let value = await storage.coreDataManager.getComputedPropertySincePlacement(
        placement,
        request: computedPropertyRequest
      ) {
        output[computedPropertyRequest.type.prefix + computedPropertyRequest.placementName] = value
      }
    }

    return output
  }

  static func makePaddedVersion(using version: String) -> String {
    // Separate out the "beta" part from the main version.
    let components = version.split(separator: "-")
    if components.isEmpty {
      return ""
    }
    let versionNumber = String(components[0])

    var appendix = ""

    // If there is a "beta" part...
    if components.count > 1 {
      // Separate out the number from the name, e.g. beta.1 -> [beta, 1]
      let appendixComponents = components[1].split(separator: ".")
      appendix = "-" + String(appendixComponents[0])

      var appendixVersion = ""

      // Pad beta number and add to appendix
      if appendixComponents.count > 1 {
        appendixVersion = String(format: "%03d", Int(appendixComponents[1]) ?? 0)
        appendix += "." + appendixVersion
      }
    }

    // Separate out the version numbers.
    let versionComponents = versionNumber.split(separator: ".")
    var newVersion = ""
    if !versionComponents.isEmpty {
      let major = String(format: "%03d", Int(versionComponents[0]) ?? 0)
      newVersion += major
    }
    if versionComponents.count > 1 {
      let minor = String(format: "%03d", Int(versionComponents[1]) ?? 0)
      newVersion += ".\(minor)"
    }
    if versionComponents.count > 2 {
      let patch = String(format: "%03d", Int(versionComponents[2]) ?? 0)
      newVersion += ".\(patch)"
    }

    newVersion += appendix

    return newVersion
  }

  private let capabilitiesConfig: [Capability] = [
    PaywallEventReceiverCapability(),
    MultiplePaywallUrlsCapability(),
    ConfigRefreshCapability(),
    WebViewTextInteractionCapability(),
    ConfigCaching()
  ]

  func getTemplateDevice() async -> [String: Any] {
    let identityInfo = await factory.makeIdentityInfo()
    let aliases = [identityInfo.aliasId]

    let template = DeviceTemplate(
      publicApiKey: storage.apiKey,
      platform: isMac ? "macOS" : "iOS",
      appUserId: identityInfo.appUserId ?? "",
      aliases: aliases,
      vendorId: vendorId,
      appVersion: appVersion,
      appVersionPadded: appVersionPadded,
      osVersion: osVersion,
      deviceModel: model,
      deviceLocale: locale,
      preferredLocale: preferredLocale,
      deviceLanguageCode: languageCode,
      preferredLanguageCode: preferredLanguageCode,
      regionCode: regionCode,
      preferredRegionCode: preferredRegionCode,
      deviceCurrencyCode: currencyCode,
      deviceCurrencySymbol: currencySymbol,
      interfaceType: interfaceType,
      timezoneOffset: Int(TimeZone.current.secondsFromGMT()),
      radioType: radioType,
      interfaceStyle: interfaceStyle,
      isLowPowerModeEnabled: isLowPowerModeEnabled == "true",
      bundleId: bundleId,
      appInstallDate: appInstalledAtString,
      isMac: isMac,
      daysSinceInstall: daysSinceInstall,
      minutesSinceInstall: minutesSinceInstall,
      daysSinceLastPaywallView: daysSinceLastPaywallView,
      minutesSinceLastPaywallView: minutesSinceLastPaywallView,
      totalPaywallViews: totalPaywallViews,
      utcDate: utcDateString,
      localDate: localDateString,
      utcTime: utcTimeString,
      localTime: localTimeString,
      utcDateTime: utcDateTimeString,
      localDateTime: localDateTimeString,
      isSandbox: isSandbox,
      activeEntitlements: Set(entitlementsInfo.active.map { $0.id }),
      activeEntitlementObjects: entitlementsInfo.active,
      activeProducts: await receiptManager.getActiveProductIds(),
      entitlementStatus: entitlementsInfo.status.description,
      isFirstAppOpen: isFirstAppOpen,
      sdkVersion: sdkVersion,
      sdkVersionPadded: sdkVersionPadded,
      appBuildString: appBuildString,
      appBuildStringNumber: Int(appBuildString),
      interfaceStyleMode: interfaceStyleOverride == nil ? "automatic" : "manual",
      ipRegion: geoInfo?.region,
      ipRegionCode: geoInfo?.regionCode,
      ipCountry: geoInfo?.country,
      ipCity: geoInfo?.city,
      ipContinent: geoInfo?.continent,
      ipTimezone: geoInfo?.timezone,
      capabilities: capabilitiesConfig.namesCommaSeparated(),
      capabilitiesConfig: capabilitiesConfig.toJson(),
      platformWrapper: platformWrapper,
      platformWrapperVersion: platformWrapperVersion
    )

    return template.toDictionary()
  }

  private unowned let network: Network
  private unowned let storage: Storage
  private unowned let entitlementsInfo: EntitlementsInfo
  private unowned let receiptManager: ReceiptManager
  private unowned let factory: IdentityInfoFactory & LocaleIdentifierFactory

  init(
    api: Api,
    storage: Storage,
    network: Network,
    entitlementsInfo: EntitlementsInfo,
    receiptManager: ReceiptManager,
    factory: IdentityInfoFactory & LocaleIdentifierFactory
  ) {
    self.storage = storage
    self.network = network
    self.entitlementsInfo = entitlementsInfo
    self.appInstalledAtString = appInstallDate?.isoString ?? ""
    self.receiptManager = receiptManager
    self.factory = factory
      reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, api.base.host)
    self.sdkVersionPadded = Self.makePaddedVersion(using: sdkVersion)
    self.appVersionPadded = Self.makePaddedVersion(using: appVersion)
  }

  func getGeoInfo(maxRetry: Int? = nil) async {
    geoInfo = try? await network.getGeoInfo(maxRetry: maxRetry)
    if let geoInfo = geoInfo {
      storage.save(geoInfo, forType: LatestGeoInfo.self)
    }
  }
}
