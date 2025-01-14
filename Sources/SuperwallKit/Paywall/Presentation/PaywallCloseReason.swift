//
//  File.swift
//  
//
//  Created by Jake Mor on 4/29/23.
//

import Foundation

/// An enum whose cases indicate whether the paywall was closed by user
/// interaction or because another paywall will show.
@objc(SWKPaywallCloseReason)
public enum PaywallCloseReason: Int, Codable, Equatable, Sendable, CustomStringConvertible {
  /// The paywall was closed by system logic, either after a purchase or because
  /// a deeplink was presented.
  case systemLogic

  /// The paywall was automatically closed because another paywall will show.
  ///
  /// This prevents ``Superwall/register(placement:params:handler:feature:)`` `feature`
  /// block from executing on dismiss of the paywall, because another paywall is set to show
  case forNextPaywall

  /// The paywall was closed because the webview couldn't be loaded.
  ///
  /// If this happens for a gated paywall, the ``PaywallPresentationHandler/onError(_:)``
  /// handler will be called. If it's for a non-gated paywall, the feature block will be called.
  case webViewFailedToLoad

  /// The paywall was closed because the user tapped the close button or dragged to dismiss.
  case manualClose

  /// The paywall hasn't been closed yet.
  case none

  public var description: String {
    switch self {
    case .systemLogic:
      return "systemLogic"
    case .forNextPaywall:
      return "forNextPaywall"
    case .webViewFailedToLoad:
      return "webViewFailedToLoad"
    case .manualClose:
      return "manualClose"
    case .none:
      return "none"
    }
  }

  /// Indicates whether the paywall state publisher should receive a completion.
  var stateShouldComplete: Bool {
    switch self {
    case .forNextPaywall:
      return false
    default:
      return true
    }
  }
}
