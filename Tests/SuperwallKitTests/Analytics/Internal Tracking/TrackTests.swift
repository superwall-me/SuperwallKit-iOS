//
//  File.swift
//
//
//  Created by Yusuf Tör on 10/03/2023.
//
// swiftlint:disable all

import XCTest

@testable import SuperwallKit

final class TrackingTests: XCTestCase {
  func test_userInitiatedPlacement() async {
    let eventName = "MyEvent"
    let result = await Superwall.shared.track(
      UserInitiatedPlacement.Track(
        rawName: eventName,
        canImplicitlyTriggerPaywall: false,
        isFeatureGatable: false
      ))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertFalse(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertFalse(result.parameters.audienceFilterParams["$is_feature_gatable"] as! Bool)
    XCTAssertEqual(result.parameters.audienceFilterParams["$event_name"] as! String, eventName)
  }

  func test_appOpen() async {
    let result = await Superwall.shared.track(InternalSuperwallPlacement.AppOpen())
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(result.parameters.audienceFilterParams["$event_name"] as! String, "app_open")
  }

  func test_appInstall() async {
    let appInstalledAtString = "now"
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.AppInstall(
        appInstalledAtString: appInstalledAtString, hasExternalPurchaseController: true))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertTrue(result.parameters.audienceFilterParams["$using_purchase_controller"] as! Bool)
    XCTAssertEqual(result.parameters.audienceFilterParams["$event_name"] as! String, "app_install")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$application_installed_at"] as! String,
      appInstalledAtString)
  }

  func test_appLaunch() async {
    let result = await Superwall.shared.track(InternalSuperwallPlacement.AppLaunch())
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(result.parameters.audienceFilterParams["$event_name"] as! String, "app_launch")
  }

  func test_attributes() async {
    let appInstalledAtString = "now"
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.Attributes(appInstalledAtString: appInstalledAtString))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "user_attributes")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$application_installed_at"] as! String,
      appInstalledAtString)
  }

  func test_deepLink() async {
    let url = URL(string: "http://superwall.com/test?query=value#fragment")!
    let result = await Superwall.shared.track(InternalSuperwallPlacement.DeepLink(url: url))
    // "$app_session_id": "B993FB6C-556D-47E0-ADFE-E2E43365D732", "$is_standard_event": false, "$event_name": ""
    print(result)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "deepLink_open")
    XCTAssertEqual(result.parameters.audienceFilterParams["$url"] as! String, url.absoluteString)
    XCTAssertEqual(result.parameters.audienceFilterParams["$path"] as! String, url.path)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$pathExtension"] as! String, url.pathExtension)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$lastPathComponent"] as! String, url.lastPathComponent
    )
    XCTAssertEqual(result.parameters.audienceFilterParams["$host"] as! String, url.host!)
    XCTAssertEqual(result.parameters.audienceFilterParams["$query"] as! String, url.query!)
    XCTAssertEqual(result.parameters.audienceFilterParams["$fragment"] as! String, url.fragment!)
  }

  func test_firstSeen() async {
    let result = await Superwall.shared.track(InternalSuperwallPlacement.FirstSeen())
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(result.parameters.audienceFilterParams["$event_name"] as! String, "first_seen")
  }

  func test_appClose() async {
    let result = await Superwall.shared.track(InternalSuperwallPlacement.AppClose())
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(result.parameters.audienceFilterParams["$event_name"] as! String, "app_close")
  }

  func test_sessionStart() async {
    let result = await Superwall.shared.track(InternalSuperwallPlacement.SessionStart())
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "session_start")
  }

  func test_surveyResponse() async {
    // Given
    let survey = Survey.stub()
    let paywallInfo = PaywallInfo.stub()
    let event = InternalSuperwallPlacement.SurveyResponse(
      survey: survey,
      selectedOption: survey.options.first!,
      customResponse: nil,
      paywallInfo: paywallInfo
    )
    // When
    let result = await Superwall.shared.track(event)

    print(result.parameters.audienceFilterParams)

    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "survey_response")
    XCTAssertEqual(result.parameters.audienceFilterParams["$survey_id"] as! String, survey.id)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$survey_selected_option_id"] as! String,
      survey.options.first!.id)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$survey_assignment_key"] as! String,
      survey.assignmentKey)
    XCTAssertNil(result.parameters.audienceFilterParams["$survey_custom_response"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["survey_selected_option_title"] as! String,
      survey.assignmentKey)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String, "survey_response")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["survey_selected_option_title"] as! String,
      survey.assignmentKey)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)

    XCTAssertTrue(result.parameters.delegateParams["is_superwall"] as! Bool)
    XCTAssertEqual(
      result.parameters.delegateParams["survey_selected_option_title"] as! String,
      survey.assignmentKey)
    XCTAssertEqual(result.parameters.delegateParams["survey_id"] as! String, survey.id)
    XCTAssertEqual(
      result.parameters.delegateParams["survey_selected_option_id"] as! String,
      survey.options.first!.id)
    XCTAssertEqual(
      result.parameters.delegateParams["survey_assignment_key"] as! String, survey.assignmentKey)
    XCTAssertNil(result.parameters.delegateParams["survey_custom_response"])
    XCTAssertEqual(
      result.parameters.delegateParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.delegateParams["paywall_identifier"] as! String, paywallInfo.identifier)
    XCTAssertEqual(result.parameters.delegateParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.delegateParams["paywall_url"] as! String, paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.delegateParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.delegateParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.delegateParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.delegateParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.delegateParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.delegateParams["tertiary_product_id"])
  }

  func test_paywallLoad_start() async {
    let eventName = "name"
    let params = ["hello": true]
    let eventData = PlacementData(
      name: eventName,
      parameters: JSON(params),
      createdAt: Date()
    )
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.PaywallLoad(state: .start, placementData: eventData))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywallResponseLoad_start")
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_triggered_from_event"] as! Bool)
  }

  func test_paywallLoad_fail() async {
    let eventName = "name"
    let params = ["hello": true]
    let eventData = PlacementData(
      name: eventName,
      parameters: JSON(params),
      createdAt: Date()
    )
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.PaywallLoad(state: .fail, placementData: eventData))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywallResponseLoad_fail")
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_triggered_from_event"] as! Bool)
  }

  func test_paywallLoad_notFound() async {
    let eventName = "name"
    let params = ["hello": true]
    let eventData = PlacementData(
      name: eventName,
      parameters: JSON(params),
      createdAt: Date()
    )
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.PaywallLoad(state: .notFound, placementData: eventData))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String,
      "paywallResponseLoad_notFound")
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_triggered_from_event"] as! Bool)
  }

  func test_paywallLoad_complete() async {
    let eventName = "name"
    let params = ["hello": true]
    let eventData = PlacementData(
      name: eventName,
      parameters: JSON(params),
      createdAt: Date()
    )
    let paywallInfo = PaywallInfo.stub()
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.PaywallLoad(
        state: .complete(paywallInfo: paywallInfo), placementData: eventData))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String,
      "paywallResponseLoad_complete")
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_triggered_from_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String,
      "paywallResponseLoad_complete")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_entitlementStatusDidChange_hasOneEntitlement() async {
    let entitlements: Set<Entitlement> = [.stub()]
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.EntitlementStatusDidChange(status: .active([.stub()])))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String,
      "entitlementStatus_didChange")
    XCTAssertEqual(result.parameters.audienceFilterParams["$status"] as! String, "ACTIVE")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$active_entitlement_ids"] as! String,
      entitlements.map { $0.id }.joined())
  }

  func test_subscriptionStatusDidChange_hasTwoEntitlements() async {
    let entitlements: Set<Entitlement> = [.stub(), Entitlement(id: "test2", type: .serviceLevel)]
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.EntitlementStatusDidChange(status: .active(entitlements)))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String,
      "entitlementStatus_didChange")
    XCTAssertEqual(result.parameters.audienceFilterParams["$status"] as! String, "ACTIVE")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$active_entitlement_ids"] as! String,
      entitlements.map { $0.id }.joined())
  }

  func test_subscriptionStatusDidChange_noEntitlements() async {
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.EntitlementStatusDidChange(status: .inactive))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String,
      "entitlementStatus_didChange")
    XCTAssertEqual(result.parameters.audienceFilterParams["$status"] as! String, "INACTIVE")
    XCTAssertNil(result.parameters.audienceFilterParams["$active_entitlement_ids"] as? String)
  }

  func test_triggerFire_noRuleMatch() async {
    let triggerName = "My Trigger"
    let unmatchedRules: [UnmatchedAudience] = [
      .init(source: .expression, experimentId: "1"),
      .init(source: .occurrence, experimentId: "2"),
    ]
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.TriggerFire(
        triggerResult: .noAudienceMatch(unmatchedRules), triggerName: triggerName))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(result.parameters.audienceFilterParams["$event_name"] as! String, "trigger_fire")
    XCTAssertEqual(result.parameters.audienceFilterParams["$result"] as! String, "no_rule_match")
    XCTAssertEqual(result.parameters.audienceFilterParams["$trigger_name"] as! String, triggerName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$unmatched_audience_1"] as! String, "EXPRESSION")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$unmatched_audience_2"] as! String, "OCCURRENCE")
    // TODO: Missing test for trigger_session_id here. Need to figure out a way to activate it
  }

  func test_triggerFire_holdout() async {
    let triggerName = "My Trigger"
    let experiment: Experiment = .stub()
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.TriggerFire(
        triggerResult: .holdout(experiment), triggerName: triggerName))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(result.parameters.audienceFilterParams["$event_name"] as! String, "trigger_fire")
    XCTAssertEqual(result.parameters.audienceFilterParams["$trigger_name"] as! String, triggerName)
    XCTAssertEqual(result.parameters.audienceFilterParams["$result"] as! String, "holdout")
    XCTAssertEqual(result.parameters.audienceFilterParams["$trigger_name"] as! String, triggerName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$variant_id"] as! String, experiment.variant.id)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$experiment_id"] as! String, experiment.id)
  }

  func test_triggerFire_paywall() async {
    let triggerName = "My Trigger"
    let experiment: Experiment = .stub()
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.TriggerFire(
        triggerResult: .paywall(experiment), triggerName: triggerName))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(result.parameters.audienceFilterParams["$event_name"] as! String, "trigger_fire")
    XCTAssertEqual(result.parameters.audienceFilterParams["$trigger_name"] as! String, triggerName)
    XCTAssertEqual(result.parameters.audienceFilterParams["$result"] as! String, "present")
    XCTAssertEqual(result.parameters.audienceFilterParams["$trigger_name"] as! String, triggerName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$variant_id"] as! String, experiment.variant.id)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      experiment.variant.paywallId!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$experiment_id"] as! String, experiment.id)
  }

  func test_triggerFire_eventNotFound() async {
    let triggerName = "My Trigger"
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.TriggerFire(
        triggerResult: .placementNotFound, triggerName: triggerName))
    print(result)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(result.parameters.audienceFilterParams["$result"] as! String, "eventNotFound")
    XCTAssertEqual(result.parameters.audienceFilterParams["$event_name"] as! String, "trigger_fire")
  }

  func test_triggerFire_error() async {
    let triggerName = "My Trigger"
    let error = NSError(domain: "com.superwall", code: 400)
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.TriggerFire(triggerResult: .error(error), triggerName: triggerName)
    )
    print(result)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(result.parameters.audienceFilterParams["$result"] as! String, "error")
    XCTAssertEqual(result.parameters.audienceFilterParams["$event_name"] as! String, "trigger_fire")
  }

  func test_presentationRequest_eventNotFound() async {
    let dependencyContainer = DependencyContainer()
    let placementData: PlacementData = .stub()
    let event = InternalSuperwallPlacement.PresentationRequest(
      placementData: placementData,
      type: .getPaywall(.stub()),
      status: .noPresentation,
      statusReason: .placementNotFound,
      factory: dependencyContainer
    )
    let result = await Superwall.shared.track(event)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywallPresentationRequest"
    )
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$source_event_name"] as! String, placementData.name)
    XCTAssertEqual(result.parameters.audienceFilterParams["$status"] as! String, "no_presentation")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$pipeline_type"] as! String,
      "getPaywallViewController")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$status_reason"] as! String, "event_not_found")
  }

  func test_presentationRequest_noRuleMatch() async {
    let dependencyContainer = DependencyContainer()
    let placementData: PlacementData = .stub()
    let event = InternalSuperwallPlacement.PresentationRequest(
      placementData: placementData,
      type: .getPaywall(.stub()),
      status: .noPresentation,
      statusReason: .noAudienceMatch,
      factory: dependencyContainer
    )
    let result = await Superwall.shared.track(event)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywallPresentationRequest"
    )
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$source_event_name"] as! String, placementData.name)
    XCTAssertEqual(result.parameters.audienceFilterParams["$status"] as! String, "no_presentation")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$pipeline_type"] as! String,
      "getPaywallViewController")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$status_reason"] as! String, "no_rule_match")
    XCTAssertNil(result.parameters.audienceFilterParams["$expression_params"] as? String)
  }

  func test_presentationRequest_expressionParams() async {
    let dependencyContainer = DependencyContainer()
    dependencyContainer.configManager.configState.send(
      .retrieved(.stub().setting(\.featureFlags.enableExpressionParameters, to: true)))
    let placementData: PlacementData = .stub()
    let event = InternalSuperwallPlacement.PresentationRequest(
      placementData: placementData,
      type: .getPaywall(.stub()),
      status: .noPresentation,
      statusReason: .noAudienceMatch,
      factory: dependencyContainer
    )
    let result = await Superwall.shared.track(event)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywallPresentationRequest"
    )
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$source_event_name"] as! String, placementData.name)
    XCTAssertEqual(result.parameters.audienceFilterParams["$status"] as! String, "no_presentation")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$pipeline_type"] as! String,
      "getPaywallViewController")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$status_reason"] as! String, "no_rule_match")
    XCTAssertNotNil(result.parameters.audienceFilterParams["$expression_params"] as! String)
  }

  func test_presentationRequest_alreadyPresented() async {
    let dependencyContainer = DependencyContainer()
    let placementData: PlacementData = .stub()
    let event = InternalSuperwallPlacement.PresentationRequest(
      placementData: placementData,
      type: .getPaywall(.stub()),
      status: .noPresentation,
      statusReason: .paywallAlreadyPresented,
      factory: dependencyContainer
    )
    let result = await Superwall.shared.track(event)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywallPresentationRequest"
    )
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$source_event_name"] as! String, placementData.name)
    XCTAssertEqual(result.parameters.audienceFilterParams["$status"] as! String, "no_presentation")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$pipeline_type"] as! String,
      "getPaywallViewController")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$status_reason"] as! String,
      "paywall_already_presented")
  }
  // TODO: Add test for expression params
  func test_presentationRequest_debuggerLaunched() async {
    let dependencyContainer = DependencyContainer()
    let placementData: PlacementData = .stub()
    let event = InternalSuperwallPlacement.PresentationRequest(
      placementData: placementData,
      type: .getPaywall(.stub()),
      status: .noPresentation,
      statusReason: .debuggerPresented,
      factory: dependencyContainer
    )
    let result = await Superwall.shared.track(event)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywallPresentationRequest"
    )
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$source_event_name"] as! String, placementData.name)
    XCTAssertEqual(result.parameters.audienceFilterParams["$status"] as! String, "no_presentation")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$pipeline_type"] as! String,
      "getPaywallViewController")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$status_reason"] as! String, "debugger_presented")
  }

  func test_presentationRequest_noPresenter() async {
    let dependencyContainer = DependencyContainer()
    let placementData: PlacementData = .stub()
    let event = InternalSuperwallPlacement.PresentationRequest(
      placementData: placementData,
      type: .getPaywall(.stub()),
      status: .noPresentation,
      statusReason: .noPresenter,
      factory: dependencyContainer
    )
    let result = await Superwall.shared.track(event)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywallPresentationRequest"
    )
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$source_event_name"] as! String, placementData.name)
    XCTAssertEqual(result.parameters.audienceFilterParams["$status"] as! String, "no_presentation")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$pipeline_type"] as! String,
      "getPaywallViewController")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$status_reason"] as! String, "no_presenter")
  }

  func test_presentationRequest_noPaywallViewController() async {
    let dependencyContainer = DependencyContainer()
    let placementData: PlacementData = .stub()
    let event = InternalSuperwallPlacement.PresentationRequest(
      placementData: placementData,
      type: .getPaywall(.stub()),
      status: .noPresentation,
      statusReason: .noPaywallViewController,
      factory: dependencyContainer
    )
    let result = await Superwall.shared.track(event)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywallPresentationRequest"
    )
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$source_event_name"] as! String, placementData.name)
    XCTAssertEqual(result.parameters.audienceFilterParams["$status"] as! String, "no_presentation")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$pipeline_type"] as! String,
      "getPaywallViewController")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$status_reason"] as! String,
      "no_paywall_view_controller")
  }

  func test_presentationRequest_holdout() async {
    let dependencyContainer = DependencyContainer()
    let placementData: PlacementData = .stub()
    let event = InternalSuperwallPlacement.PresentationRequest(
      placementData: placementData,
      type: .getPaywall(.stub()),
      status: .noPresentation,
      statusReason: .holdout(.stub()),
      factory: dependencyContainer
    )
    let result = await Superwall.shared.track(event)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywallPresentationRequest"
    )
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$source_event_name"] as! String, placementData.name)
    XCTAssertEqual(result.parameters.audienceFilterParams["$status"] as! String, "no_presentation")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$pipeline_type"] as! String,
      "getPaywallViewController")
    XCTAssertEqual(result.parameters.audienceFilterParams["$status_reason"] as! String, "holdout")
  }

  func test_paywallOpen() async {
    let paywallInfo: PaywallInfo = .stub()
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.PaywallOpen(paywallInfo: paywallInfo))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)

    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presentation_source_type"] as? String,
      paywallInfo.presentationSourceType)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(result.parameters.audienceFilterParams["$event_name"] as! String, "paywall_open")

    // Custom parameters
    XCTAssertEqual(result.parameters.audienceFilterParams["event_name"] as! String, "paywall_open")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_paywallClose_survey_show() async {
    let paywall: Paywall = .stub()
      .setting(\.surveys, to: [.stub()])
    let paywallInfo = paywall.getInfo(fromPlacement: .stub())
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.PaywallClose(
        paywallInfo: paywallInfo,
        surveyPresentationResult: .show
      )
    )
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)

    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywall_close")
    XCTAssertTrue(result.parameters.audienceFilterParams["$survey_attached"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$survey_presentation"] as! String, "show")

    // Custom parameters
    XCTAssertEqual(result.parameters.audienceFilterParams["event_name"] as! String, "paywall_close")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_paywallClose_survey_noShow() async {
    let paywall: Paywall = .stub()
      .setting(\.surveys, to: [.stub()])
    let paywallInfo = paywall.getInfo(fromPlacement: .stub())
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.PaywallClose(
        paywallInfo: paywallInfo,
        surveyPresentationResult: .noShow
      )
    )
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)

    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywall_close")
    XCTAssertTrue(result.parameters.audienceFilterParams["$survey_attached"] as! Bool)
    XCTAssertNil(result.parameters.audienceFilterParams["$survey_presentation"])

    // Custom parameters
    XCTAssertEqual(result.parameters.audienceFilterParams["event_name"] as! String, "paywall_close")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_paywallClose_survey_holdout() async {
    let paywall: Paywall = .stub()
      .setting(\.surveys, to: [.stub()])
    let paywallInfo = paywall.getInfo(fromPlacement: .stub())
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.PaywallClose(
        paywallInfo: paywallInfo,
        surveyPresentationResult: .holdout
      )
    )
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)

    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywall_close")
    XCTAssertTrue(result.parameters.audienceFilterParams["$survey_attached"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$survey_presentation"] as! String, "holdout")

    // Custom parameters
    XCTAssertEqual(result.parameters.audienceFilterParams["event_name"] as! String, "paywall_close")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_paywallClose_noSurvey() async {
    let paywall: Paywall = .stub()
      .setting(\.surveys, to: [])
    let paywallInfo = paywall.getInfo(fromPlacement: .stub())
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.PaywallClose(
        paywallInfo: paywallInfo,
        surveyPresentationResult: .noShow
      )
    )
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)

    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywall_close")
    XCTAssertFalse(result.parameters.audienceFilterParams["$survey_attached"] as! Bool)
    XCTAssertNil(result.parameters.audienceFilterParams["$survey_presentation"])

    // Custom parameters
    XCTAssertEqual(result.parameters.audienceFilterParams["event_name"] as! String, "paywall_close")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_paywallDecline() async {
    let paywallInfo: PaywallInfo = .stub()
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.PaywallDecline(paywallInfo: paywallInfo))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)

    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywall_decline")

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String, "paywall_decline")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_transaction_start() async {
    let paywallInfo: PaywallInfo = .stub()
    let productId = "abc"
    let product = StoreProduct(
      sk1Product: MockSkProduct(productIdentifier: productId),
      entitlements: [.stub()]
    )
    let dependencyContainer = DependencyContainer()
    let skTransaction = MockSKPaymentTransaction(state: .purchased)
    let transaction = await dependencyContainer.makeStoreTransaction(from: skTransaction)
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.Transaction(
        state: .start(product), paywallInfo: paywallInfo, product: product,
        transaction: transaction, source: .internal, isObserved: false, storeKitVersion: .storeKit1)
    )
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)

    XCTAssertEqual(result.parameters.audienceFilterParams["$source"] as! String, "SUPERWALL")
    XCTAssertEqual(result.parameters.audienceFilterParams["$store"] as! String, "APP_STORE")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$storekit_version"] as! String, "STOREKIT1")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(result.parameters.audienceFilterParams["$product_id"] as! String, productId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$product_identifier"] as! String, productId)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_raw_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_alt"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_localized_period"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_periodly"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_weekly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_daily_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_monthly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_yearly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_days"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_weeks"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_months"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_years"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_text"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_end_date"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_days"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_weeks"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_months"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_years"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_locale"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_language_code"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_currency_code"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_currency_symbol"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$tertiary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$original_transaction_identifier"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$config_request_id"])
    XCTAssertEqual(result.parameters.audienceFilterParams["$state"] as! String, "PURCHASED")
    XCTAssertNotNil(result.parameters.audienceFilterParams["$id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "transaction_start")

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String, "transaction_start")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_transaction_complete() async {
    let paywallInfo: PaywallInfo = .stub()
    let productId = "abc"
    let product = StoreProduct(
      sk1Product: MockSkProduct(productIdentifier: productId),
      entitlements: [.stub()]
    )
    let dependencyContainer = DependencyContainer()
    let skTransaction = MockSKPaymentTransaction(state: .purchased)
    let transaction = await dependencyContainer.makeStoreTransaction(from: skTransaction)
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.Transaction(
        state: .complete(product, transaction, .nonRecurringProductPurchase),
        paywallInfo: paywallInfo, product: product, transaction: transaction, source: .internal,
        isObserved: false, storeKitVersion: .storeKit1))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)

    XCTAssertEqual(result.parameters.audienceFilterParams["$source"] as! String, "SUPERWALL")
    XCTAssertEqual(result.parameters.audienceFilterParams["$store"] as! String, "APP_STORE")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$storekit_version"] as! String, "STOREKIT1")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$transaction_type"] as! String,
      "NON_RECURRING_PRODUCT_PURCHASE")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(result.parameters.audienceFilterParams["$product_id"] as! String, productId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$product_identifier"] as! String, productId)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_raw_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_alt"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_localized_period"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_periodly"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_weekly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_daily_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_monthly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_yearly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_days"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_weeks"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_months"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_years"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_text"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_end_date"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_days"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_weeks"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_months"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_years"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_locale"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_language_code"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_currency_code"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_currency_symbol"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$tertiary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$original_transaction_identifier"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$config_request_id"])
    XCTAssertEqual(result.parameters.audienceFilterParams["$state"] as! String, "PURCHASED")
    XCTAssertNotNil(result.parameters.audienceFilterParams["$id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "transaction_complete")

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String, "transaction_complete")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_transaction_restore() async {
    let paywallInfo: PaywallInfo = .stub()
    let productId = "abc"
    let product = StoreProduct(
      sk1Product: MockSkProduct(productIdentifier: productId),
      entitlements: [.stub()]
    )
    let dependencyContainer = DependencyContainer()
    let skTransaction = MockSKPaymentTransaction(state: .purchased)
    let transaction = await dependencyContainer.makeStoreTransaction(from: skTransaction)
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.Transaction(
        state: .restore(RestoreType.viaPurchase(transaction)), paywallInfo: paywallInfo,
        product: product, transaction: transaction, source: .internal, isObserved: false,
        storeKitVersion: .storeKit2))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)

    XCTAssertEqual(result.parameters.audienceFilterParams["$source"] as! String, "SUPERWALL")
    XCTAssertEqual(result.parameters.audienceFilterParams["$store"] as! String, "APP_STORE")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$storekit_version"] as! String, "STOREKIT2")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertTrue(result.parameters.audienceFilterParams["$restore_via_purchase_attempt"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(result.parameters.audienceFilterParams["$product_id"] as! String, productId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$product_identifier"] as! String, productId)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_raw_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_alt"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_localized_period"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_periodly"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_weekly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_daily_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_monthly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_yearly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_days"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_weeks"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_months"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_years"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_text"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_end_date"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_days"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_weeks"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_months"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_years"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_locale"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_language_code"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_currency_code"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_currency_symbol"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$tertiary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$original_transaction_identifier"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$config_request_id"])
    XCTAssertEqual(result.parameters.audienceFilterParams["$state"] as! String, "PURCHASED")
    XCTAssertNotNil(result.parameters.audienceFilterParams["$id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "transaction_restore")

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String, "transaction_restore")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_transaction_timeout() async {
    let paywallInfo: PaywallInfo = .stub()
    let productId = "abc"
    let product = StoreProduct(
      sk1Product: MockSkProduct(productIdentifier: productId),
      entitlements: [.stub()]
    )
    let dependencyContainer = DependencyContainer()
    let skTransaction = MockSKPaymentTransaction(state: .purchased)
    let transaction = await dependencyContainer.makeStoreTransaction(from: skTransaction)
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.Transaction(
        state: .timeout, paywallInfo: paywallInfo, product: product, transaction: transaction,
        source: .internal, isObserved: false, storeKitVersion: .storeKit1))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)

    XCTAssertEqual(result.parameters.audienceFilterParams["$source"] as! String, "SUPERWALL")
    XCTAssertEqual(result.parameters.audienceFilterParams["$store"] as! String, "APP_STORE")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$storekit_version"] as! String, "STOREKIT1")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(result.parameters.audienceFilterParams["$product_id"] as! String, productId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$product_identifier"] as! String, productId)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_raw_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_alt"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_localized_period"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_periodly"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_weekly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_daily_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_monthly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_yearly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_days"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_weeks"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_months"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_years"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_text"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_end_date"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_days"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_weeks"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_months"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_years"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_locale"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_language_code"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_currency_code"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_currency_symbol"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$tertiary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$original_transaction_identifier"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$config_request_id"])
    XCTAssertEqual(result.parameters.audienceFilterParams["$state"] as! String, "PURCHASED")
    XCTAssertNotNil(result.parameters.audienceFilterParams["$id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "transaction_timeout")

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String, "transaction_timeout")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_transaction_fail() async {
    let paywallInfo: PaywallInfo = .stub()
    let productId = "abc"
    let product = StoreProduct(
      sk1Product: MockSkProduct(productIdentifier: productId),
      entitlements: [.stub()]
    )
    let dependencyContainer = DependencyContainer()
    let skTransaction = MockSKPaymentTransaction(state: .purchased)
    let transaction = await dependencyContainer.makeStoreTransaction(from: skTransaction)
    let error = TransactionError.failure("failed mate", product)
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.Transaction(
        state: .fail(error), paywallInfo: paywallInfo, product: product, transaction: transaction,
        source: .external, isObserved: false, storeKitVersion: .storeKit1))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)

    XCTAssertEqual(result.parameters.audienceFilterParams["$source"] as! String, "APP")
    XCTAssertEqual(result.parameters.audienceFilterParams["$store"] as! String, "APP_STORE")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$storekit_version"] as! String, "STOREKIT1")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(result.parameters.audienceFilterParams["$product_id"] as! String, productId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$product_identifier"] as! String, productId)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_raw_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_alt"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_localized_period"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_periodly"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_weekly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_daily_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_monthly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_yearly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_days"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_weeks"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_months"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_years"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_text"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_end_date"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_days"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_weeks"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_months"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_years"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_locale"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_language_code"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_currency_code"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_currency_symbol"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$tertiary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertEqual(result.parameters.audienceFilterParams["$message"] as! String, "failed mate")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "transaction_fail")

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String, "transaction_fail")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_subscriptionStart() async {
    let paywallInfo: PaywallInfo = .stub()
    let productId = "abc"
    let product = StoreProduct(
      sk1Product: MockSkProduct(productIdentifier: productId),
      entitlements: [.stub()]
    )
    let skTransaction = MockSKPaymentTransaction(state: .purchased)
    let dependencyContainer = DependencyContainer()
    let transaction = await dependencyContainer.makeStoreTransaction(from: skTransaction)
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.SubscriptionStart(
        paywallInfo: paywallInfo, product: product, transaction: transaction))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "subscription_start")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(result.parameters.audienceFilterParams["$product_id"] as! String, productId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$product_identifier"] as! String, productId)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_raw_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_alt"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_localized_period"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_periodly"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_weekly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_daily_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_monthly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_yearly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_days"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_weeks"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_months"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_years"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_text"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_end_date"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_days"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_weeks"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_months"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_years"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_locale"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_language_code"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_currency_code"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_currency_symbol"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$tertiary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String, "subscription_start")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_freeTrialStart() async {
    let paywallInfo: PaywallInfo = .stub()
    let productId = "abc"
    let product = StoreProduct(
      sk1Product: MockSkProduct(productIdentifier: productId),
      entitlements: [.stub()]
    )
    let skTransaction = MockSKPaymentTransaction(state: .purchased)
    let dependencyContainer = DependencyContainer()
    let transaction = await dependencyContainer.makeStoreTransaction(from: skTransaction)
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.FreeTrialStart(
        paywallInfo: paywallInfo, product: product, transaction: transaction))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "freeTrial_start")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(result.parameters.audienceFilterParams["$product_id"] as! String, productId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$product_identifier"] as! String, productId)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_raw_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_alt"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_localized_period"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_periodly"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_weekly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_daily_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_monthly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_yearly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_days"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_weeks"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_months"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_years"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_text"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_end_date"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_days"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_weeks"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_months"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_years"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_locale"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_language_code"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_currency_code"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_currency_symbol"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$tertiary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String, "freeTrial_start")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_nonRecurringProductPurchase() async {
    let paywallInfo: PaywallInfo = .stub()
    let productId = "abc"
    let product = StoreProduct(
      sk1Product: MockSkProduct(productIdentifier: productId),
      entitlements: [.stub()]
    )
    let skTransaction = MockSKPaymentTransaction(state: .purchased)
    let dependencyContainer = DependencyContainer()
    let transaction = await dependencyContainer.makeStoreTransaction(from: skTransaction)
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.NonRecurringProductPurchase(
        paywallInfo: paywallInfo, product: product, transaction: transaction))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String,
      "nonRecurringProduct_purchase")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(result.parameters.audienceFilterParams["$product_id"] as! String, productId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$product_identifier"] as! String, productId)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_raw_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_alt"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_localized_period"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_periodly"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_weekly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_daily_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_monthly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_yearly_price"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_days"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_weeks"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_months"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_years"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_text"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_trial_period_end_date"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_days"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_weeks"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_months"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_period_years"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_locale"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_language_code"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_currency_code"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$product_currency_symbol"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$tertiary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String,
      "nonRecurringProduct_purchase")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_paywallWebviewLoad_start() async {
    let paywallInfo: PaywallInfo = .stub()
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.PaywallWebviewLoad(state: .start, paywallInfo: paywallInfo))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywallWebviewLoad_start")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$tertiary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String, "paywallWebviewLoad_start")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_paywallWebviewLoad_fail() async {
    let paywallInfo: PaywallInfo = .stub()
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.PaywallWebviewLoad(
        state: .fail(NetworkError.unknown, []), paywallInfo: paywallInfo))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywallWebviewLoad_fail")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$tertiary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String, "paywallWebviewLoad_fail")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_paywallWebviewLoad_complete() async {
    let paywallInfo: PaywallInfo = .stub()
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.PaywallWebviewLoad(state: .complete, paywallInfo: paywallInfo))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String,
      "paywallWebviewLoad_complete")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$tertiary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String, "paywallWebviewLoad_complete"
    )
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_paywallWebviewLoad_timeout() async {
    let paywallInfo: PaywallInfo = .stub()
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.PaywallWebviewLoad(state: .timeout, paywallInfo: paywallInfo))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywallWebviewLoad_timeout"
    )
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$tertiary_product_id"])

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String, "paywallWebviewLoad_timeout")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_paywallProductsLoad_start() async {
    let paywallInfo: PaywallInfo = .stub()
    let placementData: PlacementData = .stub()
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.PaywallProductsLoad(
        state: .start, paywallInfo: paywallInfo, placementData: placementData))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywallProductsLoad_start")
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_triggered_from_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$tertiary_product_id"])

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String, "paywallProductsLoad_start")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_paywallProductsLoad_fail() async {
    let paywallInfo: PaywallInfo = .stub()
    let placementData: PlacementData = .stub()
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.PaywallProductsLoad(
        state: .fail(NetworkError.unknown), paywallInfo: paywallInfo, placementData: placementData))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String, "paywallProductsLoad_fail")
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_triggered_from_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$tertiary_product_id"])

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String, "paywallProductsLoad_fail")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }

  func test_paywallProductsLoad_complete() async {
    let paywallInfo: PaywallInfo = .stub()
    let placementData: PlacementData = .stub()
    let result = await Superwall.shared.track(
      InternalSuperwallPlacement.PaywallProductsLoad(
        state: .complete, paywallInfo: paywallInfo, placementData: placementData))
    XCTAssertNotNil(result.parameters.audienceFilterParams["$app_session_id"])
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$event_name"] as! String,
      "paywallProductsLoad_complete")
    XCTAssertTrue(result.parameters.audienceFilterParams["$is_triggered_from_event"] as! Bool)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywalljs_version"] as? String,
      paywallInfo.paywalljsVersion)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_identifier"] as! String,
      paywallInfo.identifier)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_url"] as! String,
      paywallInfo.url.absoluteString)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_id"] as? String,
      paywallInfo.presentedByPlacementWithId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by_event_timestamp"] as? String,
      paywallInfo.presentedByPlacementAt)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_start_time"] as! String,
      paywallInfo.responseLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_complete_time"] as! String,
      paywallInfo.responseLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_response_load_duration"] as? TimeInterval,
      paywallInfo.responseLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_start_time"] as! String,
      paywallInfo.webViewLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_complete_time"] as! String,
      paywallInfo.webViewLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_webview_load_duration"] as? TimeInterval,
      paywallInfo.webViewLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_start_time"] as! String,
      paywallInfo.productsLoadStartTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_complete_time"] as! String,
      paywallInfo.productsLoadCompleteTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_fail_time"] as! String,
      paywallInfo.productsLoadFailTime!)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$paywall_products_load_duration"] as? TimeInterval,
      paywallInfo.productsLoadDuration)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["$is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertNotNil(result.parameters.audienceFilterParams["$primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["$tertiary_product_id"])

    // Custom parameters
    XCTAssertEqual(
      result.parameters.audienceFilterParams["event_name"] as! String,
      "paywallProductsLoad_complete")
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_id"] as! String, paywallInfo.databaseId)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_name"] as! String, paywallInfo.name)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["is_free_trial_available"] as! Bool,
      paywallInfo.isFreeTrialAvailable)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["feature_gating"] as! String,
      FeatureGatingBehavior.nonGated.description)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by"] as! String, paywallInfo.presentedBy)
    XCTAssertEqual(
      result.parameters.audienceFilterParams["paywall_product_ids"] as? String,
      paywallInfo.productIds.joined(separator: ","))
    XCTAssertNotNil(result.parameters.audienceFilterParams["primary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["secondary_product_id"])
    XCTAssertNotNil(result.parameters.audienceFilterParams["tertiary_product_id"])
    XCTAssertEqual(
      result.parameters.audienceFilterParams["presented_by_event_name"] as? String,
      paywallInfo.presentedByPlacementWithName)
  }
}
