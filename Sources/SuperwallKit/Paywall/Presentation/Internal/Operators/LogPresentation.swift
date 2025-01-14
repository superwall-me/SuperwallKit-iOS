//
//  File.swift
//  
//
//  Created by Yusuf Tör on 11/05/2023.
//

import Foundation

extension Superwall {
  /// Logs the presentation request with a custom message and gets debug info for the placement.
  ///
  /// - Parameters:
  ///    - request: The presentation request.
  ///    - message: A message to log.
  func log(request: PresentationRequest) -> [String: Any] {
    var message = "Called "
    switch request.flags.type {
    case .getPaywall:
      message += "Superwall.shared.getPaywall"
    case .presentation:
      switch request.presentationInfo {
      case .explicitTrigger,
        .fromIdentifier:
        message += "Superwall.shared.register"
      case .implicitTrigger:
        message = "Tracking an implicit trigger"
      }
    case .getPresentationResult:
      message += "Superwall.shared.getPresentationResult"
    case .handleImplicitTrigger,
      .paywallDeclineCheck:
      message += "Superwall.shared.handleImplicitTrigger"
    case .confirmAllAssignments:
      message += "Superwall.shared.confirmAllAssignments"
    }
    let placementData = request.presentationInfo.placementData
    let debugInfo: [String: Any] = [
      "on": request.presenter.debugDescription,
      "fromPlacement": placementData.debugDescription as Any
    ]
    Logger.debug(
      logLevel: .debug,
      scope: .paywallPresentation,
      message: message,
      info: debugInfo
    )
    return debugInfo
  }
}
