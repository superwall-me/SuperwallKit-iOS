//
//  File.swift
//  
//
//  Created by Yusuf Tör on 02/07/2024.
//

import Foundation

protocol Capability: Encodable {
  var name: String { get }
}

struct PaywallEventReceiverCapability: Capability {
  let name = "paywall_event_receiver"

  let eventNames = [
    SuperwallPlacementObjc.restoreStart.description,
    SuperwallPlacementObjc.restoreComplete.description,
    SuperwallPlacementObjc.restoreFail.description,
    SuperwallPlacementObjc.transactionRestore.description,
    SuperwallPlacementObjc.transactionStart.description,
    SuperwallPlacementObjc.transactionComplete.description,
    SuperwallPlacementObjc.transactionFail.description,
    SuperwallPlacementObjc.transactionAbandon.description,
    SuperwallPlacementObjc.transactionTimeout.description,
    SuperwallPlacementObjc.paywallOpen.description,
    SuperwallPlacementObjc.paywallClose.description
  ]
}

struct MultiplePaywallUrlsCapability: Capability {
  let name = "multiple_paywall_urls"
}

struct ConfigRefreshCapability: Capability {
  let name = "config_refresh"
}

struct ConfigCaching: Capability {
  let name = "config_caching"
}

struct WebViewTextInteractionCapability: Capability {
  let name = "webview_text_interaction"
}
