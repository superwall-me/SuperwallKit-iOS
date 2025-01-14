//
//  ModelLoader.swift
//  Superwall
//
//  Created by Yusuf Tör on 04/03/2022.
//
// swiftlint:disable type_body_length

import Foundation
import UIKit
import Combine

class Network {
  private let urlSession: CustomURLSession
  private let factory: ApiFactory
  private let options: SuperwallOptions
  private var applicationStateSubject: CurrentValueSubject<UIApplication.State, Never> = .init(.background)

  init(
    urlSession: CustomURLSession? = nil,
    options: SuperwallOptions,
    factory: ApiFactory
  ) {
    self.options = options
    self.urlSession = urlSession ?? CustomURLSession(factory: factory)
    self.factory = factory

    Task { @MainActor [weak self] in
      self?.applicationStateDidChange()
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationStateDidChange),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationStateDidChange),
      name: UIApplication.didEnterBackgroundNotification,
      object: nil
    )
  }

  @objc
  @MainActor
  private func applicationStateDidChange() {
    applicationStateSubject.send(UIApplication.shared.applicationState)
  }

  func sendEvents(events: EventsRequest) async {
    do {
      let result = try await urlSession.request(
        .events(eventsRequest: events),
        data: SuperwallRequestData(factory: factory)
      )
      switch result.status {
      case .ok:
        break
      case .partialSuccess:
        Logger.debug(
          logLevel: .warn,
          scope: .network,
          message: "Request had partial success: /events",
          info: ["payload": result.invalidIndexes as Any]
        )
      }
    } catch {
      Logger.debug(
        logLevel: .error,
        scope: .network,
        message: "Request Failed: /events",
        info: ["payload": events],
        error: error
      )
    }
  }

  func getPaywall(
    withId identifier: String? = nil,
    fromPlacement placement: PlacementData? = nil,
    retryCount: Int
  ) async throws -> Paywall {
    do {
      return try await urlSession.request(
        .paywall(
          withIdentifier: identifier,
          fromPlacement: placement,
          retryCount: retryCount,
          appUserId: factory.identityManager.userId,
          apiKey: factory.storage.apiKey,
          config: factory.configManager.config,
          locale: factory.deviceHelper.locale
        ),
        data: SuperwallRequestData(factory: factory)
      )
    } catch {
      if identifier == nil {
        Logger.debug(
          logLevel: .error,
          scope: .network,
          message: "Request Failed: /paywall",
          info: [
            "identifier": identifier ?? "none",
            "event": placement.debugDescription
          ],
          error: error
        )
      } else {
        Logger.debug(
          logLevel: .error,
          scope: .network,
          message: "Request Failed: /paywall/:identifier",
          error: error
        )
      }
      throw error
    }
  }

  func getPaywalls() async throws -> [Paywall] {
    do {
      let response = try await urlSession.request(
        .paywalls(),
        data: SuperwallRequestData(
          factory: factory,
          isForDebugging: true
        )
      )
      return response.paywalls
    } catch {
      Logger.debug(
        logLevel: .error,
        scope: .network,
        message: "Request Failed: /paywalls",
        error: error
      )
      throw error
    }
  }

  func getConfig(
    injectedApplicationStatePublisher: (AnyPublisher<UIApplication.State, Never>)? = nil,
    maxRetry: Int? = nil,
    isRetryingCallback: ((Int) -> Void)? = nil
  ) async throws -> Config {
    try await appInForeground(injectedApplicationStatePublisher)

    do {
      let requestId = UUID().uuidString
      var config = try await urlSession.request(
        .config(
          maxRetry: maxRetry ?? options.maxConfigRetryCount,
          apiKey: factory.storage.apiKey
        ),
        data: SuperwallRequestData(
          factory: factory,
          requestId: requestId
        ),
        isRetryingCallback: isRetryingCallback
      )
      config.requestId = requestId
      return config
    } catch {
      Logger.debug(
        logLevel: .error,
        scope: .network,
        message: "Request Failed: /static_config",
        error: error
      )
      throw error
    }
  }

  @MainActor
  private func appInForeground(
    _ injectedApplicationStatePublisher: (AnyPublisher<UIApplication.State, Never>)? = nil
  ) async throws {
    let existingApplicationStatePublisher = self.applicationStateSubject.eraseToAnyPublisher()
    let applicationStatePublisher = injectedApplicationStatePublisher ?? existingApplicationStatePublisher

    // Suspend until app is in foreground.
    try await applicationStatePublisher
      .subscribe(on: DispatchQueue.main)
      .filter { $0 != .background }
      .throwableAsync()
  }

  func getGeoInfo(
    injectedApplicationStatePublisher: (AnyPublisher<UIApplication.State, Never>)? = nil,
    maxRetry: Int?
  ) async throws -> GeoInfo? {
    do {
      try await appInForeground(injectedApplicationStatePublisher)
      let geoWrapper = try await urlSession.request(
        .geo(maxRetry: maxRetry ?? options.maxConfigRetryCount),
        data: SuperwallRequestData(factory: factory)
      )
      return geoWrapper.info
    } catch {
      Logger.debug(
        logLevel: .error,
        scope: .network,
        message: "Request Failed: /geo",
        error: error
      )
      throw error
    }
  }

  func confirmAssignments(_ confirmableAssignments: AssignmentPostback) async {
    do {
      try await urlSession.request(
        .confirmAssignments(confirmableAssignments),
        data: SuperwallRequestData(factory: factory)
      )
    } catch {
      Logger.debug(
        logLevel: .error,
        scope: .network,
        message: "Request Failed: /confirm_assignments",
        info: ["assignments": confirmableAssignments],
        error: error
      )
    }
  }

  func getAssignments() async throws -> [Assignment] {
    do {
      let result = try await urlSession.request(
        .assignments(),
        data: SuperwallRequestData(factory: factory)
      )
      return result.assignments
    } catch {
      Logger.debug(
        logLevel: .error,
        scope: .network,
        message: "Request Failed: /assignments",
        error: error
      )
      throw error
    }
  }

  func sendSessionEvents(_ session: SessionEventsRequest) async {
    do {
      let result = try await urlSession.request(
        .sessionEvents(session),
        data: SuperwallRequestData(factory: factory)
      )
      switch result.status {
      case .ok:
        break
      case .partialSuccess:
        Logger.debug(
          logLevel: .warn,
          scope: .network,
          message: "Request had partial success: /session_events",
          info: ["payload": result.invalidIndexes as Any]
        )
      }
    } catch {
      Logger.debug(
        logLevel: .error,
        scope: .network,
        message: "Request Failed: /session_events",
        info: ["payload": session],
        error: error
      )
    }
  }

  func sendToken(_ token: String) async -> [String: Any] {
    do {
      let jsonDict = try await urlSession.request(
        .adServices(token: token),
        data: SuperwallRequestData(factory: factory)
      ).attribution
      return convertJSONToDictionary(attribution: jsonDict)
    } catch {
      Logger.debug(
        logLevel: .error,
        scope: .network,
        message: "Request Failed: /apple-ad-services/token",
        info: ["payload": token],
        error: error
      )
      return [:]
    }
  }
}
