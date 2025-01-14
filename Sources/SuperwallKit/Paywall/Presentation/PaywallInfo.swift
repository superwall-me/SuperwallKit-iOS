//
//  PaywallInfo.swift
//  Superwall
//
//  Created by Yusuf Tör on 28/02/2022.
//
// swiftlint:disable file_length

import Foundation
import StoreKit

/// Contains information about a paywall.
@objc(SWKPaywallInfo)
@objcMembers
public final class PaywallInfo: NSObject {
  /// Superwall's internal ID for this paywall.
  let databaseId: String

  /// The identifier set for this paywall in the Superwall dashboard.
  public let identifier: String

  /// The cache key for the paywall.
  public let cacheKey: String

  /// The build ID of the Superwall configuration.
  public let buildId: String

  /// The trigger experiment that caused the paywall to present.
  ///
  /// An experiment is a set of paywall variants determined by probabilities. An experiment will result in a user seeing a paywall unless they are in a holdout group.
  public let experiment: Experiment?

  /// An array of products associated with the paywall.
  public let products: [Product]

  /// An ordered array of product IDs that this paywall is displaying.
  public let productIds: [String]

  /// The name set for this paywall in Superwall's web dashboard.
  public let name: String

  /// The URL where this paywall is hosted.
  public let url: URL

  /// The name of the placement that triggered this Paywall. Defaults to `nil` if `triggeredByPlacement` is false.
  public let presentedByPlacementWithName: String?

  /// The Superwall internal id (for debugging) of the placement that triggered this Paywall. Defaults to `nil` if `triggeredByPlacement` is false.
  public let presentedByPlacementWithId: String?

  /// The ISO date string describing when the placement triggered this paywall. Defaults to `nil` if `triggeredByPlacement` is false.
  public let presentedByPlacementAt: String?

  /// How the paywall was presented, either 'programmatically', 'identifier', or 'placement'
  public let presentedBy: String

  /// The source function that retrieved the paywall. Either `implicit`, `getPaywall`, or `register`. `nil` only when preloading.
  public let presentationSourceType: String?

  /// An iso date string indicating when the paywall response began loading.
  public let responseLoadStartTime: String?

  /// An iso date string indicating when the paywall response finished loading.
  public let responseLoadCompleteTime: String?

  /// An iso date string indicating when the paywall response failed to load.
  public let responseLoadFailTime: String?

  /// The time it took to load the paywall response.
  public let responseLoadDuration: TimeInterval?

  /// An iso date string indicating when the paywall webview began loading.
  public let webViewLoadStartTime: String?

  /// An iso date string indicating when the paywall webview finished loading.
  public let webViewLoadCompleteTime: String?

  /// An iso date string indicating when the paywall webview failed to load.
  public let webViewLoadFailTime: String?

  /// The time it took to load the paywall website.
  public let webViewLoadDuration: TimeInterval?

  /// An iso date string indicating when the paywall products began loading.
  public let productsLoadStartTime: String?

  /// An iso date string indicating when the paywall products finished loading.
  public let productsLoadCompleteTime: String?

  /// An iso date string indicating when the paywall products failed to load.
  public let productsLoadFailTime: String?

  /// The time it took to load the paywall products.
  public let productsLoadDuration: TimeInterval?

  /// An iso date string indicating when the shimmer view began loading.
  public let shimmerLoadStartTime: String?

  /// An iso date string indicating when the shimmer view finished loading.
  public let shimmerLoadCompleteTime: String?

  /// The paywall.js version installed on the paywall website.
  public let paywalljsVersion: String?

  /// Indicates whether the paywall is showing free trial content.
  public let isFreeTrialAvailable: Bool

  /// A ``FeatureGatingBehavior`` case that indicates whether the
  /// ``Superwall/register(placement:params:handler:feature:)``
  /// `feature` block executes or not.
  public let featureGatingBehavior: FeatureGatingBehavior

  /// An enum describing why this paywall was last closed. `none` if not yet closed.
  public let closeReason: PaywallCloseReason

  /// The local notifications associated with the paywall.
  public let localNotifications: [LocalNotification]

  /// An array of requests to compute a device property associated with an placement at runtime.
  public let computedPropertyRequests: [ComputedPropertyRequest]

  /// Surveys attached to a paywall.
  public let surveys: [Survey]

  /// Information about the presentation of the paywall.
  public let presentation: PaywallPresentationInfo

  /// Indicates whether scrolling of the webview is enabled.
  public let isScrollEnabled: Bool

  init(
    databaseId: String,
    identifier: String,
    name: String,
    cacheKey: String,
    buildId: String,
    url: URL,
    products: [Product],
    productIds: [String],
    fromPlacementData placementData: PlacementData?,
    responseLoadStartTime: Date?,
    responseLoadCompleteTime: Date?,
    responseLoadFailTime: Date?,
    webViewLoadStartTime: Date?,
    webViewLoadCompleteTime: Date?,
    webViewLoadFailTime: Date?,
    productsLoadStartTime: Date?,
    productsLoadFailTime: Date?,
    productsLoadCompleteTime: Date?,
    shimmerLoadStartTime: Date?,
    shimmerLoadCompleteTime: Date?,
    experiment: Experiment?,
    paywalljsVersion: String?,
    isFreeTrialAvailable: Bool,
    presentationSourceType: String?,
    featureGatingBehavior: FeatureGatingBehavior,
    closeReason: PaywallCloseReason,
    localNotifications: [LocalNotification],
    computedPropertyRequests: [ComputedPropertyRequest],
    surveys: [Survey],
    presentation: PaywallPresentationInfo,
    isScrollEnabled: Bool
  ) {
    self.databaseId = databaseId
    self.identifier = identifier
    self.name = name
    self.cacheKey = cacheKey
    self.buildId = buildId
    self.url = url
    self.presentedByPlacementWithName = placementData?.name
    self.presentedByPlacementAt = placementData?.createdAt.isoString
    self.presentedByPlacementWithId = placementData?.id.lowercased()
    self.presentationSourceType = presentationSourceType
    self.experiment = experiment
    self.paywalljsVersion = paywalljsVersion
    self.products = products
    self.productIds = productIds
    self.isFreeTrialAvailable = isFreeTrialAvailable
    self.featureGatingBehavior = featureGatingBehavior
    self.localNotifications = localNotifications
    self.computedPropertyRequests = computedPropertyRequests
    self.surveys = surveys
    self.presentation = presentation

    if placementData != nil {
      self.presentedBy = "placement"
    } else {
      self.presentedBy = "programmatically"
    }

    self.responseLoadStartTime = responseLoadStartTime?.isoString ?? ""
    self.responseLoadCompleteTime = responseLoadStartTime?.isoString ?? ""
    self.responseLoadFailTime = responseLoadFailTime?.isoString ?? ""

    if let startTime = responseLoadStartTime,
      let endTime = responseLoadCompleteTime {
      self.responseLoadDuration = endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970
    } else {
      self.responseLoadDuration = nil
    }

    self.webViewLoadStartTime = webViewLoadStartTime?.isoString ?? ""
    self.webViewLoadCompleteTime = webViewLoadCompleteTime?.isoString ?? ""
    self.webViewLoadFailTime = webViewLoadFailTime?.isoString ?? ""

    if let startTime = webViewLoadStartTime,
      let endTime = webViewLoadCompleteTime {
      self.webViewLoadDuration = endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970
    } else {
      self.webViewLoadDuration = nil
    }

    self.productsLoadStartTime = productsLoadStartTime?.isoString ?? ""
    self.productsLoadCompleteTime = productsLoadCompleteTime?.isoString ?? ""
    self.productsLoadFailTime = productsLoadFailTime?.isoString ?? ""

    if let startTime = productsLoadStartTime,
      let endTime = productsLoadCompleteTime {
      self.productsLoadDuration = endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970
    } else {
      self.productsLoadDuration = nil
    }

    self.shimmerLoadStartTime = shimmerLoadStartTime?.isoString ?? ""
    self.shimmerLoadCompleteTime = shimmerLoadCompleteTime?.isoString ?? ""

    self.closeReason = closeReason
    self.isScrollEnabled = isScrollEnabled
  }

  func placementParams(
    forProduct product: StoreProduct? = nil,
    otherParams: [String: Any]? = nil
  ) async -> [String: Any] {
    var output = audienceFilterParams()

    output += [
      "paywalljs_version": paywalljsVersion as Any,
      "paywall_identifier": identifier,
      "paywall_url": url.absoluteString,
      "presented_by_event_id": presentedByPlacementWithId as Any,
      "presented_by_event_timestamp": presentedByPlacementAt as Any,
      "presentation_source_type": presentationSourceType as Any,
      "paywall_response_load_start_time": responseLoadStartTime as Any,
      "paywall_response_load_complete_time": responseLoadCompleteTime as Any,
      "paywall_response_load_duration": responseLoadDuration as Any,
      "paywall_webview_load_start_time": webViewLoadStartTime as Any,
      "paywall_webview_load_complete_time": webViewLoadCompleteTime as Any,
      "paywall_webview_load_duration": webViewLoadDuration as Any,
      "paywall_products_load_start_time": productsLoadStartTime as Any,
      "paywall_products_load_complete_time": productsLoadCompleteTime as Any,
      "paywall_products_load_fail_time": productsLoadFailTime as Any,
      "paywall_products_load_duration": productsLoadDuration as Any,
      "shimmerView_load_complete_time": shimmerLoadCompleteTime as Any,
      "shimmerView_load_start_time": shimmerLoadStartTime as Any,
      "experiment_id": experiment?.id as Any,
      "variant_id": experiment?.variant.id as Any,
      "cache_key": cacheKey,
      "build_id": buildId,
      "close_reason": closeReason.description,
      "is_scroll_enabled": isScrollEnabled as Any
    ]

    var loadingVars: [String: Any] = [:]
    for key in output.keys {
      if key.contains("_load_"),
        let output = output[key] {
        loadingVars[key] = output
      }
    }

    Logger.debug(
      logLevel: .debug,
      scope: .paywallEvents,
      message: "Paywall loading timestamps",
      info: loadingVars
    )

    if let product = product {
      output["product_id"] = product.productIdentifier
      for key in product.attributes.keys {
        if let value = product.attributes[key] {
          output["product_\(key.camelCaseToSnakeCase())"] = value
        }
      }
    }

    if let otherParams = otherParams {
      for key in otherParams.keys {
        if let value = otherParams[key] {
          output[key] = value
        }
      }
    }

    return output
  }

  /// Parameters that can be used in audience filters.
  func audienceFilterParams() -> [String: Any] {
    var output: [String: Any] = [
      "paywall_id": databaseId,
      "paywall_name": name,
      "presented_by_event_name": presentedByPlacementWithName as Any,
      "paywall_product_ids": productIds.joined(separator: ","),
      "is_free_trial_available": isFreeTrialAvailable as Any,
      "feature_gating": featureGatingBehavior.description as Any,
      "presented_by": presentedBy as Any
    ]

    output["primary_product_id"] = ""
    output["secondary_product_id"] = ""
    output["tertiary_product_id"] = ""

    for (index, product) in products.enumerated() {
      if index == 0 {
        output["primary_product_id"] = product.id
      } else if index == 1 {
        output["secondary_product_id"] = product.id
      } else if index == 2 {
        output["tertiary_product_id"] = product.id
      }
      if let name = product.name {
        let key = "\(name)_product_id"
        output[key] = product.id
      }
    }

    return output
  }
}

// swiftlint:disable force_unwrapping
// MARK: - Stubbable
extension PaywallInfo: Stubbable {
  static func stub() -> PaywallInfo {
    return PaywallInfo(
      databaseId: "test",
      identifier: "test",
      name: "test",
      cacheKey: "test",
      buildId: "test",
      url: URL(string: "https://superwall.com")!,
      products: [],
      productIds: [],
      fromPlacementData: nil,
      responseLoadStartTime: nil,
      responseLoadCompleteTime: nil,
      responseLoadFailTime: nil,
      webViewLoadStartTime: nil,
      webViewLoadCompleteTime: nil,
      webViewLoadFailTime: nil,
      productsLoadStartTime: nil,
      productsLoadFailTime: nil,
      productsLoadCompleteTime: nil,
      shimmerLoadStartTime: nil,
      shimmerLoadCompleteTime: nil,
      experiment: nil,
      paywalljsVersion: nil,
      isFreeTrialAvailable: false,
      presentationSourceType: "register",
      featureGatingBehavior: .nonGated,
      closeReason: .manualClose,
      localNotifications: [],
      computedPropertyRequests: [],
      surveys: [],
      presentation: .init(
        style: .none,
        delay: 0
      ),
      isScrollEnabled: true
    )
  }

  /// Used when purchasing internally.
  static func empty() -> PaywallInfo {
    return PaywallInfo(
      databaseId: "",
      identifier: "",
      name: "",
      cacheKey: "",
      buildId: "",
      url: URL(string: "https://superwall.com")!,
      products: [],
      productIds: [],
      fromPlacementData: nil,
      responseLoadStartTime: nil,
      responseLoadCompleteTime: nil,
      responseLoadFailTime: nil,
      webViewLoadStartTime: nil,
      webViewLoadCompleteTime: nil,
      webViewLoadFailTime: nil,
      productsLoadStartTime: nil,
      productsLoadFailTime: nil,
      productsLoadCompleteTime: nil,
      shimmerLoadStartTime: nil,
      shimmerLoadCompleteTime: nil,
      experiment: .init(
        id: "0",
        groupId: "0",
        variant: .init(
          id: "0",
          type: .holdout,
          paywallId: "0"
        )
      ),
      paywalljsVersion: nil,
      isFreeTrialAvailable: false,
      presentationSourceType: "",
      featureGatingBehavior: .nonGated,
      closeReason: .none,
      localNotifications: [],
      computedPropertyRequests: [],
      surveys: [],
      presentation: .init(
        style: .none,
        delay: 0
      ),
      isScrollEnabled: true
    )
  }
}
