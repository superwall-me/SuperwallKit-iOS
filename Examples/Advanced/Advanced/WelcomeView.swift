//
//  WelcomeView.swift
//  SuperwallSwiftUIExample
//
//  Created by Yusuf Tör on 14/03/2022.
//

import SwiftUI
import SuperwallKit

struct WelcomeView: View {
  @Binding var isLoggedIn: Bool
  @State private var name: String = ""

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .center, spacing: 40) {
          Spacer()
          logo()
          Spacer()
          Text("Welcome! Enter your name to get started. Your name will be added to the Superwall user attributes, which can then be  accessed and displayed within your paywall.")
            .lineSpacing(5)
            .multilineTextAlignment(.leading)
          inputField()
          Spacer()
          logInButton()
        }
        .padding()
        .frame(maxHeight: .infinity)
      }
      .navigationDestination(isPresented: $isLoggedIn) {
        HomeView(isLoggedIn: $isLoggedIn)
      }
      .navigationBarHidden(true)
      .navigationTitle("")
    }
    .accentColor(.primaryTeal300)
    #if !os(visionOS)
    .scrollDismissesKeyboard(.immediately)
    #endif
  }

  private func logo() -> some View {
    VStack(spacing: 15) {
      Image("Logo")
        .resizable()
        .scaledToFit()
        .frame(width: 200)
        .cornerRadius(25)
      Text("Superwall Demo")
        .font(.title2)
    }
  }

  private func inputField() -> some View {
    TextField(
      "Enter your name",
      text: $name,
      prompt: Text("Enter your name")
          .foregroundStyle(Color.primaryTeal300)
    )
    .textContentType(.name)
    .textInputAutocapitalization(.never)
    .padding()
    .background(Color.primaryTeal100)
    .clipShape(Capsule())
  }

  @ViewBuilder
  private func logInButton() -> some View {
    BrandedButton(title: "Log In") {
      Superwall.shared.identify(userId: "abc")
      Superwall.shared.setUserAttributes(["firstName": name])
      isLoggedIn = true
    }
  }
}

#Preview {
  WelcomeView(isLoggedIn: .constant(false))
}
