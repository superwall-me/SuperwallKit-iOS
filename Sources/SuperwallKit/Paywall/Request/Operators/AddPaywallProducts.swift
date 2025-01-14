//
//  File.swift
//  
//
//  Created by Yusuf Tör on 12/05/2023.
//
// swiftlint:disable trailing_closure

import Foundation

extension PaywallRequestManager {
  func addProducts(
    to paywall: Paywall,
    request: PaywallRequest
  ) async throws -> Paywall {
    var paywall = paywall

    paywall = await trackProductsLoadStart(
      paywall: paywall,
      request: request
    )
    paywall = try await getProducts(
      for: paywall,
      request: request
    )
    paywall = await trackProductsLoadFinish(
      paywall: paywall,
      placement: request.placementData
    )

    return paywall
  }

  private func getProducts(for paywall: Paywall, request: PaywallRequest) async throws -> Paywall {
    var paywall = paywall

    do {
      let result = try await storeKitManager.getProducts(
        forPaywall: paywall,
        placement: request.placementData,
        substituting: request.overrides.products
      )

      paywall.products = result.productItems

      let outcome = await PaywallLogic.getVariablesAndFreeTrial(
        productItems: result.productItems,
        productsById: result.productsById,
        isFreeTrialAvailableOverride: request.overrides.isFreeTrial,
        isFreeTrialAvailable: { [weak self] product in
          guard let self = self else { return false }
          return await self.factory.isFreeTrialAvailable(for: product)
        }
      )
      paywall.productVariables = outcome.productVariables
      paywall.isFreeTrialAvailable = outcome.isFreeTrialAvailable

      return paywall
    } catch {
      paywall.productsLoadingInfo.failAt = Date()
      let paywallInfo = paywall.getInfo(fromPlacement: request.placementData)
      await trackProductLoadFail(
        paywallInfo: paywallInfo,
        placement: request.placementData,
        error: error
      )
      throw error
    }
  }

  // MARK: - Analytics
  private func trackProductsLoadStart(paywall: Paywall, request: PaywallRequest) async -> Paywall {
    var paywall = paywall
    paywall.productsLoadingInfo.startAt = Date()
    let paywallInfo = paywall.getInfo(fromPlacement: request.placementData)
    let productsLoad = InternalSuperwallPlacement.PaywallProductsLoad(
      state: .start,
      paywallInfo: paywallInfo,
      placementData: request.placementData
    )
    await Superwall.shared.track(productsLoad)

    return paywall
  }

  private func trackProductLoadFail(
    paywallInfo: PaywallInfo,
    placement: PlacementData?,
    error: Error
  ) async {
    let productLoad = InternalSuperwallPlacement.PaywallProductsLoad(
      state: .fail(error),
      paywallInfo: paywallInfo,
      placementData: placement
    )
    await Superwall.shared.track(productLoad)
  }

  private func trackProductsLoadFinish(
    paywall: Paywall,
    placement: PlacementData?
  ) async -> Paywall {
    var paywall = paywall
    paywall.productsLoadingInfo.endAt = Date()
    let paywallInfo = paywall.getInfo(fromPlacement: placement)
    let productsLoad = InternalSuperwallPlacement.PaywallProductsLoad(
      state: .complete,
      paywallInfo: paywallInfo,
      placementData: placement
    )
    await Superwall.shared.track(productsLoad)

    return paywall
  }
}
