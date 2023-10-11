//
//  File.swift
//  
//
//  Created by Yusuf Tör on 04/05/2022.
//

import UIKit
import Combine

protocol AppManagerDelegate: AnyObject {
  func didUpdateAppSession(_ appSession: AppSession) async
}

class AppSessionManager {
  var appSessionTimeout: Milliseconds?

  private(set) var appSession = AppSession() {
    didSet {
      Task {
        await delegate.didUpdateAppSession(appSession)
      }
    }
  }
  private var lastAppClose: Date?
  private var didTrackAppLaunch = false
  private var cancellable: AnyCancellable?

  private unowned let configManager: ConfigManager
  private unowned let storage: Storage
  private unowned let delegate: AppManagerDelegate & DeviceHelperFactory

  init(
    configManager: ConfigManager,
    storage: Storage,
    delegate: DeviceHelperFactory & AppManagerDelegate
  ) {
    self.configManager = configManager
    self.storage = storage
    self.delegate = delegate
    Task {
      await addActiveStateObservers()
    }
    listenForAppSessionTimeout()
  }

  // MARK: - Listeners
  @MainActor
  private func addActiveStateObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationWillResignActive),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationWillTerminate),
      name: UIApplication.willTerminateNotification,
      object: nil
    )
  }

  func listenForAppSessionTimeout() {
    cancellable = configManager.configState
      .compactMap { $0.getConfig() }
      .sink(
        receiveCompletion: { _ in },
        receiveValue: { [weak self] config in
          guard let self = self else {
            return
          }
          self.appSessionTimeout = config.appSessionTimeout

          // Account for the fact that dev may have delayed the init of Superwall
          // such that applicationDidBecomeActive() doesn't activate.
          if !self.didTrackAppLaunch {
            self.sessionCouldRefresh()
          }
        }
      )
  }

  @objc private func applicationWillResignActive() {
    storage.recordFirstSessionTracked()
    Task {
      await Superwall.shared.track(InternalSuperwallEvent.AppClose())
    }
    lastAppClose = Date()
    appSession.endAt = Date()
  }

  @objc private func applicationWillTerminate() {
    appSession.endAt = Date()
  }

  @objc private func applicationDidBecomeActive() {
    Task {
      await Superwall.shared.track(InternalSuperwallEvent.AppOpen())
    }
    sessionCouldRefresh()
  }

  // MARK: - Logic

  /// Tries to track a new app session, app launch, and first seen.
  private func sessionCouldRefresh() {
    detectNewSession()
    trackAppLaunch()
    storage.recordFirstSeenTracked()
  }

  private func detectNewSession() {
    let didStartNewSession = AppSessionLogic.didStartNewSession(
      lastAppClose,
      withSessionTimeout: appSessionTimeout
    )

    if didStartNewSession {
      appSession = AppSession()
      Task {
        let attributes = await delegate.makeSessionDeviceAttributes()
        await Superwall.shared.track(InternalSuperwallEvent.SessionStart())
        await Superwall.shared.track(InternalSuperwallEvent.DeviceAttributes(
          deviceAttributes: attributes
        ))
      }
    } else {
      appSession.endAt = nil
    }
  }

  private func trackAppLaunch() {
    if didTrackAppLaunch {
      return
    }
    Task {
      await Superwall.shared.track(InternalSuperwallEvent.AppLaunch())
    }
    didTrackAppLaunch = true
  }
}
