//
//  File.swift
//  
//
//  Created by Yusuf Tör on 16/09/2022.
//

// ********************** How to use this class **********************
//
// For variables and functions that could have race conditions, a private
// variable/function is created with an underscore. Access to this is
// synchronised via a dispatch queue. When writing, use queue.async, when
// reading use a computed var with a queue.sync block. You do not need to
// use the queue during init.
// A Dispatch Group is used when calling functions that will call didSetIdentity.
// This is to prevent the case where identitySubject sends a true value before
// all functions affecting the identity have finished.
//
// *******************************************************************

import Foundation
import Combine

class IdentityManager {
  /// The appUserId or the aliasId, depending on whether the user is logged in
  /// or not.
  var userId: String {
    return queue.sync {
      _appUserId ?? _aliasId
    }
  }

  /// The userId passed to the SDK.
  var appUserId: String? {
    queue.sync {
      _appUserId
    }
  }
  private var _appUserId: String? {
    didSet {
      saveIds()
    }
  }

  /// User attributes that belong to the user.
  var userAttributes: [String: Any] {
    queue.sync {
      _userAttributes
    }
  }
  private var _userAttributes: [String: Any] = [:]

  /// The randomly generated aliasId used to identify an anonymous user.
  var aliasId: String {
    queue.sync {
      _aliasId
    }
  }
  private var _aliasId: String {
    didSet {
      saveIds()
    }
  }

  /// The randomly generated seed used to put users into cohorts.
  var seed: Int {
    queue.sync {
      _seed
    }
  }
  private var _seed: Int {
    didSet {
      saveIds()
    }
  }

  /// Indicates whether the user has logged in or not.
  var isLoggedIn: Bool {
    return appUserId != nil
  }

  /// A Publisher that only emits when `identitySubject` is `true`. When `true`,
  /// it means the SDK is ready to fire triggers.
  var hasIdentity: AnyPublisher<Bool, Error> {
    identitySubject
      .filter { $0 == true }
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
  }

  /// Indicates whether the identity (i.e. anonymous or logged in with
  /// assignments) has been retrieved.
  ///
  /// When `false`, the SDK is unable to present paywalls.
  let identitySubject = CurrentValueSubject<Bool, Never>(false)
  private let queue = DispatchQueue(label: "com.superwall.identitymanager")
  private let group = DispatchGroup()

  private var deviceHelper: DeviceHelper {
    return factory.deviceHelper
  }

  private var storage: Storage {
    return factory.storage
  }

  private var configManager: ConfigManager {
    return factory.configManager
  }

  private let factory: DependencyContainer

  init(factory: DependencyContainer) {
    self.factory = factory

    let storage = factory.storage
    self._appUserId = storage.get(AppUserId.self)

    var extraAttributes: [String: Any] = [:]

    if let aliasId = storage.get(AliasId.self) {
      self._aliasId = aliasId
    } else {
      self._aliasId = IdentityLogic.generateAlias()
      storage.save(_aliasId, forType: AliasId.self)
      extraAttributes["aliasId"] = self._aliasId
    }

    if let seed = storage.get(Seed.self) {
      self._seed = seed
    } else {
      self._seed = IdentityLogic.generateSeed()
      storage.save(_seed, forType: Seed.self)
      extraAttributes["seed"] = self._seed
    }
    self._userAttributes = storage.get(UserAttributes.self) ?? [:]

    if !extraAttributes.isEmpty {
      mergeUserAttributes(extraAttributes, shouldTrackMerge: false)
    }
  }

  /// Checks for static config upgrade before setting identity.
  func configure() async {
    group.enter()
    let neverCalledStaticConfig = storage.neverCalledStaticConfig
    let isFirstAppOpen = !(storage.get(DidTrackFirstSeen.self) ?? false)

    if IdentityLogic.shouldGetAssignments(
      isLoggedIn: isLoggedIn,
      neverCalledStaticConfig: neverCalledStaticConfig,
      isFirstAppOpen: isFirstAppOpen
    ) {
      try? await configManager.getAssignments()
    }

    group.leave()

    didSetIdentity()
  }

  /// Creates an account and may or may not wait for assignments before
  /// returning.
  func identify(
    userId: String,
    options: IdentityOptions?
  ) {
    guard let userId = IdentityLogic.sanitize(userId: userId) else {
      Logger.debug(
        logLevel: .error,
        scope: .identityManager,
        message: "The provided userId was empty."
      )
      return
    }

    group.enter()

    queue.async { [weak self] in
      guard let self = self else {
        return
      }
      // If they're sending the same userId as before, then they're
      // already logged in.
      if self._appUserId == userId {
        self.group.leave()
        return
      }

      self.identitySubject.send(false)

      let oldUserId = self._appUserId

      // If user already logged in but identifying with a
      // different userId, reset everything first.
      if oldUserId != nil,
        userId != oldUserId {
        Superwall.shared.reset(duringIdentify: true)
      }

      self._appUserId = userId

      // Regenerate seed based on userId.
      self.group.enter()
      Task {
        let config = try? await self.configManager.configState
          .compactMap { $0.getConfig() }
          .throwableAsync()

        if config?.featureFlags.enableUserIdSeed == true,
          let seed = userId.sha256MappedToRange() {
          self._seed = seed
        }
        self.group.leave()
      }

      func getAssignmentsAsync() {
        Task.detached {
          try? await self.configManager.getAssignments()
        }
        self.group.leave()
        self.didSetIdentity()
      }

      // If they have set restore paywall assignments to true,
      // Wait for assignments before setting identity. Otherwise,
      // get assignments in the background.

      if let options = options {
        if options.restorePaywallAssignments {
          Task {
            try? await self.configManager.getAssignments()
            self.group.leave()
            self.didSetIdentity()
          }
        } else {
          getAssignmentsAsync()
        }
      } else {
        getAssignmentsAsync()
      }
    }
  }

  /// Sends a `true` value to the `identitySubject` in order to fire
  /// triggers after reset.
  func didSetIdentity() {
    group.notify(queue: .main) { [weak self] in
      self?.identitySubject.send(true)
    }
  }

  /// Saves the aliasId and appUserId to storage and user attributes.
  private func saveIds() {
    // This is not wrapped in an async block because is
    // called from the didSet of vars, who are already
    // being set within the queue.
    if let appUserId = _appUserId {
      storage.save(appUserId, forType: AppUserId.self)
    }

    // Save incase these have also changed.
    storage.save(_aliasId, forType: AliasId.self)
    storage.save(_seed, forType: Seed.self)

    var newUserAttributes: [String: Any] = [
      "aliasId": _aliasId,
      "seed": _seed
    ]
    if let appUserId = _appUserId {
      newUserAttributes["appUserId"] = appUserId
    }

    mergeUserAttributes(newUserAttributes)
  }
}

// MARK: - Reset
extension IdentityManager {
  /// Clears all stored user-specific variables.
  ///
  /// - Parameters:
  ///   - duringIdentify: A boolean that indicates whether the reset
  ///   call is happening during a call to `identify(userId:)`. If `false`,
  ///   this happens
  func reset(duringIdentify: Bool) {
    identitySubject.send(false)

    if duringIdentify {
      self._reset()
    } else {
      group.enter()
      queue.async { [weak self] in
        self?._reset()
        self?.group.leave()
        self?.didSetIdentity()
      }
    }
  }

  /// Resets user values
  private func _reset() {
    _appUserId = nil
    _aliasId = IdentityLogic.generateAlias()
    _seed = IdentityLogic.generateSeed()
    _userAttributes = [:]
  }
}

// MARK: - User Attributes
extension IdentityManager {
  /// Merges the attributes on an async queue
  func mergeUserAttributes(
    _ newUserAttributes: [String: Any?],
    shouldTrackMerge: Bool = true
  ) {
    queue.async { [weak self] in
      self?._mergeUserAttributes(
        newUserAttributes,
        shouldTrackMerge: shouldTrackMerge
      )
    }
  }

  /// Merges the provided user attributes with existing attributes then saves them.
  ///
  /// - Parameter shouldTrackMerge: A boolean indicated whether the merge should be tracked in analytics.
  private func _mergeUserAttributes(
    _ newUserAttributes: [String: Any?],
    shouldTrackMerge: Bool = true
  ) {
    let mergedAttributes = IdentityLogic.mergeAttributes(
      newUserAttributes,
      with: _userAttributes,
      appInstalledAtString: deviceHelper.appInstalledAtString
    )

    if shouldTrackMerge {
      Task {
        let trackableEvent = InternalSuperwallEvent.Attributes(
          appInstalledAtString: deviceHelper.appInstalledAtString,
          customParameters: mergedAttributes
        )
        await Superwall.shared.track(trackableEvent)
      }
    }

    storage.save(mergedAttributes, forType: UserAttributes.self)
    _userAttributes = mergedAttributes
  }
}
