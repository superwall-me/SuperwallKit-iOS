//
//  CacheManager.swift
//  
//
//  Created by Brian Anglin on 8/3/21.
//

import Foundation

class Storage {
  /// The interface that manages core data.
  let coreDataManager: CoreDataManager

  /// The API key, set on configure.
  var apiKey = ""

  /// The API key for debugging, set when handling a deep link.
  var debugKey = ""

  /// Indicates whether first seen has been tracked.
  var didTrackFirstSeen: Bool {
    get {
      queue.sync {
        _didTrackFirstSeen
      }
    }
    set {
      queue.async { [weak self] in
        self?.didTrackFirstSeen = newValue
      }
    }
  }
  private var _didTrackFirstSeen = false

  /// Indicates whether first seen has been tracked.
  var didTrackFirstSession: Bool {
    get {
      queue.sync {
        _didTrackFirstSession
      }
    }
    set {
      queue.async { [weak self] in
        self?.didTrackFirstSession = newValue
      }
    }
  }
  private var _didTrackFirstSession = false

  /// Indicates whether static config hasn't been called before.
  ///
  /// Users upgrading from older SDK versions will not have called static config.
  /// This means that we'll need to wait for assignments before firing triggers.
  var neverCalledStaticConfig = false

  /// The confirmed assignments for the user loaded from the cache.
  private var confirmedAssignments: [Experiment.ID: Experiment.Variant]? {
    get {
      queue.sync {
        self._confirmedAssignments
      }
    }
    set {
      queue.async { [weak self] in
        self?._confirmedAssignments = newValue
      }
    }
  }
  private var _confirmedAssignments: [Experiment.ID: Experiment.Variant]?

  private let queue = DispatchQueue(label: "com.superwall.storage")

  /// The disk cache.
  private let cache: Cache

  private unowned let factory: DeviceHelperFactory & HasExternalPurchaseControllerFactory

  // MARK: - Configuration

  init(
    factory: DeviceHelperFactory & HasExternalPurchaseControllerFactory,
    cache: Cache = Cache(),
    coreDataManager: CoreDataManager = CoreDataManager()
  ) {
    self.cache = cache
    self.coreDataManager = coreDataManager
    self._didTrackFirstSeen = cache.read(DidTrackFirstSeen.self) == true

    // If we've already tracked firstSeen, then it can't be the first session. Useful for those upgrading.
    if _didTrackFirstSeen {
      self._didTrackFirstSession = true
    } else {
      self._didTrackFirstSession = cache.read(DidTrackFirstSession.self) == true
    }
    self.factory = factory
  }

  func configure(apiKey: String) {
    migrateData()
    updateSdkVersion()
    self.apiKey = apiKey
  }

  private func migrateData() {
    let version = cache.read(Version.self) ?? .v1
    FileManagerMigrator.migrate(
      fromVersion: version,
      cache: cache
    )
  }

  /// Checks to see whether a user has upgraded from normal to static config.
  /// This blocks triggers until assignments is returned.
  private func updateSdkVersion() {
    let actualSdkVersion = sdkVersion
    let previousSdkVersion = cache.read(SdkVersion.self)

    if actualSdkVersion != previousSdkVersion {
      save(actualSdkVersion, forType: SdkVersion.self)
    }

    if previousSdkVersion == nil {
      neverCalledStaticConfig = true
    }
  }

  /// Clears data that is user specific.
  func reset() {
    coreDataManager.deleteAllEntities()
    cache.cleanUserFiles()

    queue.async { [weak self] in
      self?._confirmedAssignments = nil
      self?._didTrackFirstSeen = false
    }

    recordFirstSeenTracked()
  }

  // MARK: - Custom
  /// Tracks and stores first seen for the user.
	func recordFirstSeenTracked() {
    queue.async {
      if self._didTrackFirstSeen {
        return
      }

      Task {
        await Superwall.shared.track(InternalSuperwallPlacement.FirstSeen())
      }
      self.save(true, forType: DidTrackFirstSeen.self)
      self._didTrackFirstSeen = true
    }
	}

  func recordFirstSessionTracked() {
    queue.async {
      if self._didTrackFirstSession {
        return
      }

      self.save(true, forType: DidTrackFirstSession.self)
      self._didTrackFirstSession = true
    }
  }

  /// Records the app install
  func recordAppInstall(
  trackPlacement: @escaping (Trackable) async -> TrackingResult
  ) {
    let didTrackAppInstall = get(DidTrackAppInstall.self) ?? false
    if didTrackAppInstall {
      return
    }

    let hasExternalPurchaseController = factory.makeHasExternalPurchaseController()
    let deviceInfo = factory.makeDeviceInfo()

    Task {
      let appInstall = InternalSuperwallPlacement.AppInstall(
        appInstalledAtString: deviceInfo.appInstalledAtString,
        hasExternalPurchaseController: hasExternalPurchaseController
      )
      _ = await trackPlacement(appInstall)
    }
    save(true, forType: DidTrackAppInstall.self)
  }

  func clearCachedSessionEvents() {
    cache.delete(Transactions.self)
  }

  func trackPaywallOpen() {
    let totalPaywallViews = get(TotalPaywallViews.self) ?? 0
    save(totalPaywallViews + 1, forType: TotalPaywallViews.self)
    save(Date(), forType: LastPaywallView.self)
  }

  func saveConfirmedAssignments(_ assignments: [Experiment.ID: Experiment.Variant]) {
    save(assignments, forType: ConfirmedAssignments.self)
    confirmedAssignments = assignments
  }

  func getConfirmedAssignments() -> [Experiment.ID: Experiment.Variant] {
    if let confirmedAssignments = confirmedAssignments {
      return confirmedAssignments
    } else {
      let assignments = get(ConfirmedAssignments.self) ?? [:]
      confirmedAssignments = assignments
      return assignments
    }
  }

// MARK: - Cache Reading & Writing
  func get<Key: Storable>(_ keyType: Key.Type) -> Key.Value? {
    return cache.read(keyType)
  }

  func get<Key: Storable>(_ keyType: Key.Type) -> Key.Value? where Key.Value: Decodable {
    return cache.read(keyType)
  }

  func save<Key: Storable>(_ value: Key.Value, forType keyType: Key.Type) {
    return cache.write(value, forType: keyType)
  }

  func save<Key: Storable>(_ value: Key.Value, forType keyType: Key.Type) where Key.Value: Encodable {
    return cache.write(value, forType: keyType)
  }

  func delete<Key: Storable>(_ keyType: Key.Type) {
    return cache.delete(keyType)
  }

  func save<Key: Storable>(_ keyType: Key.Type) where Key.Value: Encodable {
    return cache.delete(keyType)
  }
}
