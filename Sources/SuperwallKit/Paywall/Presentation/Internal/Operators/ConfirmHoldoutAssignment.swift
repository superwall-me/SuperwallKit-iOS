//
//  File.swift
//  
//
//  Created by Yusuf Tör on 11/05/2023.
//

import Foundation

extension Superwall {
  /// Confirms the assignment for a holdout, if it exists.
  ///
  /// We can't confirm a paywall assignment here because there may be factors that prevent
  /// it from showing later on.
  ///
  /// - Parameters:
  ///   - request: The presentation request.
  ///   - audienceOutcome: The output from evaluating audience filters.
  ///   - dependencyContainer: Used for testing only.
  func confirmHoldoutAssignment(
    request: PresentationRequest,
    from audienceOutcome: AudienceFilterEvaluationOutcome,
    dependencyContainer: DependencyContainer? = nil
  ) {
    guard request.flags.type.shouldConfirmAssignments else {
      return
    }
    let dependencyContainer = dependencyContainer ?? self.dependencyContainer
    guard case .holdout = audienceOutcome.triggerResult else {
      return
    }
    if let confirmableAssignment = audienceOutcome.confirmableAssignment {
      dependencyContainer.configManager.confirmAssignment(confirmableAssignment)
    }
  }
}
