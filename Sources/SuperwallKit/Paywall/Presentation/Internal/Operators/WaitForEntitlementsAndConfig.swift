//
//  File.swift
//  
//
//  Created by Yusuf Tör on 11/05/2023.
//
// swiftlint:disable function_body_length

import Foundation
import Combine

extension Superwall {
  /// Waits for config to be received and the identity and entitlements of the user to
  /// be established before continuing.
  ///
  /// - Parameters:
  ///   - request: The presentation request.
  ///   - dependencyContainer: Used for testing only.
  func waitForEntitlementsAndConfig(
    _ request: PresentationRequest,
    paywallStatePublisher: PassthroughSubject<PaywallState, Never>? = nil,
    dependencyContainer: DependencyContainer? = nil
  ) async throws {
    let dependencyContainer = dependencyContainer ?? self.dependencyContainer

    let configState = dependencyContainer.configManager.configState

    // First try to get config. If no config, wait for it.
    if configState.value.getConfig() == nil {
      do {
        try await dependencyContainer.configManager.configState
          .compactMap { $0.getConfig() }
          .throwableAsync()
      } catch {
        // If config completely dies, then throw an error
        let error = InternalPresentationLogic.presentationError(
          domain: "SWKPresentationError",
          code: 104,
          title: "No Config",
          value: "Trying to present paywall without the Superwall config."
        )
        let state: PaywallState = .presentationError(error)
        paywallStatePublisher?.send(state)
        paywallStatePublisher?.send(completion: .finished)
        throw PresentationPipelineError.noConfig
      }
    } else {
      // If there is config, continue.
    }

    // Now get the entitlement status. This has to be done after the retrieving
    // of config because entitlements are within config. Otherwise, if config
    // hasn't been retrieved we would get an error saying "entitlements not set"
    // but actually it's a config issue.
    let entitlementStatusTask = Task {
      return try await request.flags.entitlementStatus
        .filter { $0 != .unknown }
        .throwableAsync()
    }

    // Create a 5 sec timer. If the entitlement status is retrieved it'll
    // get cancelled. Otherwise will log a timeout and fail the request.
    let timer = Timer(
      timeInterval: 5,
      repeats: false
    ) { _ in
      entitlementStatusTask.cancel()
    }
    RunLoop.main.add(timer, forMode: .default)

    do {
      _ = try await entitlementStatusTask.value
    } catch {
      Task {
        let presentationRequest = InternalSuperwallPlacement.PresentationRequest(
          placementData: request.presentationInfo.placementData,
          type: request.flags.type,
          status: .timeout,
          statusReason: .entitlementsTimeout,
          factory: dependencyContainer
        )
        await self.track(presentationRequest)
      }
      Logger.debug(
        logLevel: .info,
        scope: .paywallPresentation,
        message: "Timeout: Superwall.shared.entitlements have not been set for over 5 seconds resulting in a failure."
      )
      let error = InternalPresentationLogic.presentationError(
        domain: "SWKPresentationError",
        code: 105,
        title: "Timeout",
        value: "The entitlements were not set."
      )
      paywallStatePublisher?.send(.presentationError(error))
      paywallStatePublisher?.send(completion: .finished)
      throw PresentationPipelineError.entitlementsTimeout
    }

    timer.invalidate()

    // Get the identity. This may or may not wait depending on whether the dev
    // specifically wants to wait for assignments.
    try await dependencyContainer.identityManager.hasIdentity.throwableAsync()
  }
}
