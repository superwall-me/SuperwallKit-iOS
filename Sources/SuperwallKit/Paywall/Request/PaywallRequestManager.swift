//
//  File.swift
//  
//
//  Created by Jake Mor on 10/19/21.
//

import Foundation
import Combine

/// Actor responsible for handling all paywall requests.
actor PaywallRequestManager {
  let factory: DependencyContainer

  var storeKitManager: StoreKitManager {
    return factory.storeKitManager
  }
  var receiptManager: ReceiptManager {
    return factory.receiptManager
  }
  var network: Network {
    return factory.network
  }

  private var activeTasks: [String: Task<Paywall, Error>] = [:]
  private var paywallsByHash: [String: Paywall] = [:]
  typealias Factory = DeviceHelperFactory
    & TriggerSessionManagerFactory
    & ConfigManagerFactory

  init(factory: DependencyContainer) {
    self.factory = factory
  }

  ///  Gets a paywall from a given request.
  ///
  ///  If a request for the same paywall is already in progress, it suspends until the request returns.
  ///
  ///  - Parameters:
  ///     - request: A request to get a paywall.
  ///  - Returns A paywall.
  func getPaywall(from request: PaywallRequest) async throws -> Paywall {
    let deviceInfo = factory.makeDeviceInfo()
    let requestHash = PaywallLogic.requestHash(
      identifier: request.responseIdentifiers.paywallId,
      event: request.eventData,
      locale: deviceInfo.locale,
      paywallProducts: request.overrides.products
    )

    if var paywall = paywallsByHash[requestHash],
      !request.isDebuggerLaunched {
      paywall = updatePaywall(paywall, for: request)
      return paywall
    }

    if let existingTask = activeTasks[requestHash] {
      var paywall = try await existingTask.value
      paywall = updatePaywall(paywall, for: request)
      return paywall
    }

    let task = Task<Paywall, Error> {
      do {
        let rawPaywall = try await getRawPaywall(from: request)
        let paywallWithProducts = try await addProducts(to: rawPaywall, request: request)

        saveRequestHash(
          requestHash,
          paywall: paywallWithProducts,
          isDebuggerLaunched: request.isDebuggerLaunched
        )

        return paywallWithProducts
      } catch {
        activeTasks[requestHash] = nil
        throw error
      }
    }

    activeTasks[requestHash] = task

    var paywall = try await task.value
    paywall = updatePaywall(paywall, for: request)

    return paywall
  }

  private func updatePaywall(
    _ paywall: Paywall,
    for request: PaywallRequest
  ) -> Paywall {
    var paywall = paywall
    paywall.experiment = request.responseIdentifiers.experiment
    paywall.presentationSourceType = request.presentationSourceType
    return paywall
  }

  private func saveRequestHash(
    _ requestHash: String,
    paywall: Paywall,
    isDebuggerLaunched: Bool
  ) {
    activeTasks[requestHash] = nil
    if !isDebuggerLaunched {
      paywallsByHash[requestHash] = paywall
    }
  }
}
