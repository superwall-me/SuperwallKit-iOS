//
//  SuperwallEntitlementsView.swift
//  SuperwallSwiftUIExample
//
//  Created by Yusuf Tör on 15/03/2022.
//

import SwiftUI
import SuperwallKit

struct SuperwallEntitlementsView: View {
  @StateObject private var entitlements = Superwall.shared.entitlements // ensures entitlements is auto updating
  var text: String {
    // These are published properties that auto-update
    switch entitlements.status {
    case .unknown:
      return "Loading active entitlements."
    case .inactive:
      return "You do not have any active entitlements so a paywall will always show."
    case .active(let entitlements):
      return "You currently have the \(entitlements.map { $0.id }.joined(separator: " and ")) entitlement. For the purposes of this app, delete and reinstall the app to clear entitlements."
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
  SuperwallEntitlementsView()
}
