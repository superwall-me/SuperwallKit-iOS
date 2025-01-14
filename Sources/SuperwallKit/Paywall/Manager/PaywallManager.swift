//
//  File.swift
//
//
//  Created by Jake Mor on 11/15/21.
//

import Foundation
import UIKit

class PaywallManager {
  var presentedViewController: PaywallViewController? {
    return cache.activePaywallViewController
	}
  private let queue = DispatchQueue(label: "com.superwall.paywallmanager")
  private unowned let paywallRequestManager: PaywallRequestManager
  private unowned let factory: ViewControllerFactory
    & CacheFactory
    & DeviceHelperFactory
    & PaywallArchiveManagerFactory

  private var cache: PaywallViewControllerCache {
    return queue.sync { _cache ?? createCache() }
  }
  private var _cache: PaywallViewControllerCache?

  private var paywallArchiveManager: PaywallArchiveManager {
    return queue.sync { _paywallArchiveManager ?? createPaywallArchiveManager() }
  }
  private var _paywallArchiveManager: PaywallArchiveManager?

  init(
    factory: ViewControllerFactory
      & CacheFactory
      & DeviceHelperFactory
      & PaywallArchiveManagerFactory,
    paywallRequestManager: PaywallRequestManager
  ) {
    self.factory = factory
    self.paywallRequestManager = paywallRequestManager
  }

  private func createCache() -> PaywallViewControllerCache {
    let cache = factory.makeCache()
    _cache = cache
    return cache
  }

  private func createPaywallArchiveManager() -> PaywallArchiveManager {
    let paywallArchiveManager = factory.makePaywallArchiveManager()
    _paywallArchiveManager = paywallArchiveManager
    return paywallArchiveManager
  }

	func resetCache() {
		cache.removeAll()
	}

  /// Removes cached `Paywall` and `PaywallViewController` objects so that
  /// they can be fetched again when the config refreshes.
  func removePaywalls(withIds ids: Set<String>) async {
    await paywallRequestManager.removePaywalls(withIds: ids)

    let deviceInfo = factory.makeDeviceInfo()

    for id in ids {
      let cacheKey = PaywallCacheLogic.key(
        identifier: id,
        locale: deviceInfo.locale
      )
      cache.removePaywallViewController(forKey: cacheKey)
    }
  }

  func getPaywall(from request: PaywallRequest) async throws -> Paywall {
    return try await paywallRequestManager.getPaywall(from: request)
  }

  /// Tries to preload the archive for the paywall, if available.
  ///
  /// - Parameter paywall: The paywall whose archive to preload.
  func attemptToPreloadArchive(from paywall: Paywall) async {
    await paywallArchiveManager.preloadArchive(paywall: paywall)
  }

  /// Gets the paywall view controller for a given paywall.
  @MainActor
  func getViewController(
    for paywall: Paywall,
    isDebuggerLaunched: Bool,
    isForPresentation: Bool,
    isPreloading: Bool,
    delegate: PaywallViewControllerDelegateAdapter?
  ) async throws -> PaywallViewController {
    let deviceInfo = factory.makeDeviceInfo()
    let cacheKey = PaywallCacheLogic.key(
      identifier: paywall.identifier,
      locale: deviceInfo.locale
    )

    if !isDebuggerLaunched,
      let viewController = self.cache.getPaywallViewController(forKey: cacheKey) {
      let outcomes = PaywallManagerLogic.handleCachedPaywall(
        newPaywall: paywall,
        oldPaywall: viewController.paywall,
        isPreloading: isPreloading,
        isForPresentation: isForPresentation
      )

      for outcome in outcomes {
        switch outcome {
        case .loadWebView:
          viewController.loadWebView()
        case .replacePaywall:
          viewController.paywall = paywall
        case .setDelegate:
          viewController.delegate = delegate
        case .updatePaywall:
          viewController.paywall.update(from: paywall)
        }
      }

      return viewController
    }

    let paywallViewController = factory.makePaywallViewController(
      for: paywall,
      withCache: cache,
      withPaywallArchiveManager: paywallArchiveManager,
      delegate: delegate
    )
    cache.save(paywallViewController, forKey: cacheKey)

    if isForPresentation {
      // Only preload if it's actually gonna present the view.
      // Not if we're just checking it's result
      paywallViewController.loadViewIfNeeded()
    }

    return paywallViewController
  }
}
