//
//  HomeView.swift
//  SuperwallSwiftUIExample
//
//  Created by Yusuf Tör on 11/03/2022.
//

import SwiftUI
import SuperwallKit
import StoreKit

struct HomeView: View {
  @Binding var isLoggedIn: Bool
  @State private var page: Page?
  enum Page {
    case nonGated
    case pro
    case diamond
  }

  init(isLoggedIn: Binding<Bool>) {
    _isLoggedIn = isLoggedIn
    UINavigationBar.appearance().titleTextAttributes = [
      .foregroundColor: UIColor.white,
      .font: UIFont.rubikBold(.five)
    ]
  }

  var firstName: String? {
    Superwall.shared.userAttributes["firstName"] as? String
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text("Superwall Demo")
            .foregroundStyle(.black)
            .font(.largeTitle.weight(.bold))
          Spacer()
          Button(
            action: {
              Superwall.shared.reset()
              isLoggedIn = false
            }, label: {
              Text("Log Out")
              .foregroundStyle(.gray)
            }
          )
        }
        if let firstName = firstName,
          !firstName.isEmpty {
          Text("Hello \(firstName)!")
            .foregroundStyle(.gray)
        }
      }
      .padding()

      InfoView(
        text: "Each button below registers a placement. Each placement has been added to a campaign on the Superwall dashboard. When the placement is registered, the audience filters in the campaign are evaluated and attempt to show a paywall. Each product on the paywall is associated with an entitlement and Pro and Diamond features are gated behind their respective entitlements."
      )

      Divider()
        .background(Color.primaryTeal300)
        .padding()

      SuperwallEntitlementsView()

      VStack(spacing: 20) {
        BrandedButton(title: "Launch Non-Gated Feature") {
          Superwall.shared.register(placement: "non_gated") {
            page = .nonGated
          }
        }
        BrandedButton(title: "Launch Pro Feature") {
          Superwall.shared.register(placement: "pro") {
            page = .pro
          }
        }
        BrandedButton(title: "Launch Diamond Feature") {
          Superwall.shared.register(placement: "diamond") {
            page = .diamond
          }
        }
      }
      .padding(.horizontal)
    }
    .frame(maxHeight: .infinity)
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden()
    .navigationTitle("")
    .navigationDestination(item: $page) { page in
      ZStack {
        switch page {
        case .nonGated:
          Text("Non gated feature launched")
        case .pro:
          Text("Pro feature launched")
        case .diamond:
          Text("Diamond feature launched")
        }
      }
    }
  }
}

#Preview {
  HomeView(isLoggedIn: .constant(false))
}
