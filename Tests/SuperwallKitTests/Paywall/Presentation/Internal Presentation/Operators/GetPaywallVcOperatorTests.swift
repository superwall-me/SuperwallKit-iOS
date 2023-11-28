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
  func test_getPaywallViewController_error_userSubscribed() async {
    let statePublisher = PassthroughSubject<PaywallState, Never>()
    let stateExpectation = expectation(description: "Output a state")
    stateExpectation.expectedFulfillmentCount = 2

    statePublisher.sink { completion in
      switch completion {
      case .finished:
        stateExpectation.fulfill()
      }
    } receiveValue: { state in
      switch state {
      case .skipped(let reason):
        switch reason {
        case .userIsSubscribed:
          stateExpectation.fulfill()
        default:
          break
        }
      default:
        break
      }
    }
    .store(in: &cancellables)

    let dependencyContainer = DependencyContainer()
    let paywallManager = PaywallManagerMock(factory: dependencyContainer)
    paywallManager.getPaywallError = PresentationPipelineError.noPaywallViewController

    let publisher = CurrentValueSubject<SubscriptionStatus, Never>(SubscriptionStatus.active)
      .eraseToAnyPublisher()
    let request = PresentationRequest.stub()
      .setting(\.flags.subscriptionStatus, to: publisher)

    do {
      _ = try await Superwall.shared.getPaywallViewController(
        request: request,
        rulesOutcome: .init(triggerResult: .paywall(.init(id: "", groupId: "", variant: .init(id: "", type: .treatment, paywallId: "")))),
        debugInfo: [:],
        paywallStatePublisher: statePublisher,
        dependencyContainer: dependencyContainer
      )
    } catch {
      if let error = error as? PresentationPipelineError,
         case .userIsSubscribed = error {

      } else {
        XCTFail("Wrong error case \(error)")
      }
    }

    await fulfillment(of: [stateExpectation], timeout: 0.1)
  }

  @MainActor
  func test_getPaywallViewController_error_userNotSubscribed() async {
    let statePublisher = PassthroughSubject<PaywallState, Never>()
    let stateExpectation = expectation(description: "Output a state")
    stateExpectation.expectedFulfillmentCount = 2

    statePublisher.sink { completion in
      switch completion {
      case .finished:
        stateExpectation.fulfill()
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
    let paywallManager = PaywallManagerMock(factory: dependencyContainer)
    paywallManager.getPaywallError = PresentationPipelineError.userIsSubscribed

    let publisher = CurrentValueSubject<SubscriptionStatus, Never>(SubscriptionStatus.inactive)
      .eraseToAnyPublisher()
    let request = PresentationRequest.stub()
      .setting(\.flags.subscriptionStatus, to: publisher)

    do {
      _ = try await Superwall.shared.getPaywallViewController(
        request: request,
        rulesOutcome: .init(triggerResult: .paywall(.init(id: "", groupId: "", variant: .init(id: "", type: .treatment, paywallId: "")))),
        debugInfo: [:],
        paywallStatePublisher: statePublisher,
        dependencyContainer: dependencyContainer
      )
    } catch {
      if let error = error as? PresentationPipelineError,
         case .noPaywallViewController = error {

      } else {
        XCTFail("Wrong error case \(error)")
      }
    }

    await fulfillment(of: [stateExpectation], timeout: 0.1)
  }

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
    let paywallManager = PaywallManagerMock(factory: dependencyContainer)
    paywallManager.getPaywallVc = dependencyContainer.makePaywallViewController(for: .stub(), withCache: nil, delegate: nil)
    dependencyContainer.paywallManager = paywallManager

    let request = PresentationRequest.stub()
      .setting(\.flags.isPaywallPresented, to: false)

    do {
      _ = try await Superwall.shared.getPaywallViewController(
        request: request,
        rulesOutcome: .init(triggerResult: .paywall(.init(id: "", groupId: "", variant: .init(id: "", type: .treatment, paywallId: "")))),
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
