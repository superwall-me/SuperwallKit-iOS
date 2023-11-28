//
//  File.swift
//  
//
//  Created by Yusuf Tör on 06/12/2022.
//

import XCTest
@testable import SuperwallKit
import Combine

final class PresentPaywallOperatorTests: XCTestCase {
  var cancellables: [AnyCancellable] = []

  @MainActor
  func test_presentPaywall_isPresented() async {
    let statePublisher = PassthroughSubject<PaywallState, Never>()
    let stateExpectation = expectation(description: "Output a state")

    statePublisher.sink { completion in
      XCTFail()
    } receiveValue: { state in
      switch state {
      case .presented:
        stateExpectation.fulfill()
      default:
        break
      }
    }
    .store(in: &cancellables)
    let dependencyContainer = DependencyContainer()

    let messageHandler = PaywallMessageHandler(factory: dependencyContainer)
    let webView = SWWebView(
      isMac: false,
      sessionEventsManager: dependencyContainer.sessionEventsManager,
      messageHandler: messageHandler
    )
    let paywallVc = PaywallViewControllerMock(
      paywall: .stub(),
      deviceHelper: dependencyContainer.deviceHelper,
      factory: dependencyContainer,
      storage: dependencyContainer.storage,
      paywallManager: dependencyContainer.paywallManager,
      webView: webView,
      cache: nil
    )

    webView.delegate = paywallVc
    messageHandler.delegate = paywallVc

    paywallVc.shouldPresent = true

    do {
      _ = try await Superwall.shared.presentPaywallViewController(
        paywallVc,
        on: UIViewController(),
        unsavedOccurrence: nil,
        debugInfo: [:],
        request: .stub(),
        paywallStatePublisher: statePublisher
      )
    } catch {
      XCTFail("Shouldn't fail")
    }

    await fulfillment(of: [stateExpectation], timeout: 0.1)
  }

  @MainActor
  func test_presentPaywall_isNotPresented() async {
    let statePublisher = PassthroughSubject<PaywallState, Never>()
    let stateExpectation = expectation(description: "Output a state")
    stateExpectation.expectedFulfillmentCount = 2

    statePublisher.sink { completion in
      switch completion {
      case .finished:
        stateExpectation.fulfill()
      default:
        break
      }
    } receiveValue: { state in
      switch state {
      case .presentationError:
        stateExpectation.fulfill()
      default:
        break
      }
    }
    .store(in: &cancellables)

    let dependencyContainer = DependencyContainer()

    let messageHandler = PaywallMessageHandler(factory: dependencyContainer)
    let webView = SWWebView(
      isMac: false,
      sessionEventsManager: dependencyContainer.sessionEventsManager,
      messageHandler: messageHandler
    )
    let paywallVc = PaywallViewControllerMock(
      paywall: .stub(),
      deviceHelper: dependencyContainer.deviceHelper,
      factory: dependencyContainer,
      storage: dependencyContainer.storage,
      paywallManager: dependencyContainer.paywallManager,
      webView: webView,
      cache: nil
    )
    paywallVc.shouldPresent = false
    webView.delegate = paywallVc
    messageHandler.delegate = paywallVc

    do {
      _ = try await Superwall.shared.presentPaywallViewController(
        paywallVc,
        on: UIViewController(),
        unsavedOccurrence: nil,
        debugInfo: [:],
        request: .stub(),
        paywallStatePublisher: statePublisher
      )
      XCTFail("Should fail")
    } catch {
      if let error = error as? PresentationPipelineError,
        case .paywallAlreadyPresented = error {

      } else {
        XCTFail("Wrong error type")
      }
    }

    await fulfillment(of: [stateExpectation], timeout: 0.1)
  }
}
