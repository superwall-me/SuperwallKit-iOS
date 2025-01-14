//
//  Font.swift
//  SuperwallSwiftUIExample
//
//  Created by Yusuf Tör on 11/03/2022.
//

import SwiftUI

extension Font {
  static func rubik(_ size: Styles.FontSize) -> Font {
    return .custom("Rubik-Regular", size: size.rawValue)
  }

  static func rubikBold(_ size: Styles.FontSize) -> Font {
    return .custom("Rubik-Bold", size: size.rawValue)
  }
}

extension UIFont {
  static func rubikBold(_ size: Styles.FontSize) -> UIFont {
    // swiftlint:disable:next force_unwrapping
    return UIFont(name: "Rubik-Bold", size: size.rawValue)!
  }
}
