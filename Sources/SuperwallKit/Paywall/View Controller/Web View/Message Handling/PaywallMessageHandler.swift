//
//  EventHandler.swift
//  Superwall
//
//  Created by Yusuf Tör on 04/03/2022.
//
// swiftlint:disable line_length function_body_length

import UIKit
import WebKit

protocol PaywallMessageHandlerDelegate: AnyObject {
  var request: PresentationRequest? { get }
  var paywall: Paywall { get set }
  var info: PaywallInfo { get }
  var webView: SWWebView { get }
  var loadingState: PaywallLoadingState { get set }
  var isActive: Bool { get }

  func eventDidOccur(_ paywallWebEvent: PaywallWebEvent)
  func openDeepLink(_ url: URL)
  func presentSafariInApp(_ url: URL)
  func presentSafariExternal(_ url: URL)
}

@MainActor
final class PaywallMessageHandler: WebEventDelegate {
  weak var delegate: PaywallMessageHandlerDelegate?
  private var sessionEventsManager: SessionEventsManager {
    return factory.sessionEventsManager
  }
  private let factory: DependencyContainer

  init(factory: DependencyContainer) {
    self.factory = factory
  }

  func handle(_ message: PaywallMessage) {
    Logger.debug(
      logLevel: .debug,
      scope: .paywallViewController,
      message: "Handle Message",
      info: ["message": message]
    )
    guard let paywall = delegate?.paywall else {
      return
    }

    switch message {
    case .templateParamsAndUserAttributes:
      Task {
        await self.passTemplatesToWebView(from: paywall)
      }
    case .onReady(let paywalljsVersion):
      delegate?.paywall.paywalljsVersion = paywalljsVersion
      let loadedAt = Date()
      Task {
        await self.didLoadWebView(for: paywall, at: loadedAt)
      }
    case .close:
      hapticFeedback()
      delegate?.eventDidOccur(.closed)
    case .paywallOpen:
      Task {
        await self.pass(eventName: "paywall_open", from: paywall)
      }
    case .openUrl(let url):
      openUrl(url)
    case .openUrlInSafari(let url):
      openUrlInSafari(url)
    case .openDeepLink(let url):
      openDeepLink(url)
    case .restore:
      restorePurchases()
    case .purchase(productId: let id):
      purchaseProduct(withId: id)
    case .custom(data: let customEvent):
      handleCustomEvent(customEvent)
    }
  }

  nonisolated private func pass(
    eventName: String,
    from paywall: Paywall
  ) async {
    let event = [
      "event_name": eventName,
      "paywall_id": paywall.databaseId,
      "paywall_identifier": paywall.identifier
    ]
    guard let jsonEncodedEvent = try? JSONEncoder().encode([event]) else {
      return
    }
    let base64Event = jsonEncodedEvent.base64EncodedString()
    await passMessageToWebView(base64Event)
  }

  /// Passes the templated variables and params to the webview.
  ///
  /// This is called every paywall open incase variables like user attributes have changed.
  nonisolated private func passTemplatesToWebView(from paywall: Paywall) async {
    let eventData = await delegate?.request?.presentationInfo.eventData
    let base64Templates = await TemplateLogic.getBase64EncodedTemplates(
      from: paywall,
      event: eventData,
      factory: factory
    )
    await passMessageToWebView(base64Templates)
  }

  private func passMessageToWebView(_ base64String: String) {
    let messageScript = """
      window.paywall.accept64('\(base64String)');
    """

    Logger.debug(
      logLevel: .debug,
      scope: .paywallViewController,
      message: "Posting Message",
      info: ["message": messageScript],
      error: nil
    )

    delegate?.webView.evaluateJavaScript(messageScript) { _, error in
      if let error = error {
        Logger.debug(
          logLevel: .error,
          scope: .paywallViewController,
          message: "Error Evaluating JS",
          info: ["message": messageScript],
          error: error
        )
      }
    }
  }

  /// Passes in the HTML substitutions, templates and other scripts to make the webview
  /// feel native.
  nonisolated private func didLoadWebView(
    for paywall: Paywall,
    at loadedAt: Date
  ) async {
    Task(priority: .utility) {
      guard let delegate = await self.delegate else {
        return
      }

      delegate.paywall.webviewLoadingInfo.endAt = loadedAt

      let paywallInfo = delegate.info
      let trackedEvent = InternalSuperwallEvent.PaywallWebviewLoad(
        state: .complete,
        paywallInfo: paywallInfo
      )
      await Superwall.shared.track(trackedEvent)

      await sessionEventsManager.triggerSession.trackWebviewLoad(
        forPaywallId: paywallInfo.databaseId,
        state: .end
      )
    }

    let htmlSubstitutions = paywall.htmlSubstitutions
    let eventData = await delegate?.request?.presentationInfo.eventData
    let templates = await TemplateLogic.getBase64EncodedTemplates(
      from: paywall,
      event: eventData,
      factory: factory
    )
    let scriptSrc = """
      window.paywall.accept64('\(templates)');
      window.paywall.accept64('\(htmlSubstitutions)');
    """

    Logger.debug(
      logLevel: .debug,
      scope: .paywallViewController,
      message: "Posting Message",
      info: ["message": scriptSrc],
      error: nil
    )

    await MainActor.run {
      delegate?.webView.evaluateJavaScript(scriptSrc) { [weak self] _, error in
        if let error = error {
          Logger.debug(
            logLevel: .error,
            scope: .paywallViewController,
            message: "Error Evaluating JS",
            info: ["message": scriptSrc],
            error: error
          )
        }

        let delay = self?.delegate?.paywall.presentation.delay ?? 0
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) {
          self?.delegate?.loadingState = .ready
        }
      }

      // block selection
      let selectionString = "var css = '*{-webkit-touch-callout:none;-webkit-user-select:none} .w-webflow-badge { display: none !important; }'; "
      + "var head = document.head || document.getElementsByTagName('head')[0]; "
      + "var style = document.createElement('style'); style.type = 'text/css'; "
      + "style.appendChild(document.createTextNode(css)); head.appendChild(style); "

      let selectionScript = WKUserScript(
        source: selectionString,
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: true
      )
      self.delegate?.webView.configuration.userContentController.addUserScript(selectionScript)

      let preventSelection = "var css = '*{-webkit-touch-callout:none;-webkit-user-select:none}'; var head = document.head || document.getElementsByTagName('head')[0]; var style = document.createElement('style'); style.type = 'text/css'; style.appendChild(document.createTextNode(css)); head.appendChild(style);"
      self.delegate?.webView.evaluateJavaScript(preventSelection)

      let preventZoom: String = "var meta = document.createElement('meta');" + "meta.name = 'viewport';" + "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" + "var head = document.getElementsByTagName('head')[0];" + "head.appendChild(meta);"
      self.delegate?.webView.evaluateJavaScript(preventZoom)
    }
  }

  private func openUrl(_ url: URL) {
    detectHiddenPaywallEvent(
      "openUrl",
      userInfo: ["url": url]
    )
    hapticFeedback()
    delegate?.eventDidOccur(.openedURL(url: url))
    delegate?.presentSafariInApp(url)
  }

  private func openUrlInSafari(_ url: URL) {
    detectHiddenPaywallEvent(
      "openUrlInSafari",
      userInfo: ["url": url]
    )
    hapticFeedback()
    delegate?.eventDidOccur(.openedUrlInSafari(url))
    delegate?.presentSafariExternal(url)
  }

  private func openDeepLink(_ url: URL) {
    detectHiddenPaywallEvent(
      "openDeepLink",
      userInfo: ["url": url]
    )
    hapticFeedback()
    delegate?.openDeepLink(url)
  }

  private func restorePurchases() {
    detectHiddenPaywallEvent("restore")
    hapticFeedback()
    delegate?.eventDidOccur(.initiateRestore)
  }

  private func purchaseProduct(withId id: String) {
    detectHiddenPaywallEvent("purchase")
    hapticFeedback()
    delegate?.eventDidOccur(.initiatePurchase(productId: id))
  }

  private func handleCustomEvent(_ customEvent: String) {
    detectHiddenPaywallEvent(
      "custom",
      userInfo: ["custom_event": customEvent]
    )
    delegate?.eventDidOccur(.custom(string: customEvent))
  }

  private func detectHiddenPaywallEvent(
    _ eventName: String,
    userInfo: [String: Any]? = nil
  ) {
    guard delegate?.isActive == false else {
      return
    }
    let paywallDebugDescription = Superwall.shared.paywallViewController.debugDescription
    var info: [String: Any] = [
      "self": self,
      "Superwall.shared.paywallViewController": paywallDebugDescription,
      "event": eventName
    ]
    if let userInfo = userInfo {
      info = info.merging(userInfo)
    }
    Logger.debug(
      logLevel: .error,
      scope: .paywallViewController,
      message: "Received Event on Hidden Superwall",
      info: info
    )
  }

  private func hapticFeedback() {
    guard Superwall.shared.options.paywalls.isHapticFeedbackEnabled else {
      return
    }
    if Superwall.shared.options.isGameControllerEnabled {
      return
    }
    UIImpactFeedbackGenerator().impactOccurred(intensity: 0.7)
  }
}
