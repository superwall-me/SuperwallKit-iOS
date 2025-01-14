//
//  File.swift
//  
//
//  Created by Yusuf Tör on 04/10/2022.
//

import UIKit

extension Superwall {
  // MARK: - V2 to V4
  @available(*, unavailable, renamed: "preloadPaywalls(forPlacements:)")
  @objc public func preloadPaywalls(forTriggers triggers: Set<String>) {}

  @available(*, unavailable, renamed: "register(placement:params:handler:feature:)")
  @objc public func trigger(
    event: String? = nil,
    params: [String: Any]? = nil,
    on viewController: UIViewController? = nil,
    ignoreSubscriptionStatus: Bool = false,
    presentationStyleOverride: PaywallPresentationStyle = .none,
    onSkip: ((NSError?) -> Void)? = nil,
    onPresent: ((PaywallInfo) -> Void)? = nil,
    onDismiss: ((Bool, String?, PaywallInfo) -> Void)? = nil
  ) {}

  @available(*, unavailable, renamed: "register(placement:params:)")
  @objc public func track(
    _ name: String,
    _ params: [String: Any] = [:]
  ) {}

  @available(*, unavailable, message: "Set the SuperwallOption \"localeIdentifier\" instead.")
  @objc public func localizationOverride(localeIdentifier: String? = nil) {}

  @available(*, unavailable, renamed: "SuperwallPlacement")
  public enum EventName: String {
    case fakeCase = "fake"
  }

  // MARK: - V3 to V4

  @available(*, unavailable, renamed: "register(placement:params:handler:feature:)")
  @objc public func register(
    event: String,
    params: [String: Any]? = nil,
    handler: PaywallPresentationHandler? = nil,
    feature: @escaping () -> Void
  ) {}

  @available(*, unavailable, renamed: "register(placement:params:handler:)")
  @objc public func register(
    event: String,
    params: [String: Any]? = nil,
    handler: PaywallPresentationHandler? = nil
  ) {}

  @available(*, unavailable, renamed: "register(placement:params:)")
  @objc public func register(
    event: String,
    params: [String: Any]? = nil
  ) {}

  @available(*, unavailable, renamed: "register(placement:)")
  @objc public func register(
    event: String
  ) {}

  @available(*, unavailable, renamed: "preloadPaywalls(forPlacements:)")
  @objc public func preloadPaywalls(forEvents eventNames: Set<String>) {}

  @available(*, unavailable, renamed: "getPaywall(forPlacement:params:paywallOverrides:delegate:completion:)")
  @available(swift, obsoleted: 1.0)
  @objc public func getPaywall(
    forEvent event: String,
    params: [String: Any]? = nil,
    paywallOverrides: PaywallOverrides? = nil,
    delegate: PaywallViewControllerDelegateObjc,
    completion: @escaping (GetPaywallResultObjc) -> Void
  ) {}

  @available(*, unavailable, renamed: "getPaywall(forPlacement:params:paywallOverrides:delegate:)")
  @MainActor
  @nonobjc public func getPaywall(
    forEvent event: String,
    params: [String: Any]? = nil,
    paywallOverrides: PaywallOverrides? = nil,
    delegate: PaywallViewControllerDelegate
  ) async throws -> PaywallViewController {
    let dependencyContainer = DependencyContainer()
    return PaywallViewController(
      paywall: .stub(),
      deviceHelper: dependencyContainer.deviceHelper,
      factory: dependencyContainer,
      storage: dependencyContainer.storage,
      webView: SWWebView(
        isMac: false,
        messageHandler: .init(
          receiptManager: dependencyContainer.receiptManager,
          factory: dependencyContainer
        ),
        isOnDeviceCacheEnabled: false,
        factory: dependencyContainer
      ),
      cache: dependencyContainer.makeCache(),
      paywallArchiveManager: dependencyContainer.paywallArchiveManager
    )
  }

  @available(*, unavailable, renamed: "getPaywall(forPlacement:params:paywallOverrides:delegate:completion:)")
  @nonobjc public func getPaywall(
    forEvent event: String,
    params: [String: Any]? = nil,
    paywallOverrides: PaywallOverrides? = nil,
    delegate: PaywallViewControllerDelegate,
    completion: @escaping (PaywallViewController?, PaywallSkippedReason?, Error?) -> Void
  ) {}

  @available(*, unavailable, renamed: "getPresentationResult(forPlacement:params:)")
  public func getPresentationResult(
    forEvent event: String,
    params: [String: Any]? = nil
  ) async -> PresentationResult {
    return .placementNotFound
  }

  @available(*, unavailable, renamed: "getPresentationResult(forPlacement:params:completion:)")
  public func getPresentationResult(
    forEvent event: String,
    params: [String: Any]? = nil,
    completion: @escaping (PresentationResult) -> Void
  ) {}

  @available(*, unavailable, renamed: "getPresentationResult(forPlacement:params:)")
  @available(swift, obsoleted: 1.0)
  @objc public func getPresentationResult(
    forEvent event: String,
    params: [String: Any]? = nil
  ) async -> PresentationResultObjc {
    return .init(trackResult: .placementNotFound)
  }
}

@available(*, unavailable, renamed: "SuperwallPlacementInfo")
@objc(SWKSuperwallEventInfo)
@objcMembers
public final class SuperwallEventInfo: NSObject {}

extension SuperwallDelegate {
  @available(*, unavailable, renamed: "handleSuperwallPlacement(withInfo:)")
  public func handleSuperwallEvent(withInfo placementInfo: SuperwallEventInfo) {}
}

@available(*, unavailable, renamed: "ProductStore")
@objc(SWKStore)
public enum Store: Int {
  case appStore
}

@available(*, unavailable, renamed: "Product")
@objc(SWKProductInfo)
@objcMembers
public final class ProductInfo: NSObject, Codable, Sendable {}
