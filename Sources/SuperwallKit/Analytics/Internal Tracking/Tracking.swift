//
//  File.swift
//  
//
//  Created by Jake Mor on 8/16/21.
//
// swiftlint:disable line_length

import Foundation
import Combine

extension Superwall {
  /// Tracks an analytical event by sending it to the server and, for internal Superwall placements, the delegate.
  ///
  /// - Parameters:
  ///   - placement: The placement you want to track.
	@discardableResult
  func track(_ placement: Trackable) async -> TrackingResult {
    // Get parameters to be sent to the delegate and stored in an placement.
    let placementCreatedAt = Date()
    let parameters = await TrackingLogic.processParameters(
      fromTrackablePlacement: placement,
      appSessionId: dependencyContainer.appSessionManager.appSession.id
    )

    // For a trackable superwall placement, send params to delegate
    if let trackedPlacement = placement as? TrackableSuperwallPlacement {
      let info = SuperwallPlacementInfo(
        placement: trackedPlacement.superwallPlacement,
        params: parameters.delegateParams
      )

      await dependencyContainer.delegateAdapter.handleSuperwallPlacement(withInfo: info)

      Logger.debug(
        logLevel: .debug,
        scope: .placements,
        message: "Logged Placement",
        info: parameters.audienceFilterParams
      )
    }

    let placementData = PlacementData(
      name: placement.rawName,
      parameters: JSON(parameters.audienceFilterParams),
      createdAt: placementCreatedAt
    )

    // If config doesn't exist yet we rely on previous saved feature flag
    // to determine whether to disable verbose placements.
    let existingDisableVerbosePlacements = dependencyContainer.configManager.config?.featureFlags.disableVerbosePlacements
    let previousDisableVerbosePlacements = dependencyContainer.storage.get(DisableVerbosePlacements.self)

    let verbosePlacements = existingDisableVerbosePlacements ?? previousDisableVerbosePlacements

    if TrackingLogic.isNotDisabledVerbosePlacement(
      placement,
      disableVerbosePlacements: verbosePlacements,
      isSandbox: dependencyContainer.makeIsSandbox()
    ) {
      await dependencyContainer.placementsQueue.enqueue(
        data: placementData.jsonData,
        from: placement
      )
    }
    dependencyContainer.storage.coreDataManager.savePlacementData(placementData)

    if placement.canImplicitlyTriggerPaywall {
      Task.detached { [weak self] in
        await self?.handleImplicitTrigger(
          forPlacement: placement,
          withData: placementData
        )
      }
		}

    let result = TrackingResult(
      data: placementData,
      parameters: parameters
    )
		return result
  }

  /// Attemps to implicitly trigger a paywall for a given analytical placement.
  ///
  ///  - Parameters:
  ///     - placement: The tracked placement.
  ///     - placementData: The placement data that could trigger a paywall.
  @MainActor
  func handleImplicitTrigger(
    forPlacement placement: Trackable,
    withData placementData: PlacementData
  ) async {
    // Assign the current register task while capturing the previous one.
    previousRegisterTask = Task { [weak self, previousRegisterTask] in
      // Wait until the previous register task is finished before continuing.
      await previousRegisterTask?.value

      await self?.internallyHandleImplicitTrigger(
        forPlacement: placement,
        withData: placementData
      )
    }
  }

  @MainActor
  private func internallyHandleImplicitTrigger(
    forPlacement placement: Trackable,
    withData placementData: PlacementData
  ) async {
    let presentationInfo: PresentationInfo = .implicitTrigger(placementData)

    var request = dependencyContainer.makePresentationRequest(
      presentationInfo,
      isPaywallPresented: isPaywallPresented,
      type: .presentation
    )

    do {
      try await waitForEntitlementsAndConfig(request, paywallStatePublisher: nil)
    } catch {
      return logErrors(from: request, error)
    }

    let triggeringOutcome = TrackingLogic.canTriggerPaywall(
      placement,
      triggers: Set(dependencyContainer.configManager.triggersByPlacementName.keys),
      paywallViewController: paywallViewController
    )

    var statePublisher = PassthroughSubject<PaywallState, Never>()

    switch triggeringOutcome {
    case .deepLinkTrigger:
      await dismiss()
    case .closePaywallThenTriggerPaywall:
      guard let lastPresentationItems = presentationItems.last else {
        return
      }

      // Make sure the result of presenting will be a paywall, otherwise do not proceed.
      // This is important to stop the paywall from being skipped and firing the feature
      // block when it shouldn't. This has to be done only to those triggers that reassign
      // the statePublisher. Others like app_launch are fine to skip and users are relying
      // on paywallPresentationRequest for those.
      let presentationResult = await internallyGetPresentationResult(
        forPlacement: placement,
        requestType: .handleImplicitTrigger
      )
      guard case .paywall = presentationResult else {
        return
      }
      await dismissForNextPaywall()

      request.paywallOverrides = PaywallOverrides(featureGatingBehavior: lastPresentationItems.featureGatingBehavior)
      statePublisher = lastPresentationItems.statePublisher
    case .triggerPaywall:
      break
    case .dontTriggerPaywall:
      return
    }

    request.flags.isPaywallPresented = isPaywallPresented

    await internallyPresent(request, statePublisher)
  }
}
