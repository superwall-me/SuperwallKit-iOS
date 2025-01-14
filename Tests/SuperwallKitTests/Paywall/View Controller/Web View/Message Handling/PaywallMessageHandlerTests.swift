//
//  File.swift
//
//
//  Created by Yusuf Tör on 19/01/2023.
// swiftlint:disable all

import XCTest

@testable import SuperwallKit

final class PaywallMessageHandlerTests: XCTestCase {
  @MainActor
  func test_handleTemplateParams() async {
    let dependencyContainer = DependencyContainer()
    let messageHandler = PaywallMessageHandler(
      receiptManager: dependencyContainer.receiptManager,
      factory: dependencyContainer
    )
    let webView = FakeWebView(
      isMac: false,
      messageHandler: messageHandler,
      isOnDeviceCacheEnabled: true,
      factory: dependencyContainer
    )
    let delegate = PaywallMessageHandlerDelegateMock(
      paywallInfo: .stub(),
      webView: webView
    )
    messageHandler.delegate = delegate
    messageHandler.handle(.templateParamsAndUserAttributes)

    try? await Task.sleep(nanoseconds: 800_000_000)

    XCTAssertTrue(webView.willHandleJs)
  }

  @MainActor
  func test_onReady() async {
    let dependencyContainer = DependencyContainer()
    let messageHandler = PaywallMessageHandler(
      receiptManager: dependencyContainer.receiptManager,
      factory: dependencyContainer
    )
    let webView = FakeWebView(
      isMac: false,
      messageHandler: messageHandler,
      isOnDeviceCacheEnabled: true,
      factory: dependencyContainer
    )
    let delegate = PaywallMessageHandlerDelegateMock(
      paywallInfo: .stub(),
      webView: webView
    )
    messageHandler.delegate = delegate
    messageHandler.handle(.onReady(paywallJsVersion: "2"))

    try? await Task.sleep(nanoseconds: 500_000_000)

    XCTAssertEqual(delegate.paywall.paywalljsVersion, "2")
    XCTAssertTrue(webView.willHandleJs)
  }

  @MainActor
  func test_close() {
    let dependencyContainer = DependencyContainer()
    let messageHandler = PaywallMessageHandler(
      receiptManager: dependencyContainer.receiptManager,
      factory: dependencyContainer
    )
    let webView = FakeWebView(
      isMac: false,
      messageHandler: messageHandler,
      isOnDeviceCacheEnabled: true,
      factory: dependencyContainer
    )
    let delegate = PaywallMessageHandlerDelegateMock(
      paywallInfo: .stub(),
      webView: webView
    )
    messageHandler.delegate = delegate
    messageHandler.handle(.close)

    XCTAssertEqual(delegate.eventDidOccur, .closed)
  }

  @MainActor
  func test_openUrl() {
    let dependencyContainer = DependencyContainer()
    let messageHandler = PaywallMessageHandler(
      receiptManager: dependencyContainer.receiptManager,
      factory: dependencyContainer
    )
    let webView = FakeWebView(
      isMac: false,
      messageHandler: messageHandler,
      isOnDeviceCacheEnabled: true,
      factory: dependencyContainer
    )
    let delegate = PaywallMessageHandlerDelegateMock(
      paywallInfo: .stub(),
      webView: webView
    )
    messageHandler.delegate = delegate
    let url = URL(string: "https://www.google.com")!
    messageHandler.handle(.openUrl(url))

    XCTAssertEqual(delegate.eventDidOccur, .openedURL(url: url))
    XCTAssertTrue(delegate.didPresentSafariInApp)
  }

  @MainActor
  func test_openUrlInSafari() {
    let dependencyContainer = DependencyContainer()
    let messageHandler = PaywallMessageHandler(
      receiptManager: dependencyContainer.receiptManager,
      factory: dependencyContainer
    )
    let webView = FakeWebView(
      isMac: false,
      messageHandler: messageHandler,
      isOnDeviceCacheEnabled: true,
      factory: dependencyContainer
    )
    let delegate = PaywallMessageHandlerDelegateMock(
      paywallInfo: .stub(),
      webView: webView
    )
    messageHandler.delegate = delegate
    let url = URL(string: "https://www.google.com")!
    messageHandler.handle(.openUrlInSafari(url))

    XCTAssertEqual(delegate.eventDidOccur, .openedUrlInSafari(url))
    XCTAssertTrue(delegate.didPresentSafariExternal)
  }

  @MainActor
  func test_openDeepLink() {
    let dependencyContainer = DependencyContainer()
    let messageHandler = PaywallMessageHandler(
      receiptManager: dependencyContainer.receiptManager,
      factory: dependencyContainer
    )
    let webView = FakeWebView(
      isMac: false,
      messageHandler: messageHandler,
      isOnDeviceCacheEnabled: true,
      factory: dependencyContainer
    )
    let delegate = PaywallMessageHandlerDelegateMock(
      paywallInfo: .stub(),
      webView: webView
    )
    messageHandler.delegate = delegate

    let url = URL(string: "exampleapp://foo")!
    messageHandler.handle(.openDeepLink(url: url))

    XCTAssertTrue(delegate.didOpenDeepLink)
  }

  @MainActor
  func test_restore() {
    let dependencyContainer = DependencyContainer()
    let messageHandler = PaywallMessageHandler(
      receiptManager: dependencyContainer.receiptManager,
      factory: dependencyContainer
    )
    let webView = FakeWebView(
      isMac: false,
      messageHandler: messageHandler,
      isOnDeviceCacheEnabled: true,
      factory: dependencyContainer
    )
    let delegate = PaywallMessageHandlerDelegateMock(
      paywallInfo: .stub(),
      webView: webView
    )
    messageHandler.delegate = delegate
    messageHandler.handle(.restore)

    XCTAssertEqual(delegate.eventDidOccur, .initiateRestore)
  }

  @MainActor
  func test_purchaseProduct() {
    let dependencyContainer = DependencyContainer()
    let messageHandler = PaywallMessageHandler(
      receiptManager: dependencyContainer.receiptManager,
      factory: dependencyContainer
    )
    let webView = FakeWebView(
      isMac: false,
      messageHandler: messageHandler,
      isOnDeviceCacheEnabled: true,
      factory: dependencyContainer
    )
    let delegate = PaywallMessageHandlerDelegateMock(
      paywallInfo: .stub(),
      webView: webView
    )
    messageHandler.delegate = delegate
    let productId = "abc"
    messageHandler.handle(.purchase(productId: productId))

    XCTAssertEqual(delegate.eventDidOccur, .initiatePurchase(productId: productId))
  }

  @MainActor
  func test_custom() {
    let dependencyContainer = DependencyContainer()
    let messageHandler = PaywallMessageHandler(
      receiptManager: dependencyContainer.receiptManager,
      factory: dependencyContainer
    )
    let webView = FakeWebView(
      isMac: false,
      messageHandler: messageHandler,
      isOnDeviceCacheEnabled: true,
      factory: dependencyContainer
    )
    let delegate = PaywallMessageHandlerDelegateMock(
      paywallInfo: .stub(),
      webView: webView
    )
    messageHandler.delegate = delegate
    let string = "abc"
    messageHandler.handle(.custom(data: string))

    XCTAssertEqual(delegate.eventDidOccur, .custom(string: string))
  }
}
