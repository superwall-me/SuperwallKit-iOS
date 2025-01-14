//
//  File.swift
//
//
//  Created by Yusuf Tör on 07/11/2022.
//

import Foundation

/// Objective-C-only analytical placements that are automatically tracked by Superwall.
///
/// These placements are tracked internally by the SDK and sent to the delegate method ``SuperwallKit/SuperwallDelegateObjc/handleSuperwallPlacement(withInfo:)``.
@objc(SWKSuperwallPlacement)
public enum SuperwallPlacementObjc: Int, CaseIterable {
  /// When the user is first seen in the app, regardless of whether the user is logged in or not.
  case firstSeen

  /// Anytime the app enters the foreground
  case appOpen

  /// When the app is launched from a cold start
  ///
  /// This placement can be used to trigger a paywall. Just add the `app_launch` placement to a campaign.
  case appLaunch

  /// When the SDK is configured for the first time.
  ///
  /// This placement can be used to trigger a paywall. Just add the `app_install` placement to a campaign.
  case appInstall

  /// When the user's identity aliases after calling identify.
  case identityAlias

  /// When the app is opened at least an hour since last  ``SuperwallPlacement/appClose``.
  ///
  /// This placement can be used to trigger a paywall. Just add the `session_start` placement to a campaign.
  case sessionStart

  /// When device attributes are sent to the backend.
  case deviceAttributes

  /// Anytime the app leaves the foreground.
  case appClose

  /// When a user opens the app via a deep link.
  ///
  /// This placement can be used to trigger a paywall. Just add the `deepLink_open` placement to a campaign.
  case deepLink

  /// When the registered placement triggers a paywall or holdout.
  case triggerFire

  /// When a paywall is opened.
  case paywallOpen

  /// When a paywall is closed.
  case paywallClose

  /// When a user dismisses a paywall instead of purchasing
  case paywallDecline

  /// When the payment sheet is displayed to the user.
  case transactionStart

  /// When the payment sheet fails to complete a transaction (ignores user canceling the transaction).
  case transactionFail

  /// When the user cancels a transaction.
  case transactionAbandon

  /// When the user completes checkout in the payment sheet and any product was purchased.
  case transactionComplete

  /// When the user successfully restores their purchases.
  case transactionRestore

  /// When a transaction takes > 5 seconds to show the payment sheet.
  case transactionTimeout

  /// When the user successfully completes a transaction for a subscription product with no introductory offers.
  case subscriptionStart

  /// When the entitlement status did change.
  case entitlementStatusDidChange

  /// When the user successfully completes a transaction for a subscription product with an introductory offer.
  case freeTrialStart

  /// When the user attributes are set.
  case userAttributes

  /// When the user purchased a non recurring product.
  case nonRecurringProductPurchase

  /// When a paywall's request to Superwall's servers has started.
  case paywallResponseLoadStart

  /// When a paywall's request to Superwall's servers returned a 404 error.
  case paywallResponseLoadNotFound

  /// When a paywall's request to Superwall's servers produced an error.
  case paywallResponseLoadFail

  /// When a paywall's request to Superwall's servers is complete.
  case paywallResponseLoadComplete

  /// When a paywall's website begins to load.
  case paywallWebviewLoadStart

  /// When a paywall's website fails to load.
  case paywallWebviewLoadFail

  /// When a paywall's website completes loading.
  case paywallWebviewLoadComplete

  /// When the loading of a paywall's website times out.
  case paywallWebviewLoadTimeout

  /// When the loading of a paywall's website falls back to a different CDN.
  case paywallWebviewLoadFallback

  /// When the request to load the paywall's products started.
  case paywallProductsLoadStart

  /// When the request to load the paywall's products failed.
  case paywallProductsLoadFail

  /// When the request to load the paywall's products completed.
  case paywallProductsLoadComplete

  /// When the request to load the paywall's products has failed and is being retried.
  case paywallProductsLoadRetry

  /// Information about a paywall presentation request
  case paywallPresentationRequest

  /// When the response to a paywall survey as been recorded.
  case surveyResponse

  /// When the user touches the app's UIWindow for the first time.
  ///
  /// This is only tracked if there is an active `touches_began` trigger in a campaign.
  case touchesBegan

  /// When the user taps the close button to skip the survey without recording a response.
  case surveyClose

  /// When ``Superwall/reset()`` is called.
  case reset

  /// When a restore is initiated.
  case restoreStart

  /// When a restore fails.
  case restoreFail

  /// When a restore completes.
  case restoreComplete

  /// When the Superwall configuration refreshes.
  case configRefresh

  /// When a custom placement on the paywall is tapped.
  case customPlacement

  /// When the attributes that affect the configuration of Superwall are set or change.
  case configAttributes

  /// When all the experiment assignments are confirmed by calling ``Superwall/confirmAllAssignments()``.
  case confirmAllAssignments

  /// When the Superwall configuration fails to be retrieved.
  case configFail

  /// When the AdServices token request starts.
  case adServicesTokenRequestStart

  /// When the AdServices token request fails.
  case adServicesTokenRequestFail

  /// When the AdServices token request finishes.
  case adServicesTokenRequestComplete

  /// When the shimmer view starts to show.
  case shimmerViewStart

  /// When the shimmer view stops showing.
  case shimmerViewComplete

  public init(placement: SuperwallPlacement) {
    self = placement.backingData.objcPlacement
  }

  var description: String {
    switch self {
    case .firstSeen:
      return "first_seen"
    case .appOpen:
      return "app_open"
    case .appLaunch:
      return "app_launch"
    case .identityAlias:
      return "identity_alias"
    case .appInstall:
      return "app_install"
    case .sessionStart:
      return "session_start"
    case .deviceAttributes:
      return "device_attributes"
    case .entitlementStatusDidChange:
      return "entitlementStatus_didChange"
    case .appClose:
      return "app_close"
    case .deepLink:
      return "deepLink_open"
    case .triggerFire:
      return "trigger_fire"
    case .paywallOpen:
      return "paywall_open"
    case .paywallDecline:
      return "paywall_decline"
    case .paywallClose:
      return "paywall_close"
    case .transactionStart:
      return "transaction_start"
    case .transactionFail:
      return "transaction_fail"
    case .transactionAbandon:
      return "transaction_abandon"
    case .transactionTimeout:
      return "transaction_timeout"
    case .transactionComplete:
      return "transaction_complete"
    case .subscriptionStart:
      return "subscription_start"
    case .freeTrialStart:
      return "freeTrial_start"
    case .transactionRestore:
      return "transaction_restore"
    case .userAttributes:
      return "user_attributes"
    case .nonRecurringProductPurchase:
      return "nonRecurringProduct_purchase"
    case .paywallResponseLoadStart:
      return "paywallResponseLoad_start"
    case .paywallResponseLoadNotFound:
      return "paywallResponseLoad_notFound"
    case .paywallResponseLoadFail:
      return "paywallResponseLoad_fail"
    case .paywallResponseLoadComplete:
      return "paywallResponseLoad_complete"
    case .paywallWebviewLoadStart:
      return "paywallWebviewLoad_start"
    case .paywallWebviewLoadFail:
      return "paywallWebviewLoad_fail"
    case .paywallWebviewLoadComplete:
      return "paywallWebviewLoad_complete"
    case .paywallWebviewLoadTimeout:
      return "paywallWebviewLoad_timeout"
    case .paywallWebviewLoadFallback:
      return "paywallWebviewLoad_fallback"
    case .paywallProductsLoadStart:
      return "paywallProductsLoad_start"
    case .paywallProductsLoadFail:
      return "paywallProductsLoad_fail"
    case .paywallProductsLoadRetry:
      return "paywallProductsLoad_retry"
    case .paywallProductsLoadComplete:
      return "paywallProductsLoad_complete"
    case .paywallPresentationRequest:
      return "paywallPresentationRequest"
    case .surveyResponse:
      return "survey_response"
    case .touchesBegan:
      return "touches_began"
    case .surveyClose:
      return "survey_close"
    case .reset:
      return "reset"
    case .restoreStart:
      return "restore_start"
    case .restoreFail:
      return "restore_fail"
    case .restoreComplete:
      return "restore_complete"
    case .configRefresh:
      return "config_refresh"
    case .customPlacement:
      return "custom_placement"
    case .configAttributes:
      return "config_attributes"
    case .confirmAllAssignments:
      return "confirm_all_assignments"
    case .configFail:
      return "config_fail"
    case .adServicesTokenRequestStart:
      return "adServicesTokenRequest_start"
    case .adServicesTokenRequestFail:
      return "adServicesTokenRequest_fail"
    case .adServicesTokenRequestComplete:
      return "adServicesTokenRequest_complete"
    case .shimmerViewStart:
      return "shimmerView_start"
    case .shimmerViewComplete:
      return "shimmerView_complete"
    }
  }
}
