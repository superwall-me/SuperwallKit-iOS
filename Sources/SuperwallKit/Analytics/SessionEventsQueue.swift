//
//  File.swift
//  
//
//  Created by Yusuf Tör on 06/05/2022.
//

import UIKit
import Combine

/// A protocol that defines the internal methods for `SessionEventsQueue`.
///
/// This is used to be able to inject a mock version for testing.
protocol SessionEnqueuable: Actor {
  var triggerSessions: [TriggerSession] { get set }
  var transactions: [StoreTransaction] { get }

  func enqueue(_ triggerSession: TriggerSession)
  func enqueue(_ triggerSessions: [TriggerSession])
  func enqueue(_ transaction: StoreTransaction)
  func removeAllTriggerSessions()
  func flushInternal(depth: Int)
  func saveCacheToDisk()
}

extension SessionEnqueuable {
  /// Used for testing purposes only
  func removeAllTriggerSessions() {}
}

/// Sends n analytical events to the Superwall servers every 20 seconds, where n is defined by `maxEventCount`.
///
/// **Note**: this currently has a limit of 500 events per flush.
actor SessionEventsQueue: SessionEnqueuable {
  private let maxEventCount = 50
  var triggerSessions: [TriggerSession] = []
  var transactions: [StoreTransaction] = []
  private var timer: Timer?
  @MainActor
  private var willResignActiveObserver: AnyCancellable?
  private lazy var lastTwentySessions = LimitedQueue<TriggerSession>(limit: 20)
  private lazy var lastTwentyTransactions = LimitedQueue<StoreTransaction>(limit: 20)
  private let storage: Storage
  private let network: Network
  private let configManager: ConfigManager

  deinit {
    timer?.invalidate()
    timer = nil
  }

  init(
    storage: Storage,
    network: Network,
    configManager: ConfigManager
  ) {
    self.storage = storage
    self.network = network
    self.configManager = configManager
    Task {
      await setupTimer()
      await addObserver()
    }
  }

  private func setupTimer() {
    let timeInterval = configManager.options.networkEnvironment == .release ? 20.0 : 1.0
    let timer = Timer(
      timeInterval: timeInterval,
      repeats: true
    ) { [weak self] _ in
      guard let self = self else {
        return
      }
      Task {
        await self.flushInternal(depth: 10)
      }
    }
    self.timer = timer
    RunLoop.main.add(timer, forMode: .default)
  }

  @MainActor
  private func addObserver() {
    willResignActiveObserver = NotificationCenter.default
      .publisher(for: UIApplication.willResignActiveNotification)
      .sink { [weak self] _ in
        guard let self = self else {
          return
        }
        Task {
          await self.willResignActive()
        }
      }
  }

  private func willResignActive() async {
    flushInternal(depth: 10)
    saveCacheToDisk()
  }

  func enqueue(_ triggerSession: TriggerSession) {
    triggerSessions.append(triggerSession)
    lastTwentySessions.enqueue(triggerSession)
  }

  func enqueue(_ transaction: StoreTransaction) {
    transactions.append(transaction)
    lastTwentyTransactions.enqueue(transaction)
  }

  func enqueue(_ triggerSessions: [TriggerSession]) {
    self.triggerSessions += triggerSessions

    for session in triggerSessions {
      lastTwentySessions.enqueue(session)
    }
  }

  func flushInternal(depth: Int) {
    var triggerSessionsToSend: [TriggerSession] = []
    var transactionsToSend: [StoreTransaction] = []

    var i = 0
    while i < maxEventCount && !triggerSessions.isEmpty {
      triggerSessionsToSend.append(triggerSessions.removeFirst())
      i += 1
    }

    i = 0
    while i < maxEventCount && !transactions.isEmpty {
      transactionsToSend.append(transactions.removeFirst())
      i += 1
    }

    if !triggerSessionsToSend.isEmpty || !transactionsToSend.isEmpty {
      // Send to network
      let sessionEvents = SessionEventsRequest(
        triggerSessions: triggerSessionsToSend,
        transactions: transactionsToSend
      )
      Task {
        await network.sendSessionEvents(sessionEvents)
      }
    }

    if (!triggerSessions.isEmpty || !transactions.isEmpty) && depth > 0 {
      return flushInternal(depth: depth - 1)
    }
  }

  func saveCacheToDisk() {
    saveLatestSessionsToDisk()
    saveLatestTransactionsToDisk()
  }

  private func saveLatestSessionsToDisk() {
    let sessions = lastTwentySessions.getArray()
    storage.save(sessions, forType: TriggerSessions.self)
  }

  private func saveLatestTransactionsToDisk() {
    let transactions = lastTwentyTransactions.getArray()
    storage.save(transactions, forType: Transactions.self)
  }
}
