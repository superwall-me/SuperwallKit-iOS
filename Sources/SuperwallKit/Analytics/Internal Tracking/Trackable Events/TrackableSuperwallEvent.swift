//
//  File.swift
//  
//
//  Created by Yusuf Tör on 20/04/2022.
//
// swiftlint:disable type_body_length nesting file_length type_body_length

import Foundation
import StoreKit

protocol TrackableSuperwallEvent: Trackable {
  /// The ``SuperwallEvent`` to be tracked by this event.
  var superwallEvent: SuperwallEvent { get }
}

extension TrackableSuperwallEvent {
  var rawName: String {
    return String(describing: superwallEvent)
  }

  var canImplicitlyTriggerPaywall: Bool {
    return superwallEvent.canImplicitlyTriggerPaywall
  }
}

/// These are events that tracked internally and sent back to the user via the delegate.
enum InternalSuperwallEvent {
  struct AppOpen: TrackableSuperwallEvent {
    let superwallEvent: SuperwallEvent = .appOpen
    var customParameters: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct AppInstall: TrackableSuperwallEvent {
    let superwallEvent: SuperwallEvent = .appInstall
    let appInstalledAtString: String
    let hasExternalPurchaseController: Bool
    var customParameters: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] {
      return [
        "application_installed_at": appInstalledAtString,
        "using_purchase_controller": hasExternalPurchaseController
      ]
    }
  }

  struct TouchesBegan: TrackableSuperwallEvent {
    let superwallEvent: SuperwallEvent = .touchesBegan
    var customParameters: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct SurveyClose: TrackableSuperwallEvent {
    let superwallEvent: SuperwallEvent = .surveyClose
    var customParameters: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct SurveyResponse: TrackableSuperwallEvent {
    var superwallEvent: SuperwallEvent {
      return .surveyResponse(
        survey: survey,
        selectedOption: selectedOption,
        customResponse: customResponse,
        paywallInfo: paywallInfo
      )
    }
    var customParameters: [String: Any] {
      let output = paywallInfo.customParams()
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

      return await paywallInfo.eventParams(otherParams: params)
    }
  }

  struct AppLaunch: TrackableSuperwallEvent {
    let superwallEvent: SuperwallEvent = .appLaunch
    var customParameters: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct Attributes: TrackableSuperwallEvent {
    let appInstalledAtString: String
    var superwallEvent: SuperwallEvent {
      return .userAttributes(customParameters)
    }
    func getSuperwallParameters() async -> [String: Any] {
      return [
        "application_installed_at": appInstalledAtString
      ]
    }
    var customParameters: [String: Any] = [:]
  }

  struct DeepLink: TrackableSuperwallEvent {
    var superwallEvent: SuperwallEvent {
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

    var customParameters: [String: Any] {
      guard let urlComponents = URLComponents(
        url: url,
        resolvingAgainstBaseURL: false
      ) else {
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

  struct FirstSeen: TrackableSuperwallEvent {
    let superwallEvent: SuperwallEvent = .firstSeen
    var customParameters: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct Reset: TrackableSuperwallEvent {
    let superwallEvent: SuperwallEvent = .reset
    var customParameters: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct AppClose: TrackableSuperwallEvent {
    let superwallEvent: SuperwallEvent = .appClose
    var customParameters: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct SessionStart: TrackableSuperwallEvent {
    let superwallEvent: SuperwallEvent = .sessionStart
    var customParameters: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] { [:] }
  }

  struct DeviceAttributes: TrackableSuperwallEvent {
    var superwallEvent: SuperwallEvent {
      return .deviceAttributes(attributes: deviceAttributes)
    }
    let deviceAttributes: [String: Any]

    var customParameters: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] {
      return deviceAttributes
    }
  }

  struct PaywallLoad: TrackableSuperwallEvent {
    enum State {
      case start
      case notFound
      case fail
      case complete(paywallInfo: PaywallInfo)
    }
    let state: State

    var superwallEvent: SuperwallEvent {
      switch state {
      case .start:
        return .paywallResponseLoadStart(triggeredEventName: eventData?.name)
      case .notFound:
        return .paywallResponseLoadNotFound(triggeredEventName: eventData?.name)
      case .fail:
        return .paywallResponseLoadFail(triggeredEventName: eventData?.name)
      case .complete(let paywallInfo):
        return .paywallResponseLoadComplete(
          triggeredEventName: eventData?.name,
          paywallInfo: paywallInfo
        )
      }
    }
    let eventData: EventData?
    var customParameters: [String: Any] {
      switch state {
      case .complete(paywallInfo: let paywallInfo):
        return paywallInfo.customParams()
      default:
        return [:]
      }
    }

    func getSuperwallParameters() async -> [String: Any] {
      let fromEvent = eventData != nil
      let params: [String: Any] = [
        "is_triggered_from_event": fromEvent
      ]

      switch state {
      case .start,
        .notFound,
        .fail:
        return params
      case .complete(let paywallInfo):
        return await paywallInfo.eventParams(otherParams: params)
      }
    }
  }

  struct SubscriptionStatusDidChange: TrackableSuperwallEvent {
    let superwallEvent: SuperwallEvent = .subscriptionStatusDidChange
    let subscriptionStatus: SubscriptionStatus
    var customParameters: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] {
      return [
        "subscription_status": subscriptionStatus.description
      ]
    }
  }

  struct TriggerFire: TrackableSuperwallEvent {
    let triggerResult: InternalTriggerResult
    var superwallEvent: SuperwallEvent {
      return .triggerFire(
        eventName: triggerName,
        result: triggerResult.toPublicType()
      )
    }
    let triggerName: String
    var customParameters: [String: Any] = [:]
    let sessionEventsManager: SessionEventsManager

    func getSuperwallParameters() async -> [String: Any] {
      var params: [String: Any] = [
        "trigger_name": triggerName
      ]

      if let triggerSession = await sessionEventsManager.triggerSession.activeTriggerSession {
        params["trigger_session_id"] = triggerSession.id
      }

      switch triggerResult {
      case .noRuleMatch(let unmatchedRules):
        params += [
          "result": "no_rule_match"
        ]
        for unmatchedRule in unmatchedRules {
          params["unmatched_rule_\(unmatchedRule.experimentId)"] = unmatchedRule.source.rawValue
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
      case .eventNotFound:
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

  struct PresentationRequest: TrackableSuperwallEvent {
    let eventData: EventData?
    let type: PresentationRequestType
    let status: PaywallPresentationRequestStatus
    let statusReason: PaywallPresentationRequestStatusReason?
    let factory: RuleAttributesFactory & FeatureFlagsFactory & ComputedPropertyRequestsFactory

    var superwallEvent: SuperwallEvent {
      return .paywallPresentationRequest(
        status: status,
        reason: statusReason
      )
    }
    var customParameters: [String: Any] = [:]
    func getSuperwallParameters() async -> [String: Any] {
      var params = [
        "source_event_name": eventData?.name ?? "",
        "pipeline_type": type.description,
        "status": status.rawValue,
        "status_reason": statusReason?.description ?? ""
      ]

      if let featureFlags = factory.makeFeatureFlags(),
        featureFlags.enableExpressionParameters {
        let computedPropertyRequests = factory.makeComputedPropertyRequests()
        let rules = await factory.makeRuleAttributes(
          forEvent: eventData,
          withComputedProperties: computedPropertyRequests
        )

        if let rulesDictionary = rules.dictionaryObject,
          let jsonData = try? JSONSerialization.data(withJSONObject: rulesDictionary),
          let decoded = String(data: jsonData, encoding: .utf8) {
          params += [
            "expression_params": decoded
          ]
        }
      }

      return params
    }
  }

  struct PaywallOpen: TrackableSuperwallEvent {
    var superwallEvent: SuperwallEvent {
      return .paywallOpen(paywallInfo: paywallInfo)
    }
    let paywallInfo: PaywallInfo
    func getSuperwallParameters() async -> [String: Any] {
      return await paywallInfo.eventParams()
    }
    var customParameters: [String: Any] {
      return paywallInfo.customParams()
    }
  }

  struct PaywallClose: TrackableSuperwallEvent {
    var superwallEvent: SuperwallEvent {
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

      let eventParams = await paywallInfo.eventParams()
      params += eventParams
      return params
    }
    var customParameters: [String: Any] {
      return paywallInfo.customParams()
    }
  }

  struct PaywallDecline: TrackableSuperwallEvent {
    var superwallEvent: SuperwallEvent {
      return .paywallDecline(paywallInfo: paywallInfo)
    }
    let paywallInfo: PaywallInfo
    func getSuperwallParameters() async -> [String: Any] {
      return await paywallInfo.eventParams()
    }
    var customParameters: [String: Any] {
      return paywallInfo.customParams()
    }
  }

  struct Transaction: TrackableSuperwallEvent {
    enum State {
      case start(StoreProduct)
      case fail(TransactionError)
      case abandon(StoreProduct)
      case complete(StoreProduct, StoreTransaction?)
      case restore(RestoreType)
      case timeout
    }
    let state: State

    var superwallEvent: SuperwallEvent {
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
      case let .complete(product, model):
        return .transactionComplete(
          transaction: model,
          product: product,
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
    let paywallInfo: PaywallInfo
    let product: StoreProduct?
    let model: StoreTransaction?
    var customParameters: [String: Any] {
      return paywallInfo.customParams()
    }

    func getSuperwallParameters() async -> [String: Any] {
      switch state {
      case .restore:
        var eventParams = await paywallInfo.eventParams(forProduct: product)
        if let transactionDict = model?.dictionary(withSnakeCase: true) {
          eventParams += transactionDict
        }
        eventParams["restore_via_purchase_attempt"] = model != nil
        return eventParams
      case .start,
        .abandon,
        .complete,
        .timeout:
        var eventParams = await paywallInfo.eventParams(forProduct: product)
        if let transactionDict = model?.dictionary(withSnakeCase: true) {
          eventParams += transactionDict
        }
        return eventParams
      case .fail(let error):
        switch error {
        case .failure(let message, _),
          .pending(let message):
          return await paywallInfo.eventParams(
            forProduct: product,
            otherParams: ["message": message]
          )
        }
      }
    }
  }

  struct SubscriptionStart: TrackableSuperwallEvent {
    var superwallEvent: SuperwallEvent {
      return .subscriptionStart(product: product, paywallInfo: paywallInfo)
    }
    let paywallInfo: PaywallInfo
    let product: StoreProduct
    var customParameters: [String: Any] {
      return paywallInfo.customParams()
    }

    func getSuperwallParameters() async -> [String: Any] {
      return await paywallInfo.eventParams(forProduct: product)
    }
  }

  struct FreeTrialStart: TrackableSuperwallEvent {
    var superwallEvent: SuperwallEvent {
      return .freeTrialStart(
        product: product,
        paywallInfo: paywallInfo
      )
    }
    let paywallInfo: PaywallInfo
    let product: StoreProduct
    var customParameters: [String: Any] {
      return paywallInfo.customParams()
    }

    func getSuperwallParameters() async -> [String: Any] {
      return await paywallInfo.eventParams(forProduct: product)
    }
  }

  struct NonRecurringProductPurchase: TrackableSuperwallEvent {
    var superwallEvent: SuperwallEvent {
      return .nonRecurringProductPurchase(
        product: .init(product: product),
        paywallInfo: paywallInfo
      )
    }
    let paywallInfo: PaywallInfo
    let product: StoreProduct
    var customParameters: [String: Any] {
      return paywallInfo.customParams()
    }

    func getSuperwallParameters() async -> [String: Any] {
      return await paywallInfo.eventParams(forProduct: product)
    }
  }

  struct PaywallWebviewLoad: TrackableSuperwallEvent {
    enum State {
      case start
      case fail
      case timeout
      case complete
    }
    let state: State

    var superwallEvent: SuperwallEvent {
      switch state {
      case .start:
        return .paywallWebviewLoadStart(paywallInfo: paywallInfo)
      case .fail:
        return .paywallWebviewLoadFail(paywallInfo: paywallInfo)
      case .timeout:
        return .paywallWebviewLoadTimeout(paywallInfo: paywallInfo)
      case .complete:
        return .paywallWebviewLoadComplete(paywallInfo: paywallInfo)
      }
    }
    let paywallInfo: PaywallInfo

    func getSuperwallParameters() async -> [String: Any] {
      return await paywallInfo.eventParams()
    }
    var customParameters: [String: Any] {
      return paywallInfo.customParams()
    }
  }

  struct PaywallProductsLoad: TrackableSuperwallEvent {
    enum State {
      case start
      case fail
      case complete
    }
    let state: State
    var customParameters: [String: Any] {
      return paywallInfo.customParams()
    }

    var superwallEvent: SuperwallEvent {
      switch state {
      case .start:
        return .paywallProductsLoadStart(triggeredEventName: eventData?.name, paywallInfo: paywallInfo)
      case .fail:
        return .paywallProductsLoadFail(triggeredEventName: eventData?.name, paywallInfo: paywallInfo)
      case .complete:
        return .paywallProductsLoadComplete(triggeredEventName: eventData?.name)
      }
    }
    let paywallInfo: PaywallInfo
    let eventData: EventData?

    func getSuperwallParameters() async -> [String: Any] {
      let fromEvent = eventData != nil
      var params: [String: Any] = [
        "is_triggered_from_event": fromEvent
      ]
      params += await paywallInfo.eventParams()
      return params
    }
  }
}
