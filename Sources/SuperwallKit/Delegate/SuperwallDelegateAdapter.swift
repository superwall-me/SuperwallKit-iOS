//
//  File.swift
//  
//
//  Created by Yusuf Tör on 18/10/2022.
//

import Foundation
import Combine
import StoreKit

/// An adapter between the internal SDK and the public swift/objective c delegate.
final class SuperwallDelegateAdapter {
  var swiftDelegate: SuperwallDelegate?
  var objcDelegate: SuperwallDelegateObjc?

  @MainActor
  func handleCustomPaywallAction(withName name: String) {
    if let swiftDelegate = swiftDelegate {
      swiftDelegate.handleCustomPaywallAction(withName: name)
    } else if let objcDelegate = objcDelegate {
      objcDelegate.handleCustomPaywallAction?(withName: name)
    }
  }

  @MainActor
  func willDismissPaywall(withInfo paywallInfo: PaywallInfo) {
    if let swiftDelegate = swiftDelegate {
      swiftDelegate.willDismissPaywall(withInfo: paywallInfo)
    } else if let objcDelegate = objcDelegate {
      objcDelegate.willDismissPaywall?(withInfo: paywallInfo)
    }
  }

  @MainActor
  func willPresentPaywall(withInfo paywallInfo: PaywallInfo) {
    if let swiftDelegate = swiftDelegate {
      swiftDelegate.willPresentPaywall(withInfo: paywallInfo)
    } else if let objcDelegate = objcDelegate {
      objcDelegate.willPresentPaywall?(withInfo: paywallInfo)
    }
  }

  @MainActor
  func didDismissPaywall(withInfo paywallInfo: PaywallInfo) {
    if let swiftDelegate = swiftDelegate {
      swiftDelegate.didDismissPaywall(withInfo: paywallInfo)
    } else if let objcDelegate = objcDelegate {
      objcDelegate.didDismissPaywall?(withInfo: paywallInfo)
    }
  }

  @MainActor
  func didPresentPaywall(withInfo paywallInfo: PaywallInfo) {
    if let swiftDelegate = swiftDelegate {
      swiftDelegate.didPresentPaywall(withInfo: paywallInfo)
    } else if let objcDelegate = objcDelegate {
      objcDelegate.didPresentPaywall?(withInfo: paywallInfo)
    }
  }

  @MainActor
  func paywallWillOpenURL(url: URL) {
    if let swiftDelegate = swiftDelegate {
      swiftDelegate.paywallWillOpenURL(url: url)
    } else if let objcDelegate = objcDelegate {
      objcDelegate.paywallWillOpenURL?(url: url)
    }
  }

  @MainActor
  func paywallWillOpenDeepLink(url: URL) {
    if let swiftDelegate = swiftDelegate {
      swiftDelegate.paywallWillOpenDeepLink(url: url)
    } else if let objcDelegate = objcDelegate {
      objcDelegate.paywallWillOpenDeepLink?(url: url)
    }
  }

  @MainActor
  func handleSuperwallPlacement(withInfo placementInfo: SuperwallPlacementInfo) {
    if let swiftDelegate = swiftDelegate {
      swiftDelegate.handleSuperwallPlacement(withInfo: placementInfo)
    } else if let objcDelegate = objcDelegate {
      objcDelegate.handleSuperwallPlacement?(withInfo: placementInfo)
    }
  }

  @MainActor
  func entitlementStatusDidChange(
    from oldValue: EntitlementStatus,
    to newValue: EntitlementStatus
  ) {
    if let swiftDelegate = swiftDelegate {
      swiftDelegate.entitlementStatusDidChange(
        from: oldValue,
        to: newValue
      )
    } else if let objcDelegate = objcDelegate {
      objcDelegate.entitlementStatusDidChange?(
        from: oldValue.toObjc(),
        to: newValue.toObjc()
      )
    }
  }

  @MainActor
  func handleLog(
    level: String,
    scope: String,
    message: String?,
    info: [String: Any]?,
    error: Swift.Error?
  ) {
    if let swiftDelegate = swiftDelegate {
      swiftDelegate.handleLog(
        level: level,
        scope: scope,
        message: message,
        info: info,
        error: error
      )
    } else if let objcDelegate = objcDelegate {
      objcDelegate.handleLog?(
        level: level,
        scope: scope,
        message: message,
        info: info,
        error: error
      )
    }
  }
}
