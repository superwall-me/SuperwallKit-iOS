//
//  File.swift
//  SuperwallKit
//
//  Created by Yusuf Tör on 23/09/2024.
//

import Foundation

final class AttributionPoster {
  private let attributionFetcher = AttributionFetcher()
  private let collectAdServicesAttribution: Bool
  private unowned let storage: Storage

  private var adServicesTokenToPostIfNeeded: String? {
    get async throws {
      #if os(tvOS) || os(watchOS)
      return nil
      #else
      guard #available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *) else {
        return nil
      }

      guard storage.get(AdServicesTokenStorage.self) == nil else {
        return nil
      }

      await Superwall.shared.track(InternalSuperwallEvent.AdServicesTokenRetrieval(state: .start))
      return try await attributionFetcher.adServicesToken
      #endif
    }
  }

  init(
    collectAdServicesAttribution: Bool,
    storage: Storage
  ) {
    self.collectAdServicesAttribution = collectAdServicesAttribution
    self.storage = storage

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationWillEnterForeground),
      name: SystemInfo.applicationWillEnterForegroundNotification,
      object: nil
    )
  }

  @objc
  private func applicationWillEnterForeground() {
    #if os(iOS) || os(macOS) || VISION_OS
    guard Superwall.isInitialized else {
      return
    }
    Task(priority: .background) {
      if #available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *) {
        await getAdServicesTokenIfNeeded()
      }
    }
    #endif
  }

  // Should match OS availability in https://developer.apple.com/documentation/ad_services
  @available(iOS 14.3, tvOS 14.3, watchOS 6.2, macOS 11.1, macCatalyst 14.3, *)
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  func getAdServicesTokenIfNeeded() async {
    do {
      guard collectAdServicesAttribution else {
        return
      }
      guard let token = try await adServicesTokenToPostIfNeeded else {
        return
      }

      storage.save(token, forType: AdServicesTokenStorage.self)

      await Superwall.shared.track(
        InternalSuperwallEvent.AdServicesTokenRetrieval(state: .complete(token))
      )
    } catch {
      await Superwall.shared.track(
        InternalSuperwallEvent.AdServicesTokenRetrieval(state: .fail(error))
      )
    }
  }
}