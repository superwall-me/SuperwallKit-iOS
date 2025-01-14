//
//  File.swift
//  
//
//  Created by Yusuf Tör on 03/05/2022.
//

import Foundation

/// Contains information about the presentation of a paywall.
enum PresentationInfo {
  case implicitTrigger(PlacementData)
  case explicitTrigger(PlacementData)

  /// Only used in the `DebugViewController`
  case fromIdentifier(_ identifier: String, freeTrialOverride: Bool)

  var freeTrialOverride: Bool? {
    switch self {
    case .fromIdentifier(_, let freeTrialOverride):
      return freeTrialOverride
    default:
      return nil
    }
  }

  var placementData: PlacementData? {
    switch self {
    case let .implicitTrigger(placementData),
      let .explicitTrigger(placementData):
      return placementData
    default:
      return nil
    }
  }

  var placementName: String? {
    switch self {
    case let .implicitTrigger(placementData),
      let .explicitTrigger(placementData):
      return placementData.name
    case .fromIdentifier:
      return nil
    }
  }

  var identifier: String? {
    switch self {
    case .fromIdentifier(let identifier, _):
      return identifier
    default:
      return nil
    }
  }
}
