//
//  PaywallResponseLogic.swift
//  Paywall
//
//  Created by Yusuf Tör on 03/03/2022.
//

import Foundation
import StoreKit

struct ResponseIdentifiers: Equatable {
  let paywallId: String?
  var experiment: Experiment?

  static var none: ResponseIdentifiers {
    return  .init(paywallId: nil)
  }
}

struct ProductProcessingOutcome {
  var variables: [Variable]
  var productVariables: [ProductVariable]
  var orderedSwProducts: [SWProduct]
  var isFreeTrialAvailable: Bool?
  var resetFreeTrialOverride: Bool
}

enum PaywallResponseLogic {
  static func requestHash(
    identifier: String? = nil,
    event: EventData? = nil,
    locale: String = DeviceHelper.shared.locale
  ) -> String {
    let id = identifier ?? event?.name ?? "$called_manually"
    return "\(id)_\(locale)"
  }

  static func getTriggerResultAndConfirmAssignment(
    presentationInfo: PresentationInfo,
    configManager: ConfigManager = .shared,
    storage: Storage = .shared,
    triggers: [String: Trigger]
  ) -> TriggerResultOutcome {
    if let eventData = presentationInfo.eventData {
      let triggerAssignmentOutcome = AssignmentLogic.getOutcome(
        forEvent: eventData,
        triggers: triggers,
        configManager: configManager,
        storage: storage
      )

      // Confirm any triggers that the user is assigned
      if let confirmableAssignment = triggerAssignmentOutcome.confirmableAssignment {
        configManager.confirmAssignments(confirmableAssignment)
      }

      return getOutcome(forResult: triggerAssignmentOutcome.result)
    } else {
      let identifiers = ResponseIdentifiers(paywallId: presentationInfo.identifier)
      return TriggerResultOutcome(
        info: .paywall(identifiers)
      )
    }
  }

  private static func getOutcome(
    forResult triggerResult: TriggerResult
  ) -> TriggerResultOutcome {
    switch triggerResult {
    case .paywall(let experiment):
      let identifiers = ResponseIdentifiers(
        paywallId: experiment.variant.paywallId,
        experiment: experiment
      )
      return TriggerResultOutcome(
        info: .paywall(identifiers),
        result: triggerResult
      )
    case let .holdout(experiment):
      return TriggerResultOutcome(
        info: .holdout(experiment),
        result: triggerResult
      )
    case .noRuleMatch:
      return TriggerResultOutcome(
        info: .noRuleMatch,
        result: triggerResult
      )
    case .triggerNotFound:
      return TriggerResultOutcome(
        info: .triggerNotFound,
        result: triggerResult
      )
    case .error(let error):
      return TriggerResultOutcome(
        info: .error(error),
        result: triggerResult
      )
    }
  }

  static func handlePaywallError(
    _ error: Error,
    forEvent event: EventData?,
    trackEvent: (Trackable) -> TrackingResult = Superwall.track
  ) -> NSError {
    if let error = error as? CustomURLSession.NetworkError,
      error == .notFound {
      let trackedEvent = InternalSuperwallEvent.PaywallResponseLoad(
        state: .notFound,
        eventData: event
      )
      _ = trackEvent(trackedEvent)
    } else {
      let trackedEvent = InternalSuperwallEvent.PaywallResponseLoad(
        state: .fail,
        eventData: event
      )
      _ = trackEvent(trackedEvent)
    }

    let userInfo: [String: Any] = [
      NSLocalizedDescriptionKey: NSLocalizedString(
        "Not Found",
        value: "There isn't a paywall configured to show in this context",
        comment: ""
      )
    ]
    let error = NSError(
      domain: "SWPaywallNotFound",
      code: 404,
      userInfo: userInfo
    )
    return error
  }

  static func getVariablesAndFreeTrial(
    fromProducts products: [Product],
    productsById: [String: SKProduct],
    isFreeTrialAvailableOverride: Bool?,
    hasPurchased: @escaping (String) -> Bool = InAppReceipt.shared.hasPurchasedInSubscriptionGroupOfProduct(withId:)
  ) -> ProductProcessingOutcome {
    var legacyVariables: [Variable] = []
    var newVariables: [ProductVariable] = []
    var isFreeTrialAvailable: Bool?
    var resetFreeTrialOverride = false
    var orderedSwProducts: [SWProduct] = []

    for product in products {
      // Get skproduct
      guard let appleProduct = productsById[product.id] else {
        continue
      }
      orderedSwProducts.append(appleProduct.swProduct)

      let legacyVariable = Variable(
        key: product.type.rawValue,
        value: appleProduct.eventData
      )
      legacyVariables.append(legacyVariable)

      let productVariable = ProductVariable(
        key: product.type.rawValue,
        value: appleProduct.productVariables
      )
      newVariables.append(productVariable)

      if product.type == .primary {
        isFreeTrialAvailable = appleProduct.hasFreeTrial
        if hasPurchased(product.id),
          appleProduct.hasFreeTrial {
          isFreeTrialAvailable = false
        }
        // use the override if it is set
        if let freeTrialOverride = isFreeTrialAvailableOverride {
          isFreeTrialAvailable = freeTrialOverride
          resetFreeTrialOverride = true
        }
      }
    }

    return ProductProcessingOutcome(
      variables: legacyVariables,
      productVariables: newVariables,
      orderedSwProducts: orderedSwProducts,
      isFreeTrialAvailable: isFreeTrialAvailable,
      resetFreeTrialOverride: resetFreeTrialOverride
    )
  }
}