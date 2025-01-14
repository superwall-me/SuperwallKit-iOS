//
//  File.swift
//  
//
//  Created by Yusuf Tör on 05/12/2022.
//

import XCTest
@testable import SuperwallKit
import Combine

@available(iOS 14.0, *)
final class HandleTriggerResultOperatorTests: XCTestCase {
  var cancellables: [AnyCancellable] = []

  func test_handleTriggerResult_paywall() async {
    let input = AudienceFilterEvaluationOutcome(
      triggerResult: .paywall(.init(id: "", groupId: "", variant: .init(id: "", type: .treatment, paywallId: "")))
    )

    let statePublisher = PassthroughSubject<PaywallState, Never>()
    let stateExpectation = expectation(description: "Output a state")
    stateExpectation.isInverted = true

    statePublisher.sink { state in
      stateExpectation.fulfill()
    }
    .store(in: &cancellables)

    do {
      _ = try await Superwall.shared.getExperiment(
        request: .stub(),
        audienceOutcome: input,
        debugInfo: [:],
        paywallStatePublisher: statePublisher,
        storage: StorageMock()
      )
    } catch {
      XCTFail()
    }

    await fulfillment(of: [stateExpectation], timeout: 0.1)
  }

  func test_handleTriggerResult_holdout() async {
    //TODO: THis doesn't take into account activateSession
    let experimentId = "abc"
    let input = AudienceFilterEvaluationOutcome(
      triggerResult: .holdout(.init(id: experimentId, groupId: "", variant: .init(id: "", type: .treatment, paywallId: "")))
    )

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
      case .skipped(let reason):
        switch reason {
        case .holdout(let experiment):
          XCTAssertEqual(experiment.id, experimentId)
          stateExpectation.fulfill()
        default:
          break
        }
      default:
        break
      }
    }
    .store(in: &cancellables)

    do {
      _ = try await Superwall.shared.getExperiment(
        request: .stub(),
        audienceOutcome: input,
        debugInfo: [:],
        paywallStatePublisher: statePublisher,
        storage: StorageMock()
      )
      XCTFail("Should fail")
    } catch {
      if let error = error as? PresentationPipelineError,
        case .holdout = error {

      } else {
        XCTFail("Wrong error type")
      }
    }

    await fulfillment(of: [stateExpectation], timeout: 0.1)
  }

  func test_handleTriggerResult_noRuleMatch() async {
    let input = AudienceFilterEvaluationOutcome(
      triggerResult: .noAudienceMatch([])
    )

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
      case .skipped(let reason):
        switch reason {
        case .noAudienceMatch:
          stateExpectation.fulfill()
        default:
          break
        }
      default:
        break
      }
    }
    .store(in: &cancellables)

    do {
      _ = try await Superwall.shared.getExperiment(
        request: .stub(),
        audienceOutcome: input,
        debugInfo: [:],
        paywallStatePublisher: statePublisher,
        storage: StorageMock()
      )
      XCTFail("Should fail")
    } catch {
      if let error = error as? PresentationPipelineError,
        case .noAudienceMatch = error {

      } else {
        XCTFail("Wrong error type")
      }
    }

    await fulfillment(of: [stateExpectation], timeout: 0.1)
  }

  func test_handleTriggerResult_eventNotFound() async {
    let input = AudienceFilterEvaluationOutcome(
      triggerResult: .placementNotFound
    )

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
      case .skipped(let reason):
        switch reason {
        case .placementNotFound:
          stateExpectation.fulfill()
        default:
          break
        }
      default:
        break
      }
    }
    .store(in: &cancellables)

    do {
      _ = try await Superwall.shared.getExperiment(
        request: .stub(),
        audienceOutcome: input,
        debugInfo: [:],
        paywallStatePublisher: statePublisher,
        storage: StorageMock()
      )
      XCTFail("Should fail")
    } catch {
      if let error = error as? PresentationPipelineError,
        case .placementNotFound = error {

      } else {
        XCTFail("Wrong error type")
      }
    }

    await fulfillment(of: [stateExpectation], timeout: 0.1)
  }

  func test_handleTriggerResult_error() async {
    let outputError = NSError(
      domain: "Test",
      code: 1
    )
    let input = AudienceFilterEvaluationOutcome(
      triggerResult: .error(outputError)
    )

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
      case .presentationError(let error):
        XCTAssertEqual(error as NSError, outputError)
        stateExpectation.fulfill()
      default:
        break
      }
    }
    .store(in: &cancellables)

    do {
      _ = try await Superwall.shared.getExperiment(
        request: .stub(),
        audienceOutcome: input,
        debugInfo: [:],
        paywallStatePublisher: statePublisher,
        storage: StorageMock()
      )
      XCTFail("Should fail")
    } catch {
      if let error = error as? PresentationPipelineError,
         case .noPaywallViewController = error {

      } else {
        XCTFail("Wrong error type")
      }
    }

    await fulfillment(of: [stateExpectation], timeout: 0.1)
  }
}
