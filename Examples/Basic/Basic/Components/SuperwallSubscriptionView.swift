//
//  SuperwallEntitlementsView.swift
//  SuperwallSwiftUIExample
//
//  Created by Yusuf Tör on 15/03/2022.
//

import SwiftUI
import SuperwallKit

struct SuperwallSubscriptionView: View {
  @StateObject private var entitlements = Superwall.shared.entitlements // ensures entitlements is auto updating
  var text: String {
    // These are published properties that auto-update
    switch entitlements.status {
    case .unknown:
      return "Loading..."
    case .inactive:
      return "You are not subscribed so a paywall will always show."
    case .active:
      return "You are subscribed so a paywall will not show. For the purposes of this app, delete and reinstall the app to clear your subscriptions."
    }
  }

  var body: some View {
    Text(text)
      .multilineTextAlignment(.center)
      .lineSpacing(5)
      .padding()
      .padding(.bottom, 20)
  }
}

#Preview {
  SuperwallSubscriptionView()
}
