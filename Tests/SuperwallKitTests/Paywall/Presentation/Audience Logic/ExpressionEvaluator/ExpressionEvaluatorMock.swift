//
//  File.swift
//  
//
//  Created by Yusuf Tör on 10/10/2023.
//
// swiftlint:disable all

import Foundation
@testable import SuperwallKit

struct ExpressionEvaluatorMock: ExpressionEvaluating {
  let outcome: TriggerAudienceOutcome

  func evaluateExpression(fromAudienceFilter rule: TriggerRule, placementData: PlacementData?) async -> TriggerAudienceOutcome {
    return outcome
  }
}
