//
//  File.swift
//  
//
//  Created by Yusuf Tör on 05/12/2022.
//

import XCTest
@testable import SuperwallKit
import Combine

final class GetPaywallVcOperatorTests: XCTestCase {
  var cancellables: [AnyCancellable] = []

  @MainActor
  func test_getPaywallViewController_success_paywallNotAlreadyPresented() async {
    let statePublisher = PassthroughSubject<PaywallState, Never>()
    let stateExpectation = expectation(description: "Output a state")
    stateExpectation.isInverted = true

    statePublisher.sink { _ in
      stateExpectation.fulfill()
    }
    .store(in: &cancellables)

    let dependencyContainer = DependencyContainer()
    let paywallManager = PaywallManagerMock(
      factory: dependencyContainer,
      paywallRequestManager: dependencyContainer.paywallRequestManager
    )
    paywallManager.getPaywallVc = dependencyContainer.makePaywallViewController(
      for: .stub(),
      withCache: nil,
      withPaywallArchiveManager: nil,
      delegate: nil
    )
    dependencyContainer.paywallManager = paywallManager

    let request = PresentationRequest.stub()
      .setting(\.flags.isPaywallPresented, to: false)

    do {
      _ = try await Superwall.shared.getPaywallViewController(
        request: request,
        audienceOutcome: .init(triggerResult: .paywall(.init(id: "", groupId: "", variant: .init(id: "", type: .treatment, paywallId: "")))),
        debugInfo: [:],
        paywallStatePublisher: statePublisher,
        dependencyContainer: dependencyContainer
      )
    } catch {
      XCTFail("Shouldn't have failed \(error)")
    }

    await fulfillment(of: [stateExpectation], timeout: 0.1)
  }
}
