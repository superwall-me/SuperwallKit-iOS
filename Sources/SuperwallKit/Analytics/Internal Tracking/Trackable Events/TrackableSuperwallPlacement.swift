//
//  File.swift
//
//
//  Created by Yusuf Tör on 20/04/2022.
//
// swiftlint:disable type_body_length nesting file_length type_body_length

import Foundation
import StoreKit

protocol TrackableSuperwallPlacement: Trackable {
  /// The ``SuperwallPlacement`` to be tracked by this placement.
  var superwallPlacement: SuperwallPlacement { get }
}

extension TrackableSuperwallPlacement {
  var rawName: String {
    return String(describing: superwallPlacement)
  }

  var canImplicitlyTriggerPaywall: Bool {
    return superwallPlacement.canImplicitlyTriggerPaywall
  }
}

/// These are events that tracked internally and sent back to the user via the delegate.
enum InternalSuperwallPlacement {
  struct AppOpen: TrackableSuperwallPlacement {
    let superwallPlacement: SuperwallPlacement = .appOpen
    var audienceFilterParams: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct AppInstall: TrackableSuperwallPlacement {
    let superwallPlacement: SuperwallPlacement = .appInstall
    let appInstalledAtString: String
    let hasExternalPurchaseController: Bool
    var audienceFilterParams: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] {
      return [
        "application_installed_at": appInstalledAtString,
        "using_purchase_controller": hasExternalPurchaseController
      ]
    }
  }

  struct TouchesBegan: TrackableSuperwallPlacement {
    let superwallPlacement: SuperwallPlacement = .touchesBegan
    var audienceFilterParams: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct SurveyClose: TrackableSuperwallPlacement {
    let superwallPlacement: SuperwallPlacement = .surveyClose
    var audienceFilterParams: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct SurveyResponse: TrackableSuperwallPlacement {
    var superwallPlacement: SuperwallPlacement {
      return .surveyResponse(
        survey: survey,
        selectedOption: selectedOption,
        customResponse: customResponse,
        paywallInfo: paywallInfo
      )
    }
    var audienceFilterParams: [String: Any] {
      let output = paywallInfo.audienceFilterParams()
      return output + [
        "survey_selected_option_title": selectedOption.title,
        "survey_custom_response": customResponse as Any
      ]
    }
    let survey: Survey
    let selectedOption: SurveyOption
    let customResponse: String?
    let paywallInfo: PaywallInfo

    func getSuperwallParameters() async -> [String: Any] {
      let params: [String: Any] = [
        "survey_id": survey.id,
        "survey_assignment_key": survey.assignmentKey,
        "survey_selected_option_id": selectedOption.id
      ]

      return await paywallInfo.placementParams(otherParams: params)
    }
  }

  struct AppLaunch: TrackableSuperwallPlacement {
    let superwallPlacement: SuperwallPlacement = .appLaunch
    var audienceFilterParams: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct Attributes: TrackableSuperwallPlacement {
    let appInstalledAtString: String
    var superwallPlacement: SuperwallPlacement {
      return .userAttributes(audienceFilterParams)
    }
    func getSuperwallParameters() async -> [String: Any] {
      return [
        "application_installed_at": appInstalledAtString
      ]
    }
    var audienceFilterParams: [String: Any] = [:]
  }

  struct IdentityAlias: TrackableSuperwallPlacement {
    let superwallPlacement: SuperwallPlacement = .identityAlias
    var audienceFilterParams: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct DeepLink: TrackableSuperwallPlacement {
    var superwallPlacement: SuperwallPlacement {
      .deepLink(url: url)
    }
    let url: URL

    func getSuperwallParameters() async -> [String: Any] {
      return [
        "url": url.absoluteString,
        "path": url.path,
        "pathExtension": url.pathExtension,
        "lastPathComponent": url.lastPathComponent,
        "host": url.host ?? "",
        "query": url.query ?? "",
        "fragment": url.fragment ?? ""
      ]
    }

    var audienceFilterParams: [String: Any] {
      guard
        let urlComponents = URLComponents(
          url: url,
          resolvingAgainstBaseURL: false
        )
      else {
        return [:]
      }
      guard let queryItems = urlComponents.queryItems else {
        return [:]
      }

      var queryStrings: [String: Any] = [:]
      for queryItem in queryItems {
        guard
          !queryItem.name.isEmpty,
          let value = queryItem.value,
          !value.isEmpty
        else {
          continue
        }
        let name = queryItem.name
        let lowerCaseValue = value.lowercased()
        if lowerCaseValue == "true" {
          queryStrings[name] = true
        } else if lowerCaseValue == "false" {
          queryStrings[name] = false
        } else if let int = Int(value) {
          queryStrings[name] = int
        } else if let double = Double(value) {
          queryStrings[name] = double
        } else {
          queryStrings[name] = value
        }
      }
      return queryStrings
    }
  }

  struct FirstSeen: TrackableSuperwallPlacement {
    let superwallPlacement: SuperwallPlacement = .firstSeen
    var audienceFilterParams: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct Reset: TrackableSuperwallPlacement {
    let superwallPlacement: SuperwallPlacement = .reset
    var audienceFilterParams: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct AppClose: TrackableSuperwallPlacement {
    let superwallPlacement: SuperwallPlacement = .appClose
    var audienceFilterParams: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct SessionStart: TrackableSuperwallPlacement {
    let superwallPlacement: SuperwallPlacement = .sessionStart
    var audienceFilterParams: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct ConfigAttributes: TrackableSuperwallPlacement {
    let superwallPlacement: SuperwallPlacement = .configAttributes
    let options: SuperwallOptions
    let hasExternalPurchaseController: Bool
    let hasDelegate: Bool

    var audienceFilterParams: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] {
      var params = options.toDictionary()
      params += [
        "using_purchase_controller": hasExternalPurchaseController,
        "has_delegate": hasDelegate
      ]
      return params
    }
  }

  struct DeviceAttributes: TrackableSuperwallPlacement {
    var superwallPlacement: SuperwallPlacement {
      return .deviceAttributes(attributes: deviceAttributes)
    }
    let deviceAttributes: [String: Any]

    var audienceFilterParams: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] {
      return deviceAttributes
    }
  }

  struct PaywallLoad: TrackableSuperwallPlacement {
    enum State {
      case start
      case notFound
      case fail
      case complete(paywallInfo: PaywallInfo)
    }
    let state: State

    var superwallPlacement: SuperwallPlacement {
      switch state {
      case .start:
        return .paywallResponseLoadStart(triggeredPlacementName: placementData?.name)
      case .notFound:
        return .paywallResponseLoadNotFound(triggeredPlacementName: placementData?.name)
      case .fail:
        return .paywallResponseLoadFail(triggeredPlacementName: placementData?.name)
      case .complete(let paywallInfo):
        return .paywallResponseLoadComplete(
          triggeredPlacementName: placementData?.name,
          paywallInfo: paywallInfo
        )
      }
    }
    let placementData: PlacementData?
    var audienceFilterParams: [String: Any] {
      switch state {
      case .complete(let paywallInfo):
        return paywallInfo.audienceFilterParams()
      default:
        return [:]
      }
    }

    func getSuperwallParameters() async -> [String: Any] {
      let fromPlacement = placementData != nil
      let params: [String: Any] = [
        "is_triggered_from_event": fromPlacement
      ]

      switch state {
      case .start,
        .notFound,
        .fail:
        return params
      case .complete(let paywallInfo):
        return await paywallInfo.placementParams(otherParams: params)
      }
    }
  }

  struct EntitlementStatusDidChange: TrackableSuperwallPlacement {
    let superwallPlacement: SuperwallPlacement = .entitlementStatusDidChange
    let status: EntitlementStatus
    var audienceFilterParams: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] {
      var params: [String: Any] = [
        "status": status.description
      ]
      if case let .active(entitlements) = status {
        params += [
          "active_entitlement_ids": entitlements.map(\.id).joined()
        ]
      }
      return params
    }
  }

  struct TriggerFire: TrackableSuperwallPlacement {
    let triggerResult: InternalTriggerResult
    var superwallPlacement: SuperwallPlacement {
      return .triggerFire(
        placementName: triggerName,
        result: triggerResult.toPublicType()
      )
    }
    let triggerName: String
    var audienceFilterParams: [String: Any] = [:]

    func getSuperwallParameters() async -> [String: Any] {
      var params: [String: Any] = [
        "trigger_name": triggerName
      ]

      switch triggerResult {
      case .noAudienceMatch(let unmatchedAudiences):
        params += [
          "result": "no_rule_match"
        ]
        for unmatchedAudience in unmatchedAudiences {
          params["unmatched_audience_\(unmatchedAudience.experimentId)"] =
            unmatchedAudience.source.rawValue
        }
        return params
      case .holdout(let experiment):
        return params + [
          "variant_id": experiment.variant.id as Any,
          "experiment_id": experiment.id as Any,
          "result": "holdout"
        ]
      case let .paywall(experiment):
        return params + [
          "variant_id": experiment.variant.id as Any,
          "experiment_id": experiment.id as Any,
          "paywall_identifier": experiment.variant.paywallId as Any,
          "result": "present"
        ]
      case .placementNotFound:
        return params + [
          "result": "eventNotFound"
        ]
      case .error:
        return params + [
          "result": "error"
        ]
      }
    }
  }

  struct PresentationRequest: TrackableSuperwallPlacement {
    let placementData: PlacementData?
    let type: PresentationRequestType
    let status: PaywallPresentationRequestStatus
    let statusReason: PaywallPresentationRequestStatusReason?
    let factory:
      AudienceFilterAttributesFactory & FeatureFlagsFactory & ComputedPropertyRequestsFactory

    var superwallPlacement: SuperwallPlacement {
      return .paywallPresentationRequest(
        status: status,
        reason: statusReason
      )
    }
    var audienceFilterParams: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] {
      var params = [
        "source_event_name": placementData?.name ?? "",
        "pipeline_type": type.description,
        "status": status.rawValue,
        "status_reason": statusReason?.description ?? ""
      ]

      if let featureFlags = factory.makeFeatureFlags(),
        featureFlags.enableExpressionParameters {
        let computedPropertyRequests = factory.makeComputedPropertyRequests()
        let audienceFilters = await factory.makeAudienceFilterAttributes(
          forPlacement: placementData,
          withComputedProperties: computedPropertyRequests
        )

        if let jsonData = try? JSONSerialization.data(withJSONObject: audienceFilters),
          let decoded = String(data: jsonData, encoding: .utf8) {
          params += [
            "expression_params": decoded
          ]
        }
      }

      return params
    }
  }

  struct PaywallOpen: TrackableSuperwallPlacement {
    var superwallPlacement: SuperwallPlacement {
      return .paywallOpen(paywallInfo: paywallInfo)
    }
    let paywallInfo: PaywallInfo
    func getSuperwallParameters() async -> [String: Any] {
      return await paywallInfo.placementParams()
    }
    var audienceFilterParams: [String: Any] {
      return paywallInfo.audienceFilterParams()
    }
  }

  struct PaywallClose: TrackableSuperwallPlacement {
    var superwallPlacement: SuperwallPlacement {
      return .paywallClose(paywallInfo: paywallInfo)
    }
    let paywallInfo: PaywallInfo
    let surveyPresentationResult: SurveyPresentationResult

    func getSuperwallParameters() async -> [String: Any] {
      var params: [String: Any] = [
        "survey_attached": paywallInfo.surveys.isEmpty ? false : true
      ]

      if surveyPresentationResult != .noShow {
        params["survey_presentation"] = surveyPresentationResult.rawValue
      }

      let placementParams = await paywallInfo.placementParams()
      params += placementParams
      return params
    }
    var audienceFilterParams: [String: Any] {
      return paywallInfo.audienceFilterParams()
    }
  }

  struct PaywallDecline: TrackableSuperwallPlacement {
    var superwallPlacement: SuperwallPlacement {
      return .paywallDecline(paywallInfo: paywallInfo)
    }
    let paywallInfo: PaywallInfo
    func getSuperwallParameters() async -> [String: Any] {
      return await paywallInfo.placementParams()
    }
    var audienceFilterParams: [String: Any] {
      return paywallInfo.audienceFilterParams()
    }
  }

  struct CustomPlacement: TrackableSuperwallPlacement {
    var superwallPlacement: SuperwallPlacement {
      return .customPlacement(
        name: name,
        params: params,
        paywallInfo: paywallInfo
      )
    }
    var rawName: String {
      return name
    }
    let paywallInfo: PaywallInfo
    let name: String
    let params: [String: Any]

    func getSuperwallParameters() async -> [String: Any] {
      var placementParams = await paywallInfo.placementParams()
      placementParams += params
      placementParams += [
        "name": name
      ]
      return placementParams
    }
    var audienceFilterParams: [String: Any] {
      var customParams = paywallInfo.audienceFilterParams()
      customParams += params
      return customParams
    }
  }

  struct Restore: TrackableSuperwallPlacement {
    enum State {
      case start
      case fail(String)
      case complete
    }
    let state: State
    let paywallInfo: PaywallInfo

    var superwallPlacement: SuperwallPlacement {
      switch state {
      case .start:
        return .restoreStart
      case .fail(let message):
        return .restoreFail(message: message)
      case .complete:
        return .restoreComplete
      }
    }
    var audienceFilterParams: [String: Any] {
      return paywallInfo.audienceFilterParams()
    }
    func getSuperwallParameters() async -> [String: Any] {
      var placementParams = await paywallInfo.placementParams()
      if case .fail(let message) = state {
        placementParams["error_message"] = message
      }
      return placementParams
    }
  }

  struct Transaction: TrackableSuperwallPlacement {
    enum State {
      case start(StoreProduct)
      case fail(TransactionError)
      case abandon(StoreProduct)
      case complete(StoreProduct, StoreTransaction?, TransactionType)
      case restore(RestoreType)
      case timeout
    }
    let state: State

    var superwallPlacement: SuperwallPlacement {
      switch state {
      case .start(let product):
        return .transactionStart(
          product: product,
          paywallInfo: paywallInfo
        )
      case .fail(let error):
        return .transactionFail(
          error: error,
          paywallInfo: paywallInfo
        )
      case .abandon(let product):
        return .transactionAbandon(
          product: product,
          paywallInfo: paywallInfo
        )
      case let .complete(product, model, type):
        return .transactionComplete(
          transaction: model,
          product: product,
          type: type,
          paywallInfo: paywallInfo
        )
      case .restore(let restoreType):
        return .transactionRestore(
          restoreType: restoreType,
          paywallInfo: paywallInfo
        )
      case .timeout:
        return .transactionTimeout(paywallInfo: paywallInfo)
      }
    }
    enum Source: String {
      case `internal` = "SUPERWALL"
      case external = "APP"
    }
    let paywallInfo: PaywallInfo
    let product: StoreProduct?
    let transaction: StoreTransaction?
    let source: Source
    let isObserved: Bool
    let storeKitVersion: SuperwallOptions.StoreKitVersion

    var canImplicitlyTriggerPaywall: Bool {
      if isObserved {
        return false
      }
      return superwallPlacement.canImplicitlyTriggerPaywall
    }

    var audienceFilterParams: [String: Any] {
      switch state {
      case .abandon(let product):
        var params = paywallInfo.audienceFilterParams()
        params["abandoned_product_id"] = product.productIdentifier
        return params
      default:
        return paywallInfo.audienceFilterParams()
      }
    }

    func getSuperwallParameters() async -> [String: Any] {
      var storefrontCountryCode = ""
      var storefrontId = ""
      if #available(iOS 15.0, *) {
        storefrontCountryCode = await Storefront.current?.countryCode ?? ""
        storefrontId = await Storefront.current?.id ?? ""
      }
      var placementParams: [String: Any] = [
        "store": "APP_STORE",
        "source": source.rawValue,
        "storekit_version": storeKitVersion.description
      ]

      switch state {
      case .restore:
        placementParams += await paywallInfo.placementParams(forProduct: product)
        if let transactionDict = transaction?.dictionary(withSnakeCase: true) {
          placementParams += transactionDict
        }
        placementParams["restore_via_purchase_attempt"] = transaction != nil
        return placementParams
      case .complete(_, _, let type):
        placementParams += [
          "storefront_countryCode": storefrontCountryCode,
          "storefront_id": storefrontId,
          "transaction_type": type.description
        ]
        let appleSearchAttributes = Superwall.shared.userAttributes.filter { $0.key.hasPrefix("apple_search_ads_") }
        placementParams += appleSearchAttributes
        fallthrough
      case .start,
        .abandon,
        .timeout:
        placementParams += await paywallInfo.placementParams(forProduct: product)
        if let transactionDict = transaction?.dictionary(withSnakeCase: true) {
          placementParams += transactionDict
        }
        return placementParams
      case .fail(let error):
        switch error {
        case .failure(let message, _),
          .pending(let message):
          let paywallInfoParams = await paywallInfo.placementParams(
            forProduct: product,
            otherParams: ["message": message]
          )
          return placementParams + paywallInfoParams
        }
      }
    }
  }

  struct SubscriptionStart: TrackableSuperwallPlacement {
    var superwallPlacement: SuperwallPlacement {
      return .subscriptionStart(product: product, paywallInfo: paywallInfo)
    }
    let paywallInfo: PaywallInfo
    let product: StoreProduct
    let transaction: StoreTransaction?
    var audienceFilterParams: [String: Any] {
      return paywallInfo.audienceFilterParams()
    }

    func getSuperwallParameters() async -> [String: Any] {
      var params = await paywallInfo.placementParams(forProduct: product)
      if let transactionDict = transaction?.dictionary(withSnakeCase: true) {
        params += transactionDict
      }
      return params
    }
  }

  struct ConfirmAllAssignments: TrackableSuperwallPlacement {
    let superwallPlacement: SuperwallPlacement = .confirmAllAssignments
    let audienceFilterParams: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct FreeTrialStart: TrackableSuperwallPlacement {
    var superwallPlacement: SuperwallPlacement {
      return .freeTrialStart(
        product: product,
        paywallInfo: paywallInfo
      )
    }
    let paywallInfo: PaywallInfo
    let product: StoreProduct
    let transaction: StoreTransaction?
    var audienceFilterParams: [String: Any] {
      return paywallInfo.audienceFilterParams()
    }

    func getSuperwallParameters() async -> [String: Any] {
      var params = await paywallInfo.placementParams(forProduct: product)
      if let transactionDict = transaction?.dictionary(withSnakeCase: true) {
        params += transactionDict
      }
      return params
    }
  }

  struct NonRecurringProductPurchase: TrackableSuperwallPlacement {
    var superwallPlacement: SuperwallPlacement {
      return .nonRecurringProductPurchase(
        product: .init(product: product),
        paywallInfo: paywallInfo
      )
    }
    let paywallInfo: PaywallInfo
    let product: StoreProduct
    let transaction: StoreTransaction?
    var audienceFilterParams: [String: Any] {
      return paywallInfo.audienceFilterParams()
    }

    func getSuperwallParameters() async -> [String: Any] {
      var params = await paywallInfo.placementParams(forProduct: product)
      if let transactionDict = transaction?.dictionary(withSnakeCase: true) {
        params += transactionDict
      }
      return params
    }
  }

  struct PaywallWebviewLoad: TrackableSuperwallPlacement {
    enum State {
      case start
      case fail(Error, [URL])
      case timeout
      case complete
      case fallback
    }
    let state: State

    var superwallPlacement: SuperwallPlacement {
      switch state {
      case .start:
        return .paywallWebviewLoadStart(paywallInfo: paywallInfo)
      case .fail:
        return .paywallWebviewLoadFail(paywallInfo: paywallInfo)
      case .timeout:
        return .paywallWebviewLoadTimeout(paywallInfo: paywallInfo)
      case .complete:
        return .paywallWebviewLoadComplete(paywallInfo: paywallInfo)
      case .fallback:
        return .paywallWebviewLoadFallback(paywallInfo: paywallInfo)
      }
    }
    let paywallInfo: PaywallInfo

    func getSuperwallParameters() async -> [String: Any] {
      var placementParams = await paywallInfo.placementParams()
      if case .fail(let error, let urls) = state {
        placementParams["error_message"] = error.safeLocalizedDescription
        for (index, url) in urls.enumerated() {
          placementParams["url_\(index)"] = url.absoluteString
        }
      }
      return placementParams
    }
    var audienceFilterParams: [String: Any] {
      return paywallInfo.audienceFilterParams()
    }
  }

  struct PaywallProductsLoad: TrackableSuperwallPlacement {
    enum State {
      case start
      case fail(Error)
      case complete
      case retry(Int)
    }
    let state: State
    var audienceFilterParams: [String: Any] {
      return paywallInfo.audienceFilterParams()
    }

    var superwallPlacement: SuperwallPlacement {
      switch state {
      case .start:
        return .paywallProductsLoadStart(
          triggeredPlacementName: placementData?.name, paywallInfo: paywallInfo)
      case .fail:
        return .paywallProductsLoadFail(
          triggeredPlacementName: placementData?.name, paywallInfo: paywallInfo)
      case .complete:
        return .paywallProductsLoadComplete(triggeredPlacementName: placementData?.name)
      case .retry(let attempt):
        return .paywallProductsLoadRetry(
          triggeredPlacementName: placementData?.name,
          paywallInfo: paywallInfo,
          attempt: attempt
        )
      }
    }
    let paywallInfo: PaywallInfo
    let placementData: PlacementData?

    func getSuperwallParameters() async -> [String: Any] {
      let fromPlacement = placementData != nil
      var params: [String: Any] = [
        "is_triggered_from_event": fromPlacement
      ]
      if case .fail(let error) = state {
        params["error_message"] = error.safeLocalizedDescription
      }
      params += await paywallInfo.placementParams()
      return params
    }
  }

  enum ConfigCacheStatus: String {
    case cached = "CACHED"
    case notCached = "NOT_CACHED"
  }

  struct ConfigRefresh: TrackableSuperwallPlacement {
    let superwallPlacement: SuperwallPlacement = .configRefresh
    let buildId: String
    let retryCount: Int
    let cacheStatus: ConfigCacheStatus
    let fetchDuration: TimeInterval
    var audienceFilterParams: [String: Any] = [:]

    func getSuperwallParameters() async -> [String: Any] {
      return [
        "config_build_id": buildId,
        "retry_count": retryCount,
        "cache_status": cacheStatus.rawValue,
        "fetch_duration": fetchDuration
      ]
    }
  }

  struct ConfigFail: TrackableSuperwallPlacement {
    let superwallPlacement: SuperwallPlacement = .configFail
    let message: String
    var audienceFilterParams: [String: Any] = [:]

    func getSuperwallParameters() async -> [String: Any] {
      return [
        "error_message": message
      ]
    }
  }

  struct AdServicesTokenRetrieval: TrackableSuperwallPlacement {
    enum State {
      case start
      case fail(Error)
      case complete(String)
    }
    let state: State

    var superwallPlacement: SuperwallPlacement {
      switch state {
      case .start:
        return .adServicesTokenRequestStart
      case .fail(let error):
        return .adServicesTokenRequestFail(error: error)
      case .complete(let token):
        return .adServicesTokenRequestComplete(token: token)
      }
    }
    let audienceFilterParams: [String: Any] = [:]

    func getSuperwallParameters() async -> [String: Any] {
      switch state {
      case .start:
        return [:]
      case .fail(let error):
        return ["error_message": error.localizedDescription]
      case .complete(let token):
        return [
          "token": token
        ]
      }
    }
  }

  struct ShimmerLoad: TrackableSuperwallPlacement {
    enum State {
      case start
      case complete
    }
    let state: State
    let paywallId: String
    var loadDuration: Double?
    var visibleDuration: Double?
    var superwallPlacement: SuperwallPlacement {
      switch state {
      case .start:
        return .shimmerViewStart
      case .complete:
        return .shimmerViewComplete
      }
    }
    let audienceFilterParams: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] {
      var params: [String: Any] = [
        "paywall_id": paywallId
      ]

      if state == .complete {
        params += [
          "visible_duration": visibleDuration ?? 0.0
        ]
      }
      return params
    }
  }
}
