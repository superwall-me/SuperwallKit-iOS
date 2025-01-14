//
//  File.swift
//
//
//  Created by Yusuf Tör on 21/04/2022.
//

import Foundation

/// Analytical placements that are automatically tracked by Superwall.
///
/// These placement are tracked internally by the SDK and sent to the delegate method ``SuperwallDelegate/handleSuperwallPlacement(withInfo:)-pm3v``.
public enum SuperwallPlacement {
  /// When the user is first seen in the app, regardless of whether the user is logged in or not.
  case firstSeen

  /// Anytime the app enters the foreground
  case appOpen

  /// When the app is launched from a cold start
  ///
  /// The raw value of this placement can be added to a campaign to trigger a paywall.
  case appLaunch

  /// When the user's identity aliases after calling identify
  case identityAlias

  /// When the SDK is configured for the first time.
  ///
  /// The raw value of this placement can be added to a campaign to trigger a paywall.
  case appInstall

  /// When the app is opened at least an hour since last  ``appClose``.
  ///
  /// The raw value of this placement can be added to a campaign to trigger a paywall.
  case sessionStart

  /// When device attributes are sent to the backend.
  case deviceAttributes(attributes: [String: Any])

  /// When the entitlement status did change.
  case entitlementStatusDidChange

  /// Anytime the app leaves the foreground.
  case appClose

  /// When a user opens the app via a deep link.
  ///
  /// The raw value of this placement can be added to a campaign to trigger a paywall.
  case deepLink(url: URL)

  /// When the registered placement triggers a paywall or holdout.
  ///
  /// The result of firing the trigger is accessible in the `result` associated value.
  case triggerFire(placementName: String, result: TriggerResult)

  /// When a paywall is opened.
  case paywallOpen(paywallInfo: PaywallInfo)

  /// When a paywall is closed.
  case paywallClose(paywallInfo: PaywallInfo)

  /// When a user manually dismisses a paywall.
  case paywallDecline(paywallInfo: PaywallInfo)

  /// When the payment sheet is displayed to the user.
  case transactionStart(product: StoreProduct, paywallInfo: PaywallInfo)

  /// When the payment sheet fails to complete a transaction (ignores user canceling the transaction).
  case transactionFail(error: TransactionError, paywallInfo: PaywallInfo)

  /// When the user cancels a transaction.
  case transactionAbandon(product: StoreProduct, paywallInfo: PaywallInfo)

  /// When the user completes checkout in the payment sheet and any product was purchased.
  ///
  /// - Note: The `transaction` is an optional ``StoreTransaction`` object. Most of the time
  /// this won't be `nil`. However, it could be `nil` if you are using a ``PurchaseController``
  /// and the transaction object couldn't be detected after you return `.purchased` in ``PurchaseController/purchase(product:)``.
  case transactionComplete(
    transaction: StoreTransaction?, product: StoreProduct, type: TransactionType, paywallInfo: PaywallInfo)

  /// When the user successfully completes a transaction for a subscription product with no introductory offers.
  case subscriptionStart(product: StoreProduct, paywallInfo: PaywallInfo)

  /// When the user successfully completes a transaction for a subscription product with an introductory offer.
  case freeTrialStart(product: StoreProduct, paywallInfo: PaywallInfo)

  /// When the user successfully restores purchases..
  case transactionRestore(restoreType: RestoreType, paywallInfo: PaywallInfo)

  /// When the transaction took > 5 seconds to show the payment sheet.
  case transactionTimeout(paywallInfo: PaywallInfo)

  /// When the user attributes are set.
  case userAttributes(_ attributes: [String: Any])

  /// When the user purchased a non recurring product.
  case nonRecurringProductPurchase(product: TransactionProduct, paywallInfo: PaywallInfo)

  /// When a paywall's request to Superwall's servers has started.
  case paywallResponseLoadStart(triggeredPlacementName: String?)

  /// When a paywall's request to Superwall's servers returned a 404 error.
  case paywallResponseLoadNotFound(triggeredPlacementName: String?)

  /// When a paywall's request to Superwall's servers produced an error.
  case paywallResponseLoadFail(triggeredPlacementName: String?)

  /// When a paywall's request to Superwall's servers is complete.
  case paywallResponseLoadComplete(triggeredPlacementName: String?, paywallInfo: PaywallInfo)

  /// When a paywall's website begins to load.
  case paywallWebviewLoadStart(paywallInfo: PaywallInfo)

  /// When a paywall's website fails to load.
  case paywallWebviewLoadFail(paywallInfo: PaywallInfo)

  /// When a paywall's website completes loading.
  case paywallWebviewLoadComplete(paywallInfo: PaywallInfo)

  /// When the loading of a paywall's website times out.
  case paywallWebviewLoadTimeout(paywallInfo: PaywallInfo)

  /// When a paywall's website completes loading.
  case paywallWebviewLoadFallback(paywallInfo: PaywallInfo)

  /// When the request to load the paywall's products started.
  case paywallProductsLoadStart(triggeredPlacementName: String?, paywallInfo: PaywallInfo)

  /// When the request to load the paywall's products failed.
  case paywallProductsLoadFail(triggeredPlacementName: String?, paywallInfo: PaywallInfo)

  /// When the request to load the paywall's products completed.
  case paywallProductsLoadComplete(triggeredPlacementName: String?)

  /// When the request to load the paywall's products has failed and is being retried.
  case paywallProductsLoadRetry(
    triggeredPlacementName: String?, paywallInfo: PaywallInfo, attempt: Int)

  /// When the response to a paywall survey is recorded.
  case surveyResponse(
    survey: Survey,
    selectedOption: SurveyOption,
    customResponse: String?,
    paywallInfo: PaywallInfo
  )

  /// Information about the paywall presentation request
  case paywallPresentationRequest(
    status: PaywallPresentationRequestStatus,
    reason: PaywallPresentationRequestStatusReason?
  )

  /// When the first touch was detected on the UIWindow of the app.
  ///
  /// This is only registered if there's an active `touches_began` trigger on your dashboard.
  case touchesBegan

  /// When the user chose the close button on a survey instead of responding.
  case surveyClose

  /// When ``Superwall/reset()`` is called.
  case reset

  /// When a restore is initiated
  case restoreStart

  /// When a restore fails.
  case restoreFail(message: String)

  /// When a restore completes.
  case restoreComplete

  /// When the Superwall configuration is refreshed.
  case configRefresh

  /// When the user taps on an element in the paywall that has a `custom_placement` action attached to it.
  case customPlacement(name: String, params: [String: Any], paywallInfo: PaywallInfo)

  /// When the attributes that affect the configuration of Superwall are set or change.
  case configAttributes

  /// When all the experiment assignments are confirmed by calling ``Superwall/confirmAllAssignments()``.
  case confirmAllAssignments

  /// When the Superwall configuration fails to be retrieved.
  case configFail

  /// When the AdServices token request starts.
  case adServicesTokenRequestStart

  /// When the AdServices token request fails.
  case adServicesTokenRequestFail(error: Error)

  /// When the AdServices token request finishes.
  case adServicesTokenRequestComplete(token: String)

  /// When the shimmer view starts to show.
  case shimmerViewStart

  /// When the shimmer view stops showing.
  case shimmerViewComplete

  var canImplicitlyTriggerPaywall: Bool {
    switch self {
    case .appInstall,
      .sessionStart,
      .appLaunch,
      .deepLink,
      .transactionFail,
      .paywallDecline,
      .transactionAbandon,
      .surveyResponse,
      .touchesBegan,
      .customPlacement:
      return true
    default:
      return false
    }
  }
}

// MARK: - CustomStringConvertible
extension SuperwallPlacement: CustomStringConvertible {
  /// The string value of the placement name.
  public var description: String {
    return backingData.description
  }
}

// MARK: - Backing data
extension SuperwallPlacement {
  struct BackingData {
    let objcPlacement: SuperwallPlacementObjc
    let description: String

    init(objcPlacement: SuperwallPlacementObjc) {
      self.objcPlacement = objcPlacement
      self.description = objcPlacement.description
    }
  }

  var backingData: BackingData {
    switch self {
    case .firstSeen:
      return .init(objcPlacement: .firstSeen)
    case .appOpen:
      return .init(objcPlacement: .appOpen)
    case .identityAlias:
      return .init(objcPlacement: .identityAlias)
    case .appLaunch:
      return .init(objcPlacement: .appLaunch)
    case .appInstall:
      return .init(objcPlacement: .appInstall)
    case .sessionStart:
      return .init(objcPlacement: .sessionStart)
    case .deviceAttributes:
      return .init(objcPlacement: .deviceAttributes)
    case .entitlementStatusDidChange:
      return .init(objcPlacement: .entitlementStatusDidChange)
    case .appClose:
      return .init(objcPlacement: .appClose)
    case .deepLink:
      return .init(objcPlacement: .deepLink)
    case .triggerFire:
      return .init(objcPlacement: .triggerFire)
    case .paywallOpen:
      return .init(objcPlacement: .paywallOpen)
    case .paywallClose:
      return .init(objcPlacement: .paywallClose)
    case .paywallDecline:
      return .init(objcPlacement: .paywallDecline)
    case .transactionStart:
      return .init(objcPlacement: .transactionStart)
    case .transactionFail:
      return .init(objcPlacement: .transactionFail)
    case .transactionAbandon:
      return .init(objcPlacement: .transactionAbandon)
    case .transactionTimeout:
      return .init(objcPlacement: .transactionTimeout)
    case .transactionComplete:
      return .init(objcPlacement: .transactionComplete)
    case .subscriptionStart:
      return .init(objcPlacement: .subscriptionStart)
    case .freeTrialStart:
      return .init(objcPlacement: .freeTrialStart)
    case .transactionRestore:
      return .init(objcPlacement: .transactionRestore)
    case .userAttributes:
      return .init(objcPlacement: .userAttributes)
    case .nonRecurringProductPurchase:
      return .init(objcPlacement: .nonRecurringProductPurchase)
    case .paywallResponseLoadStart:
      return .init(objcPlacement: .paywallResponseLoadStart)
    case .paywallResponseLoadNotFound:
      return .init(objcPlacement: .paywallResponseLoadNotFound)
    case .paywallResponseLoadFail:
      return .init(objcPlacement: .paywallResponseLoadFail)
    case .paywallResponseLoadComplete:
      return .init(objcPlacement: .paywallResponseLoadComplete)
    case .paywallWebviewLoadStart:
      return .init(objcPlacement: .paywallWebviewLoadStart)
    case .paywallWebviewLoadFail:
      return .init(objcPlacement: .paywallWebviewLoadFail)
    case .paywallWebviewLoadComplete:
      return .init(objcPlacement: .paywallWebviewLoadComplete)
    case .paywallWebviewLoadTimeout:
      return .init(objcPlacement: .paywallWebviewLoadTimeout)
    case .paywallWebviewLoadFallback:
      return .init(objcPlacement: .paywallWebviewLoadFallback)
    case .paywallProductsLoadStart:
      return .init(objcPlacement: .paywallProductsLoadStart)
    case .paywallProductsLoadFail:
      return .init(objcPlacement: .paywallProductsLoadFail)
    case .paywallProductsLoadRetry:
      return .init(objcPlacement: .paywallProductsLoadRetry)
    case .paywallProductsLoadComplete:
      return .init(objcPlacement: .paywallProductsLoadComplete)
    case .paywallPresentationRequest:
      return .init(objcPlacement: .paywallPresentationRequest)
    case .surveyResponse:
      return .init(objcPlacement: .surveyResponse)
    case .touchesBegan:
      return .init(objcPlacement: .touchesBegan)
    case .surveyClose:
      return .init(objcPlacement: .surveyClose)
    case .reset:
      return .init(objcPlacement: .reset)
    case .restoreStart:
      return .init(objcPlacement: .restoreStart)
    case .restoreFail:
      return .init(objcPlacement: .restoreFail)
    case .restoreComplete:
      return .init(objcPlacement: .restoreComplete)
    case .configRefresh:
      return .init(objcPlacement: .configRefresh)
    case .customPlacement:
      return .init(objcPlacement: .customPlacement)
    case .configAttributes:
      return .init(objcPlacement: .configAttributes)
    case .confirmAllAssignments:
      return .init(objcPlacement: .confirmAllAssignments)
    case .configFail:
      return .init(objcPlacement: .configFail)
    case .adServicesTokenRequestStart:
      return .init(objcPlacement: .adServicesTokenRequestStart)
    case .adServicesTokenRequestFail:
      return .init(objcPlacement: .adServicesTokenRequestFail)
    case .adServicesTokenRequestComplete:
      return .init(objcPlacement: .adServicesTokenRequestComplete)
    case .shimmerViewStart:
      return .init(objcPlacement: .shimmerViewStart)
    case .shimmerViewComplete:
      return .init(objcPlacement: .shimmerViewComplete)
    }
  }
}

// Using this to silence warnings.
// This is unchecked because of the use of `Any` in `[String: Any]` user attributes.
// Also, PaywallInfo is not Sendable.
extension SuperwallPlacement: @unchecked Sendable {}
