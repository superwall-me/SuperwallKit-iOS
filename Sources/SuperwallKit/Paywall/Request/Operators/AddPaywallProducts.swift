//
//  File.swift
//  
//
//  Created by Yusuf Tör on 12/05/2023.
//

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
      event: request.eventData
    )

    return paywall
  }

  private func getProducts(for paywall: Paywall, request: PaywallRequest) async throws -> Paywall {
    var paywall = paywall

    do {
      let result = try await storeKitManager.getProducts(
        withIds: paywall.productIds,
        forPaywall: paywall.name,
        responseProducts: paywall.products,
        substituting: request.overrides.products
      )

      paywall.products = result.products

      let outcome = await PaywallLogic.getVariablesAndFreeTrial(
        fromProducts: result.products,
        productsById: result.productsById,
        isFreeTrialAvailableOverride: request.overrides.isFreeTrial,
        isFreeTrialAvailable: { [weak self] product in
          guard let self else { return false }
          return await receiptManager.isFreeTrialAvailable(for: product)
        }
      )
      paywall.swProducts = outcome.orderedSwProducts
      paywall.productVariables = outcome.productVariables
      paywall.swProductVariablesTemplate = outcome.swProductVariablesTemplate
      paywall.isFreeTrialAvailable = outcome.isFreeTrialAvailable

      return paywall
    } catch {
      paywall.productsLoadingInfo.failAt = Date()
      let paywallInfo = paywall.getInfo(
        fromEvent: request.eventData,
        factory: factory
      )
      await trackProductLoadFail(
        paywallInfo: paywallInfo,
        event: request.eventData
      )
      throw error
    }
  }

  // MARK: - Analytics
  private func trackProductsLoadStart(paywall: Paywall, request: PaywallRequest) async -> Paywall {
    var paywall = paywall
    paywall.productsLoadingInfo.startAt = Date()
    let paywallInfo = paywall.getInfo(
      fromEvent: request.eventData,
      factory: factory
    )
    let productLoadEvent = InternalSuperwallEvent.PaywallProductsLoad(
      state: .start,
      paywallInfo: paywallInfo,
      eventData: request.eventData
    )
    await Superwall.shared.track(productLoadEvent)

    let triggerSessionManager = factory.getTriggerSessionManager()
    await triggerSessionManager.trackProductsLoad(
      forPaywallId: paywallInfo.databaseId,
      state: .start
    )
    return paywall
  }

  private func trackProductLoadFail(
    paywallInfo: PaywallInfo,
    event: EventData?
  ) async {
    let productLoadEvent = InternalSuperwallEvent.PaywallProductsLoad(
      state: .fail,
      paywallInfo: paywallInfo,
      eventData: event
    )
    await Superwall.shared.track(productLoadEvent)

    let triggerSessionManager = factory.getTriggerSessionManager()
    await triggerSessionManager.trackProductsLoad(
      forPaywallId: paywallInfo.databaseId,
      state: .fail
    )
  }

  private func trackProductsLoadFinish(
    paywall: Paywall,
    event: EventData?
  ) async -> Paywall {
    var paywall = paywall
    paywall.productsLoadingInfo.endAt = Date()
    let paywallInfo = paywall.getInfo(
      fromEvent: event,
      factory: factory
    )
    let triggerSessionManager = factory.getTriggerSessionManager()
    await triggerSessionManager.trackProductsLoad(
      forPaywallId: paywallInfo.databaseId,
      state: .end
    )
    let productLoadEvent = InternalSuperwallEvent.PaywallProductsLoad(
      state: .complete,
      paywallInfo: paywallInfo,
      eventData: event
    )
    await Superwall.shared.track(productLoadEvent)

    return paywall
  }
}
