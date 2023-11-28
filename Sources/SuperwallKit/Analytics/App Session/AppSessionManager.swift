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

  private var configManager: ConfigManager {
    return factory.configManager
  }

  private var storage: Storage {
    return factory.storage
  }
  
  private var delegate: AppManagerDelegate & DeviceHelperFactory & UserAttributesEventFactory {
    return factory
  }

  let factory: DependencyContainer

  init(factory: DependencyContainer) {
    self.factory = factory

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
        let deviceAttributes = await delegate.makeSessionDeviceAttributes()
        let userAttributes = delegate.makeUserAttributesEvent()

        await withTaskGroup(of: Void.self) { group in
          group.addTask {
            await Superwall.shared.track(InternalSuperwallEvent.SessionStart())
          }
          group.addTask {
            await Superwall.shared.track(
              InternalSuperwallEvent.DeviceAttributes(deviceAttributes: deviceAttributes)
            )
          }
          group.addTask {
            await Superwall.shared.track(userAttributes)
          }
        }
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
