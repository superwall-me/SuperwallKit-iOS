//
//  File.swift
//  
//
//  Created by Yusuf Tör on 03/06/2024.
//

import Foundation

/// Information about the presentation of the paywall.
@objc(SWKPaywallPresentationInfo)
@objcMembers
public final class PaywallPresentationInfo: NSObject, Codable {
  /// The presentation style of the paywall.
  public let style: PaywallPresentationStyle

  /// The delay in milliseconds before switching from the loading view to
  /// the paywall view.
  public let delay: Int

  init(
    style: PaywallPresentationStyle = .modal,
    delay: Int
  ) {
    self.style = style
    self.delay = delay
  }
}
