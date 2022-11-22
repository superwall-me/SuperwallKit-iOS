//
//  File.swift
//  
//
//  Created by Yusuf Tör on 23/05/2022.
//
// swiftlint:disable all

import Foundation
@testable import SuperwallKit

@available(iOS 14.0, *)
final class StorageMock: Storage {
  var internalCachedTriggerSessions: [TriggerSession]
  var internalCachedTransactions: [TransactionModel]
  var internalConfirmedAssignments: [Experiment.ID: Experiment.Variant]
  var didClearCachedSessionEvents = false

  init(
    internalCachedTriggerSessions: [TriggerSession] = [],
    internalCachedTransactions: [TransactionModel] = [],
    coreDataManager: CoreDataManagerFakeDataMock = CoreDataManagerFakeDataMock(),
    confirmedAssignments: [Experiment.ID : Experiment.Variant] = [:],
    cache: Cache = Cache()
  ) {
    self.internalCachedTriggerSessions = internalCachedTriggerSessions
    self.internalCachedTransactions = internalCachedTransactions
    self.internalConfirmedAssignments = confirmedAssignments

    super.init(cache: cache, coreDataManager: coreDataManager)
  }

  override func get<Key>(_ keyType: Key.Type) -> Key.Value? where Key : Storable {
    if keyType == TriggerSessions.self {
      return internalCachedTriggerSessions as? Key.Value
    } else if keyType == Transactions.self {
      return internalCachedTransactions as? Key.Value
    }
    return nil
  }

  override func get<Key>(_ keyType: Key.Type) -> Key.Value? where Key : Storable, Key.Value : Decodable {
    if keyType == TriggerSessions.self {
      return internalCachedTriggerSessions as? Key.Value
    } else if keyType == Transactions.self {
      return internalCachedTransactions as? Key.Value
    }
    return nil
  }

  override func clearCachedSessionEvents() {
    didClearCachedSessionEvents = true
  }

  override func getConfirmedAssignments() -> [Experiment.ID: Experiment.Variant] {
    return internalConfirmedAssignments
  }

  override func saveConfirmedAssignments(_ assignments: [String : Experiment.Variant]) {
    internalConfirmedAssignments = assignments
  }
}