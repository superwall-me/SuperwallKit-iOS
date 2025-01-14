//
//  File.swift
//  SuperwallKit
//
//  Created by Yusuf Tör on 26/09/2024.
//
// swiftlint:disable identifier_name

#if os(iOS) || os(tvOS) || os(visionOS) || targetEnvironment(macCatalyst)
import UIKit
#elseif os(watchOS)
import UIKit
import WatchKit
#elseif os(macOS)
import AppKit
#endif

enum SystemInfo {
  static var applicationWillEnterForegroundNotification: Notification.Name {
    #if os(iOS) || os(tvOS) || os(visionOS)
    UIApplication.willEnterForegroundNotification
    #elseif os(macOS)
    NSApplication.willBecomeActiveNotification
    #elseif os(watchOS)
    Notification.Name.NSExtensionHostWillEnterForeground
    #endif
  }

  static var applicationDidBecomeActiveNotification: Notification.Name? {
    #if os(iOS) || os(tvOS) || os(visionOS) || targetEnvironment(macCatalyst)
    return UIApplication.didBecomeActiveNotification
    #elseif os(macOS)
    return NSApplication.didBecomeActiveNotification
    #elseif os(watchOS)
    if #available(watchOS 9, *) {
      return WKApplication.didBecomeActiveNotification
    } else if #available(watchOS 7, *) {
      // Work around for "Symbol not found" dyld crashes on watchOS 7.0..<9.0
      return Notification.Name("WKApplicationDidBecomeActiveNotification")
    } else {
      // There's no equivalent notification available on watchOS <7.
      return nil
    }
    #endif
  }
}
