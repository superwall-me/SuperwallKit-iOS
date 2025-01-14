//
//  File.swift
//  
//
//  Created by Yusuf Tör on 11/05/2023.
//

import Foundation

extension Superwall {
  func logErrors(
    from request: PresentationRequest,
    _ error: Error
  ) {
    if let reason = error as? PresentationPipelineError,
      case .entitlementsTimeout = reason {
      // Don't print anything if we've just cancelled a pipeline that timed out.
      return
    }
    Task { [weak self] in
      guard let self = self else {
        return
      }
      if let reason = error as? PresentationPipelineError {
        let presentationRequest = InternalSuperwallPlacement.PresentationRequest(
          placementData: request.presentationInfo.placementData,
          type: request.flags.type,
          status: .noPresentation,
          statusReason: reason,
          factory: self.dependencyContainer
        )
        await self.track(presentationRequest)
      }
    }
    Logger.debug(
      logLevel: .info,
      scope: .paywallPresentation,
      message: "Skipped paywall presentation: \(error)"
    )
  }
}
