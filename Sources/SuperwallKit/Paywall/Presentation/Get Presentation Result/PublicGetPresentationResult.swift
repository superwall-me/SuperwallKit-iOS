//
//  File.swift
//  
//
//  Created by Yusuf Tör on 03/03/2023.
//

import Foundation

typealias PresentationPipelineError = PaywallPresentationRequestStatusReason

extension Superwall {
  /// Preemptively gets the result of registering a placement.
  ///
  /// This helps you determine whether a particular placement will present a paywall
  /// in the future.
  ///
  /// Note that this method does not present a paywall. To do that, use
  /// ``register(placement:params:handler:feature:)``.
  ///
  /// - Parameters:
  ///    - placement: The name of the placement you want to register.
  ///    - params: Optional parameters you'd like to pass with your placement.
  ///
  /// - Returns: A ``PresentationResult`` that indicates the result of registering a placement.
  public func getPresentationResult(
    forPlacement placement: String,
    params: [String: Any]? = nil
  ) async -> PresentationResult {
    let placement = UserInitiatedPlacement.Track(
      rawName: placement,
      canImplicitlyTriggerPaywall: false,
      audienceFilterParams: params ?? [:],
      isFeatureGatable: false
    )

    return await internallyGetPresentationResult(
      forPlacement: placement,
      requestType: .getPresentationResult
    )
  }

  /// Preemptively gets the result of registering an placement.
  ///
  /// This helps you determine whether a particular placement will present a paywall
  /// in the future.
  ///
  /// Note that this method does not present a paywall. To do that, use
  /// ``register(placement:params:handler:feature:)``.
  ///
  /// - Parameters:
  ///    - placement: The name of the placement you want to register.
  ///    - params: Optional parameters you'd like to pass with your placement.
  ///    - completion: A completion block that accepts a ``PresentationResult`` indicating
  ///     the result of tracking a placement.
  public func getPresentationResult(
    forPlacement placement: String,
    params: [String: Any]? = nil,
    completion: @escaping (PresentationResult) -> Void
  ) {
    Task {
      let result = await getPresentationResult(forPlacement: placement, params: params)
      completion(result)
    }
  }

  /// Called when you need to get the presentation result from a placement, whether implicitly or explicitly.
  ///
  /// - Parameters:
  ///   - placement: The placement that's being registered.
  ///   - requestType: The presentation request type, which will control the flow of the pipeline.
  func internallyGetPresentationResult(
    forPlacement placement: Trackable,
    requestType: PresentationRequestType
  ) async -> PresentationResult {
    let placementRegisteredAt = Date()

    let parameters = await TrackingLogic.processParameters(
      fromTrackablePlacement: placement,
      appSessionId: dependencyContainer.appSessionManager.appSession.id
    )

    let placementData = PlacementData(
      name: placement.rawName,
      parameters: JSON(parameters.audienceFilterParams),
      createdAt: placementRegisteredAt
    )

    let presentationRequest = dependencyContainer.makePresentationRequest(
      .explicitTrigger(placementData),
      isDebuggerLaunched: false,
      isPaywallPresented: false,
      type: requestType
    )

    return await getPresentationResult(for: presentationRequest)
  }

  /// Objective-C-only function to preemptively gets the result of registering a placement.
  ///
  /// This helps you determine whether a particular placement will present a paywall
  /// in the future.
  ///
  /// Note that this method does not present a paywall. To do that, use
  /// ``register(placement:params:handler:feature:)``.
  ///
  /// - Parameters:
  ///     - placement: The name of the placement you want to register.
  ///     - params: Optional parameters you'd like to pass with your placement.
  ///
  /// - Returns: A ``PresentationResultObjc`` object that contains information about the result of registering a placement.
  @available(swift, obsoleted: 1.0)
  @objc public func getPresentationResult(
    forPlacement placement: String,
    params: [String: Any]? = nil
  ) async -> PresentationResultObjc {
    let result = await getPresentationResult(forPlacement: placement, params: params)
    return PresentationResultObjc(trackResult: result)
  }

  /// Objective-C-only function to preemptively gets the result of registering a placement.
  ///
  /// This helps you determine whether a particular placement will present a paywall
  /// in the future.
  ///
  /// Note that this method does not present a paywall. To do that, use
  /// ``register(placement:params:handler:feature:)``.
  ///
  /// - Parameters placement: The name of the placement you want to register.
  /// - Returns: A ``PresentationResultObjc`` object that contains information about the result of registering a placement.
  @available(swift, obsoleted: 1.0)
  @objc public func getPresentationResult(
    forPlacement placement: String
  ) async -> PresentationResultObjc {
    let result = await getPresentationResult(forPlacement: placement, params: nil)
    return PresentationResultObjc(trackResult: result)
  }
}
