//
//  File.swift
//  SuperwallKit
//
//  Created by Yusuf Tör on 23/09/2024.
//

import Foundation
import Combine

final class AttributionPoster {
  private let attributionFetcher = AttributionFetcher()
  private var isCollecting = false

  private unowned let storage: Storage
  private unowned let network: Network
  private unowned let configManager: ConfigManager
  private var cancellables: [AnyCancellable] = []

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

      await Superwall.shared.track(InternalSuperwallPlacement.AdServicesTokenRetrieval(state: .start))
      return try await attributionFetcher.adServicesToken
      #endif
    }
  }

  init(
    storage: Storage,
    network: Network,
    configManager: ConfigManager
  ) {
    self.storage = storage
    self.network = network
    self.configManager = configManager

    if #available(iOS 14.3, *) {
      listenToConfig()
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationWillEnterForeground),
      name: SystemInfo.applicationWillEnterForegroundNotification,
      object: nil
    )
  }


  @available(iOS 14.3, *)
  private func listenToConfig() {
    configManager.configState
      .compactMap { $0.getConfig() }
      .first { config in
        config.attribution?.appleSearchAds?.enabled == true
      }
      .sink(
        receiveCompletion: { _ in },
        receiveValue: { _ in
          Task { [weak self] in
            await self?.getAdServicesTokenIfNeeded()
          }
        }
      )
      .store(in: &cancellables)
  }

  @objc
  private func applicationWillEnterForeground() {
    #if os(iOS) || os(macOS) || os(visionOS)
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
    if isCollecting {
      return
    }
    defer {
      isCollecting = false
    }
    do {
      isCollecting = true
      guard configManager.config?.attribution?.appleSearchAds?.enabled == true else {
        return
      }
      guard let token = try await adServicesTokenToPostIfNeeded else {
        return
      }

      storage.save(token, forType: AdServicesTokenStorage.self)

      await Superwall.shared.track(
        InternalSuperwallPlacement.AdServicesTokenRetrieval(state: .complete(token))
      )

      let data = await network.sendToken(token)
      Superwall.shared.setUserAttributes(data)
    } catch {
      await Superwall.shared.track(
        InternalSuperwallPlacement.AdServicesTokenRetrieval(state: .fail(error))
      )
    }
  }
}
