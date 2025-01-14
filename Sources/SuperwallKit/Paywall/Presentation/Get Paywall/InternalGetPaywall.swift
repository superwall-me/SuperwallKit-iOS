//
//  File.swift
//  
//
//  Created by Yusuf Tör on 02/05/2023.
//

import Foundation
import Combine
import UIKit

extension Superwall {
  struct PaywallComponents {
    let viewController: PaywallViewController
    let presenter: UIViewController?
    let audienceOutcome: AudienceFilterEvaluationOutcome
    let debugInfo: [String: Any]
  }

  /// Gets a paywall to present, publishing ``PaywallState`` objects that provide updates on the lifecycle of the paywall.
  ///
  /// - Parameters:
  ///   - request: A presentation request of type `PresentationRequest` to feed into a presentation pipeline.
  ///
  /// - Returns: A ``PaywallViewController`` to present.
  @discardableResult
  func getPaywall(
    _ request: PresentationRequest,
    _ publisher: PassthroughSubject<PaywallState, Never> = .init()
  ) async throws -> PaywallViewController {
    do {
      let paywallComponents = try await getPaywallComponents(request, publisher)

      await paywallComponents.viewController.set(
        request: request,
        paywallStatePublisher: publisher,
        unsavedOccurrence: paywallComponents.audienceOutcome.unsavedOccurrence
      )
      return paywallComponents.viewController
    } catch {
      let toObjc = request.flags.type.hasObjcDelegate()
      logErrors(from: request, error)
      throw mapError(error, toObjc: toObjc)
    }
  }
}
