//
//  InternalEventLogicTests.swift
//  
//
//  Created by Yusuf Tör on 22/04/2022.
//
// swiftlint:disable all

import XCTest
@testable import SuperwallKit

@available(iOS 14.0, *)
final class TrackingLogicTests: XCTestCase {
  func testProcessParameters_superwallEvent_noParams() async {
    // Given
    let event = InternalSuperwallEvent.AppLaunch()

    // When
    let parameters = await TrackingLogic.processParameters(
      fromTrackableEvent: event,
      appSessionId: "abc"
    )

    XCTAssertTrue(parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertTrue(parameters.delegateParams["is_superwall"] as! Bool)
  }
/*
  func testProcessParameters_superwallEvent_noParams_firedTwice() {
    // Given
    let event = SuperwallEvent.AppLaunch()
    let storage = StorageMock(internalTriggeredEvents: [
      event.rawName: [.stub()]
    ])

    // When
    let parameters = TrackingLogic.processParameters(
      fromTrackableEvent: event,
      storage: storage
    )

    XCTAssertTrue(parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertTrue(parameters.delegateParams["is_superwall"] as! Bool)
    XCTAssertEqual(parameters.audienceFilterParams["$count_24h"] as! Int, 2)
  }*/

  func testProcessParameters_userEvent_noParams() async {
    // Given
    let event = UserInitiatedEvent.Track(
      rawName: "test",
      canImplicitlyTriggerPaywall: false,
      isFeatureGatable: false
    )

    // When
    let parameters = await TrackingLogic.processParameters(
      fromTrackableEvent: event,
      appSessionId: "abc"
    )

    XCTAssertFalse(parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertFalse(parameters.audienceFilterParams["$is_feature_gatable"] as! Bool)
    XCTAssertTrue(parameters.delegateParams["is_superwall"] as! Bool)
  }
/*
  func testProcessParameters_userEvent_noParams_firedTwice() {
    // Given
    let event = UserInitiatedEvent.Track(
      rawName: "test",
      canImplicitlyTriggerPaywall: false
    )
    let storage = StorageMock(internalTriggeredEvents: [
      "test": [.stub()]
    ])

    // When
    let parameters = TrackingLogic.processParameters(
      fromTrackableEvent: event,
      storage: storage
    )

    XCTAssertFalse(parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertTrue(parameters.delegateParams["is_superwall"] as! Bool)
    XCTAssertEqual(parameters.audienceFilterParams["$count_24h"] as! Int, 2)
  }
*/

  func testProcessParameters_paywallLoad() async {
    // Given
    let eventName = "TestName"
    let event = InternalSuperwallEvent.PaywallLoad(
      state: .start,
      eventData: EventData
        .stub()
        .setting(\.name, to: eventName)
    )
    // When
    let parameters = await TrackingLogic.processParameters(
      fromTrackableEvent: event,
      appSessionId: "abc"
    )

    XCTAssertTrue(parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertTrue(parameters.audienceFilterParams["$is_triggered_from_event"] as! Bool)
    XCTAssertEqual(parameters.audienceFilterParams["$event_name"] as! String, "paywallResponseLoad_start")
    XCTAssertTrue(parameters.delegateParams["is_superwall"] as! Bool)
    XCTAssertTrue(parameters.delegateParams["is_triggered_from_event"] as! Bool)
  }

  func testProcessParameters_attributes_withCustomParams() async {
    // Given
    let event = InternalSuperwallEvent.Attributes(
      appInstalledAtString: "abc",
      audienceFilterParams: [
        "myCustomParam": "hello",
        "otherParam": true
      ]
    )
    // When
    let parameters = await TrackingLogic.processParameters(
      fromTrackableEvent: event,
      appSessionId: "abc"
    )

    XCTAssertTrue(parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(parameters.audienceFilterParams["$application_installed_at"] as! String, "abc")
    XCTAssertEqual(parameters.audienceFilterParams["$event_name"] as! String, "user_attributes")
    XCTAssertEqual(parameters.audienceFilterParams["myCustomParam"] as! String, "hello")
    XCTAssertTrue(parameters.audienceFilterParams["otherParam"] as! Bool)
    XCTAssertTrue(parameters.delegateParams["is_superwall"] as! Bool)
    XCTAssertEqual(parameters.delegateParams["application_installed_at"] as! String, "abc")
    XCTAssertEqual(parameters.delegateParams["myCustomParam"] as! String, "hello")
    XCTAssertTrue(parameters.delegateParams["otherParam"] as! Bool)
  }

  func testProcessParameters_superwallEvent_customParams_containsDollar() async {
    // Given
    let event = InternalSuperwallEvent.Attributes(
      appInstalledAtString: "abc",
      audienceFilterParams: [
        "$myCustomParam": "hello",
        "otherParam": true
      ]
    )
    // When
    let parameters = await TrackingLogic.processParameters(
      fromTrackableEvent: event,
      appSessionId: "abc"
    )

    XCTAssertTrue(parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(parameters.audienceFilterParams["$application_installed_at"] as! String, "abc")
    XCTAssertEqual(parameters.audienceFilterParams["$event_name"] as! String, "user_attributes")
    XCTAssertNil(parameters.audienceFilterParams["$myCustomParam"])
    XCTAssertTrue(parameters.audienceFilterParams["otherParam"] as! Bool)
    XCTAssertTrue(parameters.delegateParams["is_superwall"] as! Bool)
    XCTAssertEqual(parameters.delegateParams["application_installed_at"] as! String, "abc")
    XCTAssertNil(parameters.delegateParams["$myCustomParam"])
    XCTAssertTrue(parameters.delegateParams["otherParam"] as! Bool)
  }

  func testProcessParameters_superwallEvent_customParams_containArray() async {
    // Given
    let event = InternalSuperwallEvent.Attributes(
      appInstalledAtString: "abc",
      audienceFilterParams: [
        "myCustomParam": ["hello"],
        "otherParam": true
      ]
    )
    // When
    let parameters = await TrackingLogic.processParameters(
      fromTrackableEvent: event,
      appSessionId: "abc"
    )

    XCTAssertTrue(parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(parameters.audienceFilterParams["$application_installed_at"] as! String, "abc")
    XCTAssertEqual(parameters.audienceFilterParams["$event_name"] as! String, "user_attributes")
    XCTAssertNil(parameters.audienceFilterParams["myCustomParam"])
    XCTAssertTrue(parameters.audienceFilterParams["otherParam"] as! Bool)
    XCTAssertTrue(parameters.delegateParams["is_superwall"] as! Bool)
    XCTAssertEqual(parameters.delegateParams["application_installed_at"] as! String, "abc")
    XCTAssertNil(parameters.delegateParams["myCustomParam"])
    XCTAssertTrue(parameters.delegateParams["otherParam"] as! Bool)
  }

  func testProcessParameters_superwallEvent_customParams_containDictionary() async {
    // Given
    let event = InternalSuperwallEvent.Attributes(
      appInstalledAtString: "abc",
      audienceFilterParams: [
        "myCustomParam": ["one": "two"],
        "otherParam": true
      ]
    )
    // When
    let parameters = await TrackingLogic.processParameters(
      fromTrackableEvent: event,
      appSessionId: "abc"
    )

    XCTAssertTrue(parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(parameters.audienceFilterParams["$application_installed_at"] as! String, "abc")
    XCTAssertEqual(parameters.audienceFilterParams["$event_name"] as! String, "user_attributes")
    XCTAssertNil(parameters.audienceFilterParams["myCustomParam"])
    XCTAssertTrue(parameters.audienceFilterParams["otherParam"] as! Bool)
    XCTAssertTrue(parameters.delegateParams["is_superwall"] as! Bool)
    XCTAssertEqual(parameters.delegateParams["application_installed_at"] as! String, "abc")
    XCTAssertNil(parameters.delegateParams["myCustomParam"])
    XCTAssertTrue(parameters.delegateParams["otherParam"] as! Bool)
  }

  func testProcessParameters_superwallEvent_customParams_containsDate() async {
    // Given
    let date = Date(timeIntervalSince1970: 1650534735)
    let event = InternalSuperwallEvent.Attributes(
      appInstalledAtString: "abc",
      audienceFilterParams: [
        "myCustomParam": date,
        "otherParam": true
      ]
    )
    // When
    let parameters = await TrackingLogic.processParameters(
      fromTrackableEvent: event,
      appSessionId: "abc"
    )

    XCTAssertTrue(parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(parameters.audienceFilterParams["$application_installed_at"] as! String, "abc")
    XCTAssertEqual(parameters.audienceFilterParams["$event_name"] as! String, "user_attributes")
    XCTAssertEqual(parameters.audienceFilterParams["myCustomParam"] as! String, date.isoString)
    XCTAssertTrue(parameters.audienceFilterParams["otherParam"] as! Bool)
    XCTAssertTrue(parameters.delegateParams["is_superwall"] as! Bool)
    XCTAssertEqual(parameters.delegateParams["application_installed_at"] as! String, "abc")
    XCTAssertEqual(parameters.delegateParams["myCustomParam"] as! String, date.isoString)
    XCTAssertTrue(parameters.delegateParams["otherParam"] as! Bool)
  }

  func testProcessParameters_superwallEvent_customParams_containsUrl() async {
    // Given
    let url = URL(string: "https://www.google.com")!
    let event = InternalSuperwallEvent.Attributes(
      appInstalledAtString: "abc",
      audienceFilterParams: [
        "myCustomParam": url,
        "otherParam": true
      ]
    )
    // When
    let parameters = await TrackingLogic.processParameters(
      fromTrackableEvent: event,
      appSessionId: "abc"
    )

    XCTAssertTrue(parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(parameters.audienceFilterParams["$application_installed_at"] as! String, "abc")
    XCTAssertEqual(parameters.audienceFilterParams["$event_name"] as! String, "user_attributes")
    XCTAssertEqual(parameters.audienceFilterParams["myCustomParam"] as! String, url.absoluteString)
    XCTAssertTrue(parameters.audienceFilterParams["otherParam"] as! Bool)
    XCTAssertTrue(parameters.delegateParams["is_superwall"] as! Bool)
    XCTAssertEqual(parameters.delegateParams["application_installed_at"] as! String, "abc")
    XCTAssertEqual(parameters.delegateParams["myCustomParam"] as! String, url.absoluteString)
    XCTAssertTrue(parameters.delegateParams["otherParam"] as! Bool)
  }

  func testProcessParameters_superwallEvent_customParams_nilValue() async {
    // Given
    let event = InternalSuperwallEvent.Attributes(
      appInstalledAtString: "abc",
      audienceFilterParams: [
        "myCustomParam": nil,
        "otherParam": true
      ]
    )
    // When
    let parameters = await TrackingLogic.processParameters(
      fromTrackableEvent: event,
      appSessionId: "abc"
    )

    XCTAssertTrue(parameters.audienceFilterParams["$is_standard_event"] as! Bool)
    XCTAssertEqual(parameters.audienceFilterParams["$application_installed_at"] as! String, "abc")
    XCTAssertEqual(parameters.audienceFilterParams["$event_name"] as! String, "user_attributes")
    XCTAssertNil(parameters.audienceFilterParams["myCustomParam"])
    XCTAssertTrue(parameters.audienceFilterParams["otherParam"] as! Bool)
    XCTAssertTrue(parameters.delegateParams["is_superwall"] as! Bool)
    XCTAssertEqual(parameters.delegateParams["application_installed_at"] as! String, "abc")
    XCTAssertNil(parameters.delegateParams["myCustomParam"])
    XCTAssertTrue(parameters.delegateParams["otherParam"] as! Bool)
  }

  // MARK: - didStartNewSession

  @MainActor
  func testDidStartNewSession_canTriggerPaywall_paywallAlreadyPresented() {
    let dependencyContainer = DependencyContainer()

    let messageHandler = PaywallMessageHandler(
      sessionEventsManager: dependencyContainer.sessionEventsManager,
      factory: dependencyContainer
    )
    let webView = SWWebView(
      isMac: false,
      messageHandler: messageHandler,
      isOnDeviceCacheEnabled: true,
      factory: dependencyContainer
    )
    let paywallVc = PaywallViewControllerMock(
      paywall: .stub(),
      deviceHelper: dependencyContainer.deviceHelper,
      factory: dependencyContainer,
      storage: dependencyContainer.storage,
      webView: webView,
      cache: nil,
      paywallArchiveManager: nil
    )

    let outcome = TrackingLogic.canTriggerPaywall(
      InternalSuperwallEvent.AppInstall(appInstalledAtString: "", hasExternalPurchaseController: false),
      triggers: Set(["app_install"]),
      paywallViewController: paywallVc
    )
    XCTAssertEqual(outcome, .dontTriggerPaywall)
  }

  func testDidStartNewSession_canTriggerPaywall_isntTrigger() {
    let outcome = TrackingLogic.canTriggerPaywall(
      InternalSuperwallEvent.AppInstall(appInstalledAtString: "", hasExternalPurchaseController: false),
      triggers: [],
      paywallViewController: nil
    )
    XCTAssertEqual(outcome, .dontTriggerPaywall)
  }

  func testDidStartNewSession_canTriggerPaywall_isAllowedInternalEvent() {
    let outcome = TrackingLogic.canTriggerPaywall(
      InternalSuperwallEvent.AppInstall(appInstalledAtString: "", hasExternalPurchaseController: false),
      triggers: ["app_install"],
      paywallViewController: nil
    )
    XCTAssertEqual(outcome, .triggerPaywall)
  }

  func testDidStartNewSession_canTriggerPaywall_isNotInternalEvent() {
    let outcome = TrackingLogic.canTriggerPaywall(
      UserInitiatedEvent.Track(rawName: "random_event", canImplicitlyTriggerPaywall: true, isFeatureGatable: false),
      triggers: ["random_event"],
      paywallViewController: nil
    )
    XCTAssertEqual(outcome, .triggerPaywall)
  }

  // MARK: - CheckNotSuperwallEvent

  func test_checkNotSuperwallEvent_isSuperwallEvent() {
    do {
      try TrackingLogic.checkNotSuperwallEvent("paywall_open")
      XCTFail("Should have failed")
    } catch {}
  }

  func test_checkNotSuperwallEvent_isNotSuperwallEvent() {
    do {
      try TrackingLogic.checkNotSuperwallEvent("my_random_event")
    } catch {
      XCTFail("Should have failed")
    }
  }

  // MARK: - isNotDisabledVerboseEvent
  
  // This happens when config is null
  func test_isNotDisabledVerboseEvent_nullVerboseEvents() {
    let event = InternalSuperwallEvent.SessionStart()
    let result = TrackingLogic.isNotDisabledVerboseEvent(
      event,
      disableVerboseEvents: nil,
      isSandbox: true
    )
    XCTAssertTrue(result)
  }

  func test_isNotDisabledVerboseEvent_isSandbox_disabledEvents() {
    let event = InternalSuperwallEvent.SessionStart()
    let result = TrackingLogic.isNotDisabledVerboseEvent(
      event,
      disableVerboseEvents: true,
      isSandbox: true
    )
    XCTAssertTrue(result)
  }

  func test_isNotDisabledVerboseEvent_isNotSandbox_noDisabledEvents_presentationReq() {
    let event = InternalSuperwallEvent.PresentationRequest(eventData: .stub(), type: .presentation, status: .presentation, statusReason: nil, factory: DependencyContainer())
    let result = TrackingLogic.isNotDisabledVerboseEvent(
      event,
      disableVerboseEvents: false,
      isSandbox: false
    )
    XCTAssertTrue(result)
  }

  func test_isNotDisabledVerboseEvent_isNotSandbox_disabledEvents_presentationReq() {
    let event = InternalSuperwallEvent.PresentationRequest(eventData: .stub(), type: .presentation, status: .presentation, statusReason: nil, factory: DependencyContainer())
    let result = TrackingLogic.isNotDisabledVerboseEvent(
      event,
      disableVerboseEvents: true,
      isSandbox: false
    )
    XCTAssertFalse(result)
  }

  func test_isNotDisabledVerboseEvent_isNotSandbox_disabledEvents_paywallLoadStart() {
    let event = InternalSuperwallEvent.PaywallLoad(state: .start, eventData: nil)
    let result = TrackingLogic.isNotDisabledVerboseEvent(
      event,
      disableVerboseEvents: true,
      isSandbox: false
    )
    XCTAssertFalse(result)
  }

  func test_isNotDisabledVerboseEvent_isNotSandbox_noDisabledEvents_paywallLoadStart() {
    let event = InternalSuperwallEvent.PaywallLoad(state: .start, eventData: nil)
    let result = TrackingLogic.isNotDisabledVerboseEvent(
      event,
      disableVerboseEvents: false,
      isSandbox: false
    )
    XCTAssertTrue(result)
  }


  func test_isNotDisabledVerboseEvent_isNotSandbox_disabledEvents_paywallLoadComplete() {
    let event = InternalSuperwallEvent.PaywallLoad(state: .complete(paywallInfo: .stub()), eventData: nil)
    let result = TrackingLogic.isNotDisabledVerboseEvent(
      event,
      disableVerboseEvents: true,
      isSandbox: false
    )
    XCTAssertFalse(result)
  }

  func test_isNotDisabledVerboseEvent_isNotSandbox_noDisabledEvents_paywallLoadComplete() {
    let event = InternalSuperwallEvent.PaywallLoad(state: .complete(paywallInfo: .stub()), eventData: nil)
    let result = TrackingLogic.isNotDisabledVerboseEvent(
      event,
      disableVerboseEvents: false,
      isSandbox: false
    )
    XCTAssertTrue(result)
  }

  func test_isNotDisabledVerboseEvent_isNotSandbox_disabledEvents_productsLoadStart() {
    let event = InternalSuperwallEvent.PaywallProductsLoad(state: .start, paywallInfo: .stub(), eventData: nil)
    let result = TrackingLogic.isNotDisabledVerboseEvent(
      event,
      disableVerboseEvents: true,
      isSandbox: false
    )
    XCTAssertFalse(result)
  }

  func test_isNotDisabledVerboseEvent_isNotSandbox_noDisabledEvents_productsLoadStart() {
    let event = InternalSuperwallEvent.PaywallLoad(state: .complete(paywallInfo: .stub()), eventData: nil)
    let result = TrackingLogic.isNotDisabledVerboseEvent(
      event,
      disableVerboseEvents: false,
      isSandbox: false
    )
    XCTAssertTrue(result)
  }

  func test_isNotDisabledVerboseEvent_isNotSandbox_disabledEvents_webviewLoadStart() {
    let event = InternalSuperwallEvent.PaywallWebviewLoad(state: .start, paywallInfo: .stub())
    let result = TrackingLogic.isNotDisabledVerboseEvent(
      event,
      disableVerboseEvents: true,
      isSandbox: false
    )
    XCTAssertFalse(result)
  }

  func test_isNotDisabledVerboseEvent_isNotSandbox_noDisabledEvents_webviewLoadStart() {
    let event = InternalSuperwallEvent.PaywallLoad(state: .complete(paywallInfo: .stub()), eventData: nil)
    let result = TrackingLogic.isNotDisabledVerboseEvent(
      event,
      disableVerboseEvents: false,
      isSandbox: false
    )
    XCTAssertTrue(result)
  }

  func test_isNotDisabledVerboseEvent_isNotSandbox_noDisabledEvents_sessionStart() {
    let event = InternalSuperwallEvent.SessionStart()
    let result = TrackingLogic.isNotDisabledVerboseEvent(
      event,
      disableVerboseEvents: false,
      isSandbox: false
    )
    XCTAssertTrue(result)
  }

  func test_isNotDisabledVerboseEvent_isNotSandbox_disabledEvents_sessionStart() {
    let event = InternalSuperwallEvent.SessionStart()
    let result = TrackingLogic.isNotDisabledVerboseEvent(
      event,
      disableVerboseEvents: true,
      isSandbox: false
    )
    XCTAssertTrue(result)
  }
}
