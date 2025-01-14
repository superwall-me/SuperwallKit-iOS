//
//  BrandedButton.swift
//  SuperwallSwiftUIExample
//
//  Created by Yusuf Tör on 11/03/2022.
//

import SwiftUI

struct BrandedButton: View {
  let title: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.title3.weight(.semibold))
        .foregroundColor(.primaryTeal100)
        .frame(height: 60)
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity)
    }
    .background(Color.primaryTeal300)
    .clipShape(Capsule())
    .frame(maxWidth: 500)
  }
}

#Preview {
  BrandedButton(title: "Test button") {}
}
