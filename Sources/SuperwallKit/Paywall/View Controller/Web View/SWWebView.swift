//
//  SWWebView.swift
//  Superwall
//
//  Created by Yusuf Tör on 03/03/2022.
//
// swiftlint:disable implicitly_unwrapped_optional

import Foundation
import WebKit

protocol SWWebViewDelegate: AnyObject {
  var info: PaywallInfo { get }
  func webViewDidFailProvisionalNavigation()
  func webViewDidFail()
}

class SWWebView: WKWebView {
  let messageHandler: PaywallMessageHandler
  weak var delegate: (SWWebViewDelegate & PaywallMessageHandlerDelegate)?
  var didFailToLoad = false
  private let wkConfig: WKWebViewConfiguration
  private let isMac: Bool
  private let sessionEventsManager: SessionEventsManager

  init(
    isMac: Bool,
    sessionEventsManager: SessionEventsManager,
    messageHandler: PaywallMessageHandler
  ) {
    self.isMac = isMac
    self.sessionEventsManager = sessionEventsManager
    self.messageHandler = messageHandler

    let config = WKWebViewConfiguration()
    config.allowsInlineMediaPlayback = true
    config.allowsAirPlayForMediaPlayback = true
    config.allowsPictureInPictureMediaPlayback = true
    config.mediaTypesRequiringUserActionForPlayback = []

    let preferences = WKPreferences()
    if #available(iOS 15.0, *),
      !isMac {
      preferences.isTextInteractionEnabled = false // ignore-xcode-12
    }
    preferences.javaScriptCanOpenWindowsAutomatically = true
    config.preferences = preferences
    wkConfig = config

    super.init(
      frame: .zero,
      configuration: wkConfig
    )
    wkConfig.userContentController.add(
      RawWebMessageHandler(delegate: messageHandler),
      name: "paywallMessageHandler"
    )
    self.navigationDelegate = self

    translatesAutoresizingMaskIntoConstraints = false
    allowsBackForwardNavigationGestures = true
    allowsLinkPreview = false
    backgroundColor = .clear
    scrollView.maximumZoomScale = 1.0
    scrollView.minimumZoomScale = 1.0
    isOpaque = false
    #if compiler(>=5.8) && os(iOS)
    if #available(iOS 16.4, *) {
      isInspectable = true
    }
    #endif

    scrollView.contentInsetAdjustmentBehavior = .never
    scrollView.bounces = true
    scrollView.contentInset = .zero
    scrollView.scrollIndicatorInsets = .zero
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.maximumZoomScale = 1.0
    scrollView.minimumZoomScale = 1.0
    scrollView.backgroundColor = .clear
    scrollView.isOpaque = false
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - WKNavigationDelegate
extension SWWebView: WKNavigationDelegate {
  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationResponse: WKNavigationResponse
  ) async -> WKNavigationResponsePolicy {
    guard let statusCode = (navigationResponse.response as? HTTPURLResponse)?.statusCode else {
      // if there's no http status code to act on, exit and allow navigation
      return .allow
    }

    // Track paywall errors
    if statusCode >= 400 {
      await trackPaywallError()
      return .cancel
    }

    return .allow
  }

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction
  ) async -> WKNavigationActionPolicy {
    if webView.isLoading {
      return .allow
    }
    if navigationAction.navigationType == .reload {
      return .allow
    }
    return .cancel
  }

  func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    didFailToLoad = false
  }

  func webView(
    _ webView: WKWebView,
    didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error
  ) {
    didFailToLoad = true
    delegate?.webViewDidFailProvisionalNavigation()
  }

  func webView(
    _ webView: WKWebView,
    didFail navigation: WKNavigation!,
    withError error: Error
  ) {
    didFailToLoad = true
    delegate?.webViewDidFail()
    let date = Date()
    Task {
      await trackPaywallError(at: date)
    }
  }

  func trackPaywallError(at failAt: Date = Date()) async {
    delegate?.paywall.webviewLoadingInfo.failAt = failAt

    guard let paywallInfo = delegate?.info else {
      return
    }

    await sessionEventsManager.triggerSession.trackWebviewLoad(
      forPaywallId: paywallInfo.databaseId,
      state: .fail
    )

    let trackedEvent = InternalSuperwallEvent.PaywallWebviewLoad(
      state: .fail,
      paywallInfo: paywallInfo
    )
    await Superwall.shared.track(trackedEvent)
  }
}
