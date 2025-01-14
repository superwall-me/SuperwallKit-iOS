//
//  File.swift
//  
//
//  Created by Yusuf Tör on 20/04/2022.
//
// swiftlint:disable nesting

import Foundation

protocol TrackableUserInitiatedPlacement: Trackable {}

/// These are placements that are initiated by the user. Unlike `SuperwallTrackablePlacements`, they are not sent back to the delegate.
enum UserInitiatedPlacement {
  struct Track: TrackableUserInitiatedPlacement {
    let rawName: String
    let canImplicitlyTriggerPaywall: Bool
    var audienceFilterParams: [String: Any] = [:]
    var isFeatureGatable: Bool

    func getSuperwallParameters() async -> [String: Any] {
      return ["is_feature_gatable": isFeatureGatable]
    }
  }
  /*
  // MARK: - To be deprecated/deleted
  struct PushNotification: TrackableUserInitiatedPlacement {
    enum State {
      case receive
      case open
    }
    var rawName: String {
      switch state {
      case .open:
        return "pushNotification_open"
      case .receive:
        return "pushNotification_receive"
      }
    }
    func getSuperwallParameters() async -> [String: Any] {
      if let pushNotificationId = pushNotificationId {
        return ["push_notification_id": pushNotificationId]
      }
      return [:]
    }
    let state: State
    let pushNotificationId: String?
    let canImplicitlyTriggerPaywall = true
    var audienceFilterParams: [String: Any] = [:]
  }*/
}
