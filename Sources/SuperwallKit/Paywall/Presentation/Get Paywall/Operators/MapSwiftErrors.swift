//
//  File.swift
//  
//
//  Created by Yusuf Tör on 12/05/2023.
//

import Foundation

extension Superwall {
  func mapError(_ error: Error, toObjc: Bool) -> Error {
    if let error = error as? PresentationPipelineError {
      switch error {
      case .holdout(let experiment):
        if toObjc {
          return PaywallSkippedReasonObjc.holdout
        } else {
          return PaywallSkippedReason.holdout(experiment)
        }
      case .noAudienceMatch:
        if toObjc {
          return PaywallSkippedReasonObjc.noAudienceMatch
        } else {
          return PaywallSkippedReason.noAudienceMatch
        }
      case .placementNotFound:
        if toObjc {
          return PaywallSkippedReasonObjc.placementNotFound
        } else {
          return PaywallSkippedReason.placementNotFound
        }
      default:
        return error
      }
    }
    return error
  }
}
