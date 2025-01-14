//
//  File.swift
//  
//
//  Created by Yusuf Tör on 05/12/2022.
//

import XCTest
@testable import SuperwallKit
import Combine

final class EvaluateRulesOperatorTests: XCTestCase {
  var cancellables: [AnyCancellable] = []

  func test_evaluateRules_isDebugger() async {
    let dependencyContainer = DependencyContainer()
    let identifier = "abc"

    let request = dependencyContainer.makePresentationRequest(
      .fromIdentifier(identifier, freeTrialOverride: false),
      isDebuggerLaunched: true,
      isPaywallPresented: false,
      type: .getPaywall(.stub())
    )

    do {
      let output = try await Superwall.shared.evaluateAudienceFilter(
        from: request
      )
      XCTAssertNil(output.confirmableAssignment)

      switch output.triggerResult {
      case .paywall(let experiment):
        XCTAssertEqual(experiment.id, identifier)
        XCTAssertEqual(experiment.groupId, "")
        XCTAssertEqual(experiment.variant.id, "")
        XCTAssertEqual(experiment.variant.type, .treatment)
        XCTAssertEqual(experiment.variant.paywallId, identifier)
      default:
        XCTFail("Wrong trigger result")
      }
    } catch {
      XCTFail("Shouldn't throw")
    }
  }

  func test_evaluateRules_isNotDebugger() async {
    let dependencyContainer = DependencyContainer()
    let request = dependencyContainer.makePresentationRequest(
      .explicitTrigger(.stub()),
      isDebuggerLaunched: false,
      isPaywallPresented: false,
      type: .getPaywall(.stub())
    )

    do {
      let output = try await Superwall.shared.evaluateAudienceFilter(
        from: request
      )
      XCTAssertNil(output.confirmableAssignment)

      switch output.triggerResult {
      case .placementNotFound:
        break
      default:
        XCTFail("Wrong trigger result")
      }
    } catch {
      XCTFail("Shouldn't throw")
    }
  }
}
