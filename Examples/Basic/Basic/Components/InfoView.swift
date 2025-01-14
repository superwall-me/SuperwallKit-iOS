//
//  InfoView.swift
//  SuperwallSwiftUIExample
//
//  Created by Yusuf Tör on 16/03/2022.
//

import SwiftUI

struct InfoView: View {
  var text: String

  var body: some View {
    Text("\(Image(systemName: "info.circle.fill")) \(text)")
      .lineSpacing(5)
      .multilineTextAlignment(.leading)
      .padding()
  }
}

#Preview {
  InfoView(text: "example")
}
