//
//  File 2.swift
//  
//
//  Created by Yusuf Tör on 27/06/2024.
//

import Foundation

protocol SWWebViewLoadingDelegate: AnyObject {
  func loadWebView(
    with url: URL,
    timeout: TimeInterval?
  ) async throws
}

final class SWWebViewLoadingHandler {
  weak var loadingDelegate: SWWebViewLoadingDelegate?
  weak var webViewDelegate: (SWWebViewDelegate & PaywallMessageHandlerDelegate)?
  let enableMultiplePaywallUrls: Bool
  var didFailToLoad = false

  init(enableMultiplePaywallUrls: Bool) {
    self.enableMultiplePaywallUrls = enableMultiplePaywallUrls
  }

  func loadURL(
    attempts: Int = 0,
    paywallUrlConfig: WebViewURLConfig,
    paywallUrl: URL,
    attemptedURLs: [URL] = []
  ) async -> Bool {
    guard let delegate = loadingDelegate else {
      didFailToLoad = true
      return false
    }

    if !enableMultiplePaywallUrls {
      do {
        try await delegate.loadWebView(
          with: paywallUrl,
          timeout: nil
        )
        didFailToLoad = false
        return true
      } catch {
        await trackWebViewLoadFailure(error, urls: [paywallUrl])
        didFailToLoad = true
        return false
      }
    }

    var endpoints = paywallUrlConfig.endpoints

    guard attempts < paywallUrlConfig.maxAttempts else {
      await trackWebViewLoadFailure(WebViewError.exceededAttempts, urls: attemptedURLs)
      didFailToLoad = true
      return false
    }
    guard let endpoint = SWWebViewLogic.chooseEndpoint(from: endpoints) else {
      await trackWebViewLoadFailure(WebViewError.noEndpoints, urls: [])
      didFailToLoad = true
      return false
    }

    do {
      try await delegate.loadWebView(
        with: endpoint.url,
        timeout: endpoint.timeout
      )
      didFailToLoad = false
      return true
    } catch {
      if let invalidURLIndex = endpoints.firstIndex(where: { $0.url == endpoint.url }) {
        await trackWebViewLoadFailure(error, urls: [endpoint.url])

        endpoints.remove(at: invalidURLIndex)
        if endpoints.isEmpty {
          await trackWebViewLoadFailure(error, urls: attemptedURLs)
          didFailToLoad = true
          return false
        }

        await trackWebViewLoadFallback(error)

        return await loadURL(
          attempts: attempts + 1,
          paywallUrlConfig: WebViewURLConfig(
            endpoints: endpoints,
            maxAttempts: paywallUrlConfig.maxAttempts
          ),
          paywallUrl: paywallUrl,
          attemptedURLs: attemptedURLs + [endpoint.url]
        )
      }
    }
    return false
  }

  private func trackWebViewLoadFailure(
    _ error: Error,
    urls: [URL],
    at failAt: Date = Date()
  ) async {
    webViewDelegate?.paywall.webviewLoadingInfo.failAt = failAt

    guard let paywallInfo = webViewDelegate?.info else {
      return
    }

    let webviewLoad = InternalSuperwallPlacement.PaywallWebviewLoad(
      state: .fail(error, urls),
      paywallInfo: paywallInfo
    )
    await Superwall.shared.track(webviewLoad)
  }

  private func trackWebViewLoadFallback(
    _ error: Error
  ) async {
    guard let paywallInfo = webViewDelegate?.info else {
      return
    }

    let webviewLoad = InternalSuperwallPlacement.PaywallWebviewLoad(
      state: .fallback,
      paywallInfo: paywallInfo
    )
    await Superwall.shared.track(webviewLoad)
  }
}
