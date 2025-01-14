//
//  File.swift
//
//
//  Created by Yusuf Tör on 20/04/2022.
//

import Foundation
import StoreKit

enum TrackingLogic {
  enum ImplicitTriggerOutcome {
    case triggerPaywall
    case deepLinkTrigger
    case dontTriggerPaywall
    case closePaywallThenTriggerPaywall
  }

  static func processParameters(
    fromTrackablePlacement trackablePlacement: Trackable,
    appSessionId: String
  ) async -> TrackingParameters {
    var superwallParameters = await trackablePlacement.getSuperwallParameters()
    superwallParameters["app_session_id"] = appSessionId

    let uncleanPlacementAudienceFilterParams = trackablePlacement.audienceFilterParams
    let placementName = trackablePlacement.rawName

    var delegateParams: [String: Any] = [
      "is_superwall": true
    ]

    // Add a special property if it's a superwall placement
    let isSuperwallPlacement = trackablePlacement is TrackableSuperwallPlacement

    var audienceFilterParams: [String: Any] = [
      "$is_standard_event": isSuperwallPlacement,
      "$event_name": placementName,
      "event_name": placementName
    ]

    // Filter then assign Superwall parameters
    for key in superwallParameters.keys {
      guard let value = clean(input: superwallParameters[key]) else {
        continue
      }

      let keyWithDollar = "$\(key)"
      audienceFilterParams[keyWithDollar] = value

      // no $ for delegate methods
      delegateParams[key] = value
    }

    // Filter then assign custom parameters
    for key in uncleanPlacementAudienceFilterParams.keys {
      guard let value = clean(input: uncleanPlacementAudienceFilterParams[key]) else {
        Logger.debug(
          logLevel: .debug,
          scope: .placements,
          message: "Dropping Key",
          info: ["key": key, "name": placementName, "reason": "Failed to serialize value"]
        )
        continue
      }

      if key.starts(with: "$") {
        Logger.debug(
          logLevel: .info,
          scope: .placements,
          message: "Dropping Key",
          info: ["key": key, "name": placementName, "reason": "$ signs not allowed"]
        )
      } else {
        delegateParams[key] = value
        audienceFilterParams[key] = value
      }
    }

    return TrackingParameters(
      delegateParams: delegateParams,
      audienceFilterParams: audienceFilterParams
    )
  }

  static func isNotDisabledVerbosePlacement(
    _ placement: Trackable,
    disableVerbosePlacements: Bool?,
    isSandbox: Bool
  ) -> Bool {
    guard let disableVerbosePlacements = disableVerbosePlacements else {
      return true
    }
    if isSandbox {
      return true
    }

    if placement is InternalSuperwallPlacement.PresentationRequest {
      return !disableVerbosePlacements
    }

    if let placement = placement as? InternalSuperwallPlacement.PaywallLoad {
      switch placement.state {
      case .start, .complete:
        return !disableVerbosePlacements
      default:
        return true
      }
    }

    if placement is InternalSuperwallPlacement.ShimmerLoad {
      return !disableVerbosePlacements
    }

    if let placement = placement as? InternalSuperwallPlacement.PaywallProductsLoad {
      switch placement.state {
      case .start, .complete:
        return !disableVerbosePlacements
      default:
        return true
      }
    }

    if let placement = placement as? InternalSuperwallPlacement.PaywallWebviewLoad {
      switch placement.state {
      case .start, .complete:
        return !disableVerbosePlacements
      default:
        return true
      }
    }

    return true
  }

  /// Makes optional variables non-optional. Removes `nil`, `NSArray`, `NSDictionary`, and anything that can't be `JSON`, `Date` or `URL`.
  private static func clean(input: Any?) -> Any? {
    guard let input = input else {
      return nil
    }
    if input is NSArray {
      return nil
    } else if input is NSDictionary {
      return nil
    } else {
      let json = JSON(input)
      if json.error == nil {
        return input
      } else {
        if let date = input as? Date {
          return date.isoString
        } else if let url = input as? URL {
          return url.absoluteString
        } else {
          return nil
        }
      }
    }
  }

  /// Checks whether the user is tracking a placement with the same name as a superwall placement.
  static func checkNotSuperwallPlacement(_ placement: String) throws {
    for superwallPlacement in SuperwallPlacementObjc.allCases
    where superwallPlacement.description == placement {
      Logger.debug(
        logLevel: .error,
        scope: .paywallPresentation,
        message: "Do not track a placement with the same name as a SuperwallPlacement",
        info: ["placement": placement]
      )
      let userInfo: [String: Any] = [
        NSLocalizedDescriptionKey: NSLocalizedString(
          "",
          value: "Do not track a placement with the same name as a SuperwallPlacement",
          comment: ""
        )
      ]
      let error = NSError(
        domain: "com.superwall",
        code: 400,
        userInfo: userInfo
      )
      throw error
    }
  }

  static func canTriggerPaywall(
    _ placement: Trackable,
    triggers: Set<String>,
    paywallViewController: PaywallViewController?
  ) -> ImplicitTriggerOutcome {
    if let placement = placement as? TrackableSuperwallPlacement,
      case .deepLink = placement.superwallPlacement {
      return .deepLinkTrigger
    }

    guard triggers.contains(placement.rawName) else {
      return .dontTriggerPaywall
    }

    // referring placements in this set are not able to trigger another
    // another paywall. prevents loops from occurring
    let notAllowedReferringPlacementNames: Set<String> = [
      SuperwallPlacementObjc.transactionAbandon.description,
      SuperwallPlacementObjc.transactionFail.description,
      SuperwallPlacementObjc.paywallDecline.description,
      SuperwallPlacementObjc.customPlacement.description
    ]

    if let referringPlacementName = paywallViewController?.info.presentedByPlacementWithName,
      notAllowedReferringPlacementNames.contains(referringPlacementName) {
      return .dontTriggerPaywall
    }

    if let placement = placement as? TrackableSuperwallPlacement,
      case .transactionAbandon = placement.superwallPlacement {
      return .closePaywallThenTriggerPaywall
    }

    if let placement = placement as? TrackableSuperwallPlacement,
      case .transactionFail = placement.superwallPlacement {
      return .closePaywallThenTriggerPaywall
    }

    if let placement = placement as? TrackableSuperwallPlacement,
      case .paywallDecline = placement.superwallPlacement {
      return .closePaywallThenTriggerPaywall
    }

    if let placement = placement as? TrackableSuperwallPlacement,
      case .customPlacement = placement.superwallPlacement {
      return .closePaywallThenTriggerPaywall
    }

    if let placement = placement as? TrackableSuperwallPlacement,
      case .surveyResponse = placement.superwallPlacement {
      return .closePaywallThenTriggerPaywall
    }

    if paywallViewController != nil {
      return .dontTriggerPaywall
    }

    return .triggerPaywall
  }
}
