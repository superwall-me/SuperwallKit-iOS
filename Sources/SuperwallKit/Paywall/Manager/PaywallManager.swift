//
//  File.swift
//
//
//  Created by Jake Mor on 11/15/21.
//

import Foundation
import UIKit

class PaywallManager {
  let factory: DependencyContainer

  var presentedViewController: PaywallViewController? {
    return cache.activePaywallViewController
	}
  private let queue = DispatchQueue(label: "com.superwall.paywallmanager")
  private var paywallRequestManager: PaywallRequestManager {
    return factory.paywallRequestManager
  }

  private var cache: PaywallViewControllerCache {
    return queue.sync { _cache ?? createCache() }
  }
  private var _cache: PaywallViewControllerCache?

  init(factory: DependencyContainer) {
    self.factory = factory
  }

  private func createCache() -> PaywallViewControllerCache {
    let cache = factory.makeCache()
    _cache = cache
    return cache
  }

	func removePaywallViewController(forKey key: String) {
    cache.removePaywallViewController(forKey: key)
	}

	func resetCache() {
		cache.removeAll()
	}

  /// First, this gets the paywall response for a specified paywall identifier or trigger event.
  /// It then creates the paywall view controller from that response, and caches it.
  ///
  /// If no `identifier` or `event` is specified, this gets the default paywall for the user.
  ///
  /// - Parameters:
  ///   - request: The request to get the paywall.
  ///   - isForPresentation: Indicates whether the paywall will be
  ///   presented.
  ///   - isPreloading: Whether or not the paywall is being preloaded.
  ///   - delegate: The delegate for the `PaywallViewController`.
  @MainActor
  func getPaywallViewController(
    from request: PaywallRequest,
    isForPresentation: Bool,
    isPreloading: Bool,
    delegate: PaywallViewControllerDelegateAdapter?
  ) async throws -> PaywallViewController {
    let paywall = try await paywallRequestManager.getPaywall(from: request)

    let deviceInfo = factory.makeDeviceInfo()
    let cacheKey = PaywallCacheLogic.key(
      identifier: paywall.identifier,
      locale: deviceInfo.locale
    )

    if !request.isDebuggerLaunched,
      let viewController = self.cache.getPaywallViewController(forKey: cacheKey) {
      if !isPreloading {
        viewController.delegate = delegate
        viewController.paywall.update(from: paywall)
      }
      return viewController
    }

    let paywallViewController = factory.makePaywallViewController(
      for: paywall,
      withCache: cache,
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
