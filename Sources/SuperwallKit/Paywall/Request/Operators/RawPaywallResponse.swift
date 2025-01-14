//
//  File.swift
//  
//
//  Created by Yusuf Tör on 12/05/2023.
//

import Foundation

extension PaywallRequestManager {
  func getRawPaywall(
    from request: PaywallRequest
  ) async throws -> Paywall {
    await trackResponseStarted(
      paywallId: request.responseIdentifiers.paywallId,
      placement: request.placementData
    )
    let paywall = try await getPaywallResponse(from: request)

    let paywallInfo = paywall.getInfo(fromPlacement: request.placementData)
    await trackResponseLoaded(
      paywallInfo,
      placement: request.placementData
    )

    return paywall
  }

  private func getPaywallResponse(
    from request: PaywallRequest
  ) async throws -> Paywall {
    let responseLoadStartTime = Date()
    let paywallId = request.responseIdentifiers.paywallId
    let placement = request.placementData
    var paywall: Paywall

    do {
      if let staticPaywall = factory.makeStaticPaywall(
        withId: paywallId,
        isDebuggerLaunched: request.isDebuggerLaunched
      ) {
        paywall = staticPaywall
      } else {
        paywall = try await network.getPaywall(
          withId: paywallId,
          fromPlacement: placement,
          retryCount: request.retryCount
        )
      }
    } catch {
      let errorResponse = PaywallLogic.handlePaywallError(
        error,
        forPlacement: placement
      )
      throw errorResponse
    }

    paywall.experiment = request.responseIdentifiers.experiment
    paywall.responseLoadingInfo.startAt = responseLoadStartTime
    paywall.responseLoadingInfo.endAt = Date()

    return paywall
  }

  // MARK: - Analytics
  private func trackResponseStarted(
    paywallId: String?,
    placement: PlacementData?
  ) async {
    let paywallLoad = InternalSuperwallPlacement.PaywallLoad(
      state: .start,
      placementData: placement
    )
    await Superwall.shared.track(paywallLoad)
  }

  private func trackResponseLoaded(
    _ paywallInfo: PaywallInfo,
    placement: PlacementData?
  ) async {
    let paywallLoad = InternalSuperwallPlacement.PaywallLoad(
      state: .complete(paywallInfo: paywallInfo),
      placementData: placement
    )
    await Superwall.shared.track(paywallLoad)
  }
}
