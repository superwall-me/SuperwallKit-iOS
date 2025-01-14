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
    case gated
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
        text: "Each button below registers a placement. Each placement has been added to a campaign on the Superwall dashboard. When the placement is registered, the audience filters in the campaign are evaluated and attempt to show a paywall. If you are subscribed, a paywall won't show."
      )

      Divider()
        .background(Color.primaryTeal300)
        .padding()

      SuperwallSubscriptionView()

      VStack(spacing: 20) {
        BrandedButton(title: "Launch Non-Gated Feature") {
          Superwall.shared.register(placement: "non_gated_pro") {
            page = .nonGated
          }
        }
        BrandedButton(title: "Launch Gated Feature") {
          Superwall.shared.register(placement: "gated_pro") {
            page = .gated
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
        case .gated:
          Text("Gated feature launched")
        }
      }
    }
  }
}

#Preview {
  HomeView(isLoggedIn: .constant(false))
}
