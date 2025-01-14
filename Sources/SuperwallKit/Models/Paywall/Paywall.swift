//
//  Paywall.swift
//  Superwall
//
//  Created by Yusuf Tör on 28/02/2022.
//
// swiftlint:disable function_body_length type_body_length file_length

import UIKit

struct Paywalls: Decodable {
  var paywalls: [Paywall]
}

struct Paywall: Codable {
  /// The id of the paywall in the database.
  var databaseId: String

  /// The identifier of the paywall
  var identifier: String

  /// The name of the paywall
  let name: String

  /// The key used to cache the paywall object.
  var cacheKey: String

  /// The build ID of the Superwall configuration.
  let buildId: String

  /// The URL of the paywall webpage
  var url: URL

  /// An array of potential URLs to load the paywall from.
  let urlConfig: WebViewURLConfig

  /// Contains the website modifications that are made on the paywall editor to be accepted
  /// by the webview.
  let htmlSubstitutions: String

  let presentation: PaywallPresentationInfo

  let darkBackgroundColorHex: String?
  let darkBackgroundColor: UIColor?

  let backgroundColorHex: String
  let backgroundColor: UIColor

  let computedPropertyRequests: [ComputedPropertyRequest]

  /// Indicates whether the caching of the paywall is enabled or not.
  let onDeviceCache: OnDeviceCaching

  /// A surveys to potentially show when an action happens in the paywall.
  var surveys: [Survey]

  /// An ordered list of products associated with the paywall.
  var products: [Product] {
    didSet {
      productIds = products.map { $0.id }
    }
  }

  /// Indicates whether scrolling is enabled on the webview.
  var isScrollEnabled: Bool

  // MARK: - Added by client

  var responseLoadingInfo: LoadingInfo
  var webviewLoadingInfo: LoadingInfo
  var shimmerLoadingInfo: LoadingInfo
  var productsLoadingInfo: LoadingInfo

  /// An array of the ids of paywall products.
  ///
  /// This is set on init and whenever products are updated.
  var productIds: [String]

  /// The experiment associated with the paywall.
  var experiment: Experiment?

  /// An list of product attributes associated with the paywall.
  ///
  /// Each contains a product type and their attributes.
  var productVariables: [ProductVariable]? = []

  /// The paywall.js version being used. Added when the website fires `onReady`.
  var paywalljsVersion: String?

  /// Determines whether a free trial is available or not.
  var isFreeTrialAvailable = false

  /// The source of the presentation request. Either 'implicit', 'getPaywall', 'register'.
  var presentationSourceType: String?

  /// The reason for closing the paywall.
  var closeReason: PaywallCloseReason = .none

  /// Determines whether a paywall executes the
  /// ``Superwall/register(placement:params:handler:feature:)`` feature block if the
  /// user does not purchase.
  var featureGating: FeatureGatingBehavior

  /// The local notifications for the paywall, e.g. to notify the user of free trial expiry.
  var localNotifications: [LocalNotification]

  /// A listing of all the files referenced in a paywall to be able to preload the whole
  /// paywall into a web archive.
  let manifest: ArchiveManifest?

  /// Indicates whether the manifest should be used.
  var isUsingManifest: Bool {
    guard let manifest = manifest else {
      return false
    }
    if manifest.use == .never {
      return false
    }
    return true
  }

  enum CodingKeys: String, CodingKey {
    case id
    case identifier
    case name
    case cacheKey
    case buildId
    case url
    case urlConfig
    case htmlSubstitutions = "paywalljsEvent"
    case presentationStyle = "presentationStyleV2"
    case presentationCondition
    case presentationDelay
    case backgroundColorHex
    case darkBackgroundColorHex
    case products = "productsV2"
    case featureGating
    case onDeviceCache
    case localNotifications
    case computedPropertyRequests = "computedProperties"
    case surveys
    case manifest
    case isScrollEnabled

    case responseLoadStartTime
    case responseLoadCompleteTime
    case responseLoadFailTime

    case webViewLoadStartTime
    case webViewLoadCompleteTime
    case webViewLoadFailTime

    case productsLoadStartTime
    case productsLoadCompleteTime
    case productsLoadFailTime

    case shimmerLoadStartTime
    case shimmerLoadCompleteTime
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    databaseId = try values.decode(String.self, forKey: .id)
    identifier = try values.decode(String.self, forKey: .identifier)
    name = try values.decode(String.self, forKey: .name)
    cacheKey = try values.decode(String.self, forKey: .cacheKey)
    buildId = try values.decode(String.self, forKey: .buildId)
    url = try values.decode(URL.self, forKey: .url)
    urlConfig = try values.decode(WebViewURLConfig.self, forKey: .urlConfig)
    htmlSubstitutions = try values.decode(String.self, forKey: .htmlSubstitutions)

    let throwableSurveys = try values.decodeIfPresent(
      [Throwable<Survey>].self,
      forKey: .surveys
    ) ?? []
    surveys = throwableSurveys.compactMap { try? $0.result.get() }

    let presentationStyle = try values.decode(PaywallPresentationStyle.self, forKey: .presentationStyle)
    let presentationDelay = try values.decode(Int.self, forKey: .presentationDelay)

    presentation = PaywallPresentationInfo(
      style: presentationStyle,
      delay: presentationDelay
    )

    backgroundColorHex = try values.decode(String.self, forKey: .backgroundColorHex)
    let backgroundColor = UIColor(hexString: backgroundColorHex)
    self.backgroundColor = backgroundColor

    if let darkBackgroundColorHex = try values.decodeIfPresent(String.self, forKey: .darkBackgroundColorHex) {
      let darkBackgroundColor = UIColor(hexString: darkBackgroundColorHex)
      self.darkBackgroundColor = darkBackgroundColor
      self.darkBackgroundColorHex = darkBackgroundColorHex
    } else {
      self.darkBackgroundColor = nil
      self.darkBackgroundColorHex = nil
    }

    let appStoreProductItems = try values.decodeIfPresent(
      [Throwable<Product>].self,
      forKey: .products
    ) ?? []
    products = appStoreProductItems.compactMap { try? $0.result.get() }

    productIds = products.map { $0.id }

    let responseLoadStartTime = try values.decodeIfPresent(Date.self, forKey: .responseLoadStartTime)
    let responseLoadCompleteTime = try values.decodeIfPresent(Date.self, forKey: .responseLoadCompleteTime)
    let responseLoadFailTime = try values.decodeIfPresent(Date.self, forKey: .responseLoadFailTime)
    responseLoadingInfo = LoadingInfo(
      startAt: responseLoadStartTime,
      endAt: responseLoadCompleteTime,
      failAt: responseLoadFailTime
    )

    let webviewLoadStartTime = try values.decodeIfPresent(Date.self, forKey: .webViewLoadStartTime)
    let webviewLoadCompleteTime = try values.decodeIfPresent(Date.self, forKey: .webViewLoadCompleteTime)
    let webviewLoadFailTime = try values.decodeIfPresent(Date.self, forKey: .webViewLoadFailTime)
    webviewLoadingInfo = LoadingInfo(
      startAt: webviewLoadStartTime,
      endAt: webviewLoadCompleteTime,
      failAt: webviewLoadFailTime
    )

    let shimmerLoadStartTime = try values.decodeIfPresent(Date.self, forKey: .shimmerLoadStartTime)
    let shimmerLoadCompleteTime = try values.decodeIfPresent(Date.self, forKey: .shimmerLoadCompleteTime)
    shimmerLoadingInfo = LoadingInfo(
      startAt: shimmerLoadStartTime,
      endAt: shimmerLoadCompleteTime
    )

    let productsLoadStartTime = try values.decodeIfPresent(Date.self, forKey: .productsLoadStartTime)
    let productsLoadCompleteTime = try values.decodeIfPresent(Date.self, forKey: .productsLoadCompleteTime)
    let productsLoadFailTime = try values.decodeIfPresent(Date.self, forKey: .productsLoadFailTime)
    productsLoadingInfo = LoadingInfo(
      startAt: productsLoadStartTime,
      endAt: productsLoadCompleteTime,
      failAt: productsLoadFailTime
    )

    featureGating = try values.decodeIfPresent(FeatureGatingBehavior.self, forKey: .featureGating) ?? .nonGated
    onDeviceCache = try values.decodeIfPresent(OnDeviceCaching.self, forKey: .onDeviceCache) ?? .disabled

    let throwableNotifications = try values.decodeIfPresent(
      [Throwable<LocalNotification>].self,
      forKey: .localNotifications
    ) ?? []
    localNotifications = throwableNotifications.compactMap { try? $0.result.get() }

    let throwableComputedPropertyRequests = try values.decodeIfPresent(
      [Throwable<ComputedPropertyRequest>].self,
      forKey: .computedPropertyRequests
    ) ?? []
    computedPropertyRequests = throwableComputedPropertyRequests.compactMap { try? $0.result.get() }

    manifest = try values.decodeIfPresent(ArchiveManifest.self, forKey: .manifest)
    isScrollEnabled = try values.decodeIfPresent(Bool.self, forKey: .isScrollEnabled) ?? true
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(databaseId, forKey: .id)
    try container.encode(identifier, forKey: .identifier)
    try container.encode(name, forKey: .name)
    try container.encode(cacheKey, forKey: .cacheKey)
    try container.encode(buildId, forKey: .buildId)
    try container.encode(url, forKey: .url)
    try container.encode(urlConfig, forKey: .urlConfig)
    try container.encode(htmlSubstitutions, forKey: .htmlSubstitutions)

    if !surveys.isEmpty {
      try container.encode(surveys, forKey: .surveys)
    }

    try container.encode(presentation.style, forKey: .presentationStyle)
    try container.encode(presentation.delay, forKey: .presentationDelay)

    try container.encode(backgroundColorHex, forKey: .backgroundColorHex)

    if let darkBackgroundColorHex = darkBackgroundColorHex {
      try container.encode(darkBackgroundColorHex, forKey: .darkBackgroundColorHex)
    }

    if !products.isEmpty {
      try container.encode(products, forKey: .products)
    }

    try container.encodeIfPresent(responseLoadingInfo.startAt, forKey: .responseLoadStartTime)
    try container.encodeIfPresent(responseLoadingInfo.endAt, forKey: .responseLoadCompleteTime)
    try container.encodeIfPresent(responseLoadingInfo.failAt, forKey: .responseLoadFailTime)

    try container.encodeIfPresent(webviewLoadingInfo.startAt, forKey: .webViewLoadStartTime)
    try container.encodeIfPresent(webviewLoadingInfo.endAt, forKey: .webViewLoadCompleteTime)
    try container.encodeIfPresent(webviewLoadingInfo.failAt, forKey: .webViewLoadFailTime)

    try container.encodeIfPresent(productsLoadingInfo.startAt, forKey: .productsLoadStartTime)
    try container.encodeIfPresent(productsLoadingInfo.endAt, forKey: .productsLoadCompleteTime)
    try container.encodeIfPresent(productsLoadingInfo.failAt, forKey: .productsLoadFailTime)

    try container.encodeIfPresent(featureGating, forKey: .featureGating)
    try container.encodeIfPresent(onDeviceCache, forKey: .onDeviceCache)

    if !localNotifications.isEmpty {
      try container.encode(localNotifications, forKey: .localNotifications)
    }

    if !computedPropertyRequests.isEmpty {
      try container.encode(computedPropertyRequests, forKey: .computedPropertyRequests)
    }

    try container.encodeIfPresent(manifest, forKey: .manifest)
    try container.encodeIfPresent(isScrollEnabled, forKey: .isScrollEnabled)
  }

  // Only used in stub
  private init(
    databaseId: String,
    identifier: String,
    name: String,
    cacheKey: String,
    buildId: String,
    experiment: Experiment? = nil,
    url: URL,
    urlConfig: WebViewURLConfig,
    htmlSubstitutions: String,
    presentation: PaywallPresentationInfo,
    backgroundColorHex: String,
    backgroundColor: UIColor,
    darkBackgroundColorHex: String?,
    darkBackgroundColor: UIColor?,
    productItems: [Product],
    productIds: [String],
    responseLoadingInfo: LoadingInfo,
    webviewLoadingInfo: LoadingInfo,
    productsLoadingInfo: LoadingInfo,
    shimmerLoadingInfo: LoadingInfo,
    paywalljsVersion: String,
    productVariables: [ProductVariable]? = [],
    isFreeTrialAvailable: Bool = false,
    presentationSourceType: String? = nil,
    featureGating: FeatureGatingBehavior = .nonGated,
    onDeviceCache: OnDeviceCaching = .disabled,
    localNotifications: [LocalNotification] = [],
    computedPropertyRequests: [ComputedPropertyRequest] = [],
    surveys: [Survey] = [],
    manifest: ArchiveManifest? = nil,
    isScrollEnabled: Bool
  ) {
    self.databaseId = databaseId
    self.identifier = identifier
    self.name = name
    self.cacheKey = cacheKey
    self.buildId = buildId
    self.experiment = experiment
    self.url = url
    self.urlConfig = urlConfig
    self.htmlSubstitutions = htmlSubstitutions
    self.presentation = presentation
    self.backgroundColor = backgroundColor
    self.backgroundColorHex = backgroundColorHex
    self.darkBackgroundColor = darkBackgroundColor
    self.darkBackgroundColorHex = darkBackgroundColorHex
    self.products = productItems
    self.productIds = productIds
    self.responseLoadingInfo = responseLoadingInfo
    self.webviewLoadingInfo = webviewLoadingInfo
    self.productsLoadingInfo = productsLoadingInfo
    self.shimmerLoadingInfo = shimmerLoadingInfo
    self.paywalljsVersion = paywalljsVersion
    self.productVariables = productVariables
    self.isFreeTrialAvailable = isFreeTrialAvailable
    self.presentationSourceType = presentationSourceType
    self.featureGating = featureGating
    self.onDeviceCache = onDeviceCache
    self.localNotifications = localNotifications
    self.computedPropertyRequests = computedPropertyRequests
    self.surveys = surveys
    self.manifest = manifest
    self.isScrollEnabled = isScrollEnabled
  }

  func getInfo(fromPlacement: PlacementData?) -> PaywallInfo {
    return PaywallInfo(
      databaseId: databaseId,
      identifier: identifier,
      name: name,
      cacheKey: cacheKey,
      buildId: buildId,
      url: url,
      products: products,
      productIds: productIds,
      fromPlacementData: fromPlacement,
      responseLoadStartTime: responseLoadingInfo.startAt,
      responseLoadCompleteTime: responseLoadingInfo.endAt,
      responseLoadFailTime: responseLoadingInfo.failAt,
      webViewLoadStartTime: webviewLoadingInfo.startAt,
      webViewLoadCompleteTime: webviewLoadingInfo.endAt,
      webViewLoadFailTime: webviewLoadingInfo.failAt,
      productsLoadStartTime: productsLoadingInfo.startAt,
      productsLoadFailTime: productsLoadingInfo.failAt,
      productsLoadCompleteTime: productsLoadingInfo.endAt,
      shimmerLoadStartTime: shimmerLoadingInfo.startAt,
      shimmerLoadCompleteTime: shimmerLoadingInfo.endAt,
      experiment: experiment,
      paywalljsVersion: paywalljsVersion,
      isFreeTrialAvailable: isFreeTrialAvailable,
      presentationSourceType: presentationSourceType,
      featureGatingBehavior: featureGating,
      closeReason: closeReason,
      localNotifications: localNotifications,
      computedPropertyRequests: computedPropertyRequests,
      surveys: surveys,
      presentation: presentation,
      isScrollEnabled: isScrollEnabled
    )
  }

  mutating func update(from paywall: Paywall) {
    products = paywall.products
    productVariables = paywall.productVariables
    isFreeTrialAvailable = paywall.isFreeTrialAvailable
    productsLoadingInfo = paywall.productsLoadingInfo
    presentationSourceType = paywall.presentationSourceType
    experiment = paywall.experiment
    featureGating = paywall.featureGating
  }
}

// MARK: - Equatable
extension Paywall: Equatable {
  static func == (lhs: Paywall, rhs: Paywall) -> Bool {
    return lhs.databaseId == rhs.databaseId
  }
}

// swiftlint:disable force_unwrapping

// MARK: - Stubbable
extension Paywall: Stubbable {
  static func stub() -> Paywall {
    return Paywall(
      databaseId: "id",
      identifier: "identifier",
      name: "abc",
      cacheKey: "cacheKey",
      buildId: "buildId",
      url: URL(string: "https://google.com")!,
      urlConfig: .init(endpoints: [], maxAttempts: 0),
      htmlSubstitutions: "",
      presentation: PaywallPresentationInfo(
        style: .modal,
        delay: 0
      ),
      backgroundColorHex: "",
      backgroundColor: .black,
      darkBackgroundColorHex: nil,
      darkBackgroundColor: nil,
      productItems: [],
      productIds: [],
      responseLoadingInfo: .init(),
      webviewLoadingInfo: .init(),
      productsLoadingInfo: .init(),
      shimmerLoadingInfo: .init(),
      paywalljsVersion: "",
      isScrollEnabled: true
    )
  }
}
