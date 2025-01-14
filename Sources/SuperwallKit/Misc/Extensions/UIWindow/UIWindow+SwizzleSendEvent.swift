//
//  File.swift
//  
//
//  Created by Yusuf Tör on 01/09/2023.
//

import UIKit

extension UIWindow {
  /// Does a switcharoo with the UIWindow's `sendEvent` method and our own method so that
  /// we can intercept the first `began` touch event.
  static func swizzleSendEvent() {
    let originalSelector = #selector(UIWindow.sendEvent(_:))
    let swizzledSelector = #selector(swizzledSendEvent(_:))

    guard
      let originalMethod = class_getInstanceMethod(UIWindow.self, originalSelector),
      let swizzledMethod = class_getInstanceMethod(UIWindow.self, swizzledSelector)
    else {
      return
    }

    method_exchangeImplementations(originalMethod, swizzledMethod)
  }

  /// Tracks a `.touchesBegan` event for the first `began` touch event received on the `UIWindow`.
  @objc private func swizzledSendEvent(_ event: UIEvent) {
    if event.type == .touches {
      // Check for a began touch event.
      guard
        let allTouches = event.allTouches,
        !allTouches.filter({ $0.phase == .began }).isEmpty
      else {
        // If there aren't any touches or there isn't a touches began event,
        // forward touch to original `sendEvent` function.
        swizzledSendEvent(event)
        return
      }
      Task {
        let touchesBegan = InternalSuperwallPlacement.TouchesBegan()
        await Superwall.shared.track(touchesBegan)
      }

      // Call the original implementation of sendEvent after tracking touchesBegan.
      swizzledSendEvent(event)

      // Then reverse the swizzle because we're only interested in the first began touch event.
      Self.swizzleSendEvent()
    } else {
      // Call the original implementation of sendEvent if the event we
      // receive isn't a touch.
      swizzledSendEvent(event)
    }
  }
}
