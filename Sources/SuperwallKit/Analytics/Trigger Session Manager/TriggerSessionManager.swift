//
//  File.swift
//  
//
//  Created by Yusuf Tör on 29/04/2022.
//
// swiftlint:disable type_body_length file_length

import UIKit
import StoreKit
import Combine

actor TriggerSessionManager {
  /// The list of all potential trigger sessions, keyed by the trigger event name, created after receiving the config.
  private var pendingTriggerSessions: [String: TriggerSession] = [:]

  /// The active trigger session.
  var activeTriggerSession: TriggerSession?

  private let storage: Storage
  private let configManager: ConfigManager
  private let appSessionManager: AppSessionManager
  private let identityManager: IdentityManager
  private let delegate: SessionEventsDelegate
  private let sessionEventsManager: SessionEventsManager

  /// A local count for transactions used within the trigger session.
  private var transactionCount: TriggerSession.Transaction.Count?

  @MainActor
  private var observerCancellables: [AnyCancellable] = []
  private var configListener: AnyCancellable?

  enum LoadState {
    case start
    case end
    case fail
  }

  init(
    delegate: SessionEventsDelegate,
    sessionEventsManager: SessionEventsManager,
    storage: Storage,
    configManager: ConfigManager,
    appSessionManager: AppSessionManager,
    identityManager: IdentityManager
  ) {
    self.delegate = delegate
    self.sessionEventsManager = sessionEventsManager
    self.storage = storage
    self.configManager = configManager
    self.appSessionManager = appSessionManager
    self.identityManager = identityManager
    Task {
      await listenForConfig()
      await addObservers()
    }
  }

  private func listenForConfig() {
    configListener = configManager.configState
      .compactMap { $0.getConfig() }
      .sink(
        receiveCompletion: { _ in },
        receiveValue: { [weak self] config in
          guard let self = self else {
            return
          }
          Task {
            await self.createSessions(from: config)
          }
        }
      )
  }

  @MainActor
  private func addObservers() async {
    NotificationCenter.default
      .publisher(for: UIApplication.willEnterForegroundNotification)
      .sink { [weak self] _ in
        Task {
          await self?.willEnterForeground()
        }
      }
      .store(in: &observerCancellables)

    NotificationCenter.default
      .publisher(for: UIApplication.didEnterBackgroundNotification)
      .sink { [weak self] _ in
        Task {
          await self?.didEnterBackground()
        }
      }
      .store(in: &observerCancellables)
  }

  private func willEnterForeground() async {
    activeTriggerSession?.id = UUID().uuidString
    activeTriggerSession?.endAt = nil
    await enqueueCurrentTriggerSession()
  }

  private func didEnterBackground() async {
    activeTriggerSession?.endAt = Date()
    await enqueueCurrentTriggerSession()
  }

  // MARK: - Session Lifecycle

  /// Creates a session for each potential trigger on config and manual paywall presentation and sends them off to the server.
  func createSessions(from config: Config) async {
    // Loop through triggers and create a session for each.
    let isUserSubscribed = Superwall.shared.subscriptionStatus == .active
    for trigger in config.triggers {
      let pendingTriggerSession = TriggerSessionManagerLogic.createPendingTriggerSession(
        configRequestId: configManager.config?.requestId,
        userAttributes: identityManager.userAttributes,
        isSubscribed: isUserSubscribed,
        eventName: trigger.eventName,
        appSession: appSessionManager.appSession
      )
      pendingTriggerSessions[trigger.eventName] = pendingTriggerSession
    }

    // Send the sessions back to the server.
    await enqueuePendingTriggerSessions()
  }

  /// Active a pending trigger session.
  ///
  /// - Parameters:
  ///   - presentationInfo: Information about the paywall presentation.
  ///   - presentingViewController: What view the paywall will be presented on, if any.
  ///   - paywall: The response from the server associated with the paywall
  @discardableResult func activateSession(
    for presentationInfo: PresentationInfo,
    on presentingViewController: UIViewController? = nil,
    paywall: Paywall? = nil,
    triggerResult: InternalTriggerResult?,
    trackEvent: (Trackable) async -> TrackingResult = Superwall.shared.track
  ) async -> String? {
    guard let eventName = presentationInfo.eventName else {
      // The paywall is being presented by identifier, which is what the debugger uses,
      // and that's not supported.
      return nil
    }

    guard var session = pendingTriggerSessions[eventName] else {
      return nil
    }
    guard let outcome = TriggerSessionManagerLogic.outcome(
      presentationInfo: presentationInfo,
      presentingViewController: presentingViewController,
      paywall: paywall,
      triggerResult: triggerResult?.toPublicType()
    ) else {
      return nil
    }

    // Update trigger session
    session.userAttributes = JSON(identityManager.userAttributes)
    session.presentationOutcome = outcome.presentationOutcome
    session.trigger = outcome.trigger
    session.paywall = outcome.paywall
    session.products = TriggerSession.Products(
      allProducts: paywall?.swProducts ?? [],
      loadingInfo: paywall?.productsLoadingInfo
    )

    session.appSession = appSessionManager.appSession

    self.activeTriggerSession = session
    pendingTriggerSessions[eventName] = nil

    if let triggerResult = triggerResult {
      let trackedEvent = InternalSuperwallEvent.TriggerFire(
        triggerResult: triggerResult,
        triggerName: eventName,
        sessionEventsManager: sessionEventsManager
      )
      _ = await trackEvent(trackedEvent)
    }

    switch outcome.presentationOutcome {
    case .holdout,
      .noRuleMatch:
      await endSession()
    case .paywall:
      await enqueueCurrentTriggerSession()
    }

    return session.id
  }

  /// Ends the active trigger session and resets it to `nil`.
  func endSession() async {
    guard var currentTriggerSession = activeTriggerSession else {
      return
    }
    // Send off current trigger session
    currentTriggerSession.endAt = Date()
    activeTriggerSession = currentTriggerSession
    await enqueueCurrentTriggerSession()

    // Recreate a pending trigger session
    let eventName = currentTriggerSession.trigger.eventName
    let isUserSubscribed = Superwall.shared.subscriptionStatus == .active
    let pendingTriggerSession = TriggerSessionManagerLogic.createPendingTriggerSession(
      configRequestId: configManager.config?.requestId,
      userAttributes: identityManager.userAttributes,
      isSubscribed: isUserSubscribed,
      eventName: eventName,
      products: currentTriggerSession.products.allProducts,
      appSession: appSessionManager.appSession
    )
    pendingTriggerSessions[eventName] = pendingTriggerSession

    // Reset state of current trigger session
    transactionCount = nil
    activeTriggerSession = nil
  }

  /// Queues the trigger session to be sent back to the server.
  private func enqueueCurrentTriggerSession() async {
    guard var triggerSession = activeTriggerSession else {
      return
    }
    let isUserSubscribed = Superwall.shared.subscriptionStatus == .active
    triggerSession.isSubscribed = isUserSubscribed
    await delegate.enqueue(triggerSession)
  }

  /// Queues all the pending trigger sessions to be sent back to the server.
  private func enqueuePendingTriggerSessions() async {
    let isUserSubscribed = Superwall.shared.subscriptionStatus == .active
    for eventName in pendingTriggerSessions.keys {
      guard var pendingTriggerSession = pendingTriggerSessions[eventName] else {
        continue
      }
      pendingTriggerSession.isSubscribed = isUserSubscribed
      pendingTriggerSessions[eventName] = pendingTriggerSession
    }
    let triggerSessionsArray = Array(pendingTriggerSessions.values)
    await delegate.enqueue(triggerSessionsArray)
  }

  // MARK: - App Session

  /// Adds the latest app session to the trigger
  func updateAppSession(to appSession: AppSession) async {
    activeTriggerSession?.appSession = appSession

    for eventName in pendingTriggerSessions.keys {
      var pendingTriggerSession = pendingTriggerSessions[eventName]
      pendingTriggerSession?.appSession = appSession
      pendingTriggerSessions[eventName] = pendingTriggerSession
    }

    await enqueuePendingTriggerSessions()
    await enqueueCurrentTriggerSession()
  }

  // MARK: - Paywall

  /// Tracks when the paywall was opened
  func trackPaywallOpen() async {
    activeTriggerSession?.paywall?.action.openAt = Date()
    await enqueueCurrentTriggerSession()
  }

  /// Tracks when paywall was closed and then ends the session.
  func trackPaywallClose() async {
    activeTriggerSession?.paywall?.action.closeAt = Date()
    await endSession()
  }

  // MARK: - Webview Load

  /// Tracks when a webview started to load.
  func trackWebviewLoad(
    forPaywallId paywallId: String,
    state: LoadState
  ) async {
    // Check the webview that's loading is for the active trigger session paywall.
    // Without this check preloading paywalls could intefere.
    guard paywallId == activeTriggerSession?.paywall?.databaseId else {
      return
    }
    switch state {
    case .start:
      activeTriggerSession?
        .paywall?
        .webviewLoading
        .startAt = Date()
    case .end:
      activeTriggerSession?
        .paywall?
        .webviewLoading
        .endAt = Date()
    case .fail:
      activeTriggerSession?
        .paywall?
        .webviewLoading
        .failAt = Date()
    }

    await enqueueCurrentTriggerSession()
  }

  // MARK: - Paywall Response Load

  /// Tracks when a paywall started to load.
  func trackPaywallResponseLoad(
    forPaywallId paywallId: String?,
    state: LoadState
  ) async {
    if paywallId == nil {
      return
    }

    // Otherwise, we check against the databaseId of the paywall
    guard paywallId == activeTriggerSession?.paywall?.databaseId else {
      return
    }

    switch state {
    case .start:
      activeTriggerSession?
        .paywall?
        .responseLoading
        .startAt = Date()
    case .end:
      activeTriggerSession?
        .paywall?
        .responseLoading
        .endAt = Date()
    case .fail:
      activeTriggerSession?
        .paywall?
        .responseLoading
        .failAt = Date()
    }

    await enqueueCurrentTriggerSession()
  }

  // MARK: - Products

  /// Tracks when products started to load.
  func trackProductsLoad(
    forPaywallId paywallId: String,
    state: LoadState
  ) async {
    guard paywallId == activeTriggerSession?.paywall?.databaseId else {
      return
    }
    switch state {
    case .start:
      activeTriggerSession?
        .products
        .loadingInfo?
        .startAt = Date()
    case .end:
      activeTriggerSession?
        .products
        .loadingInfo?
        .endAt = Date()
    case .fail:
      activeTriggerSession?
        .products
        .loadingInfo?
        .failAt = Date()
    }
    await enqueueCurrentTriggerSession()
  }

  // MARK: - Transactions

  func trackBeginTransaction(
    of product: StoreProduct
  ) async {
    // Determine local transaction count, per trigger session.
    if transactionCount != nil {
      transactionCount?.start += 1
    } else {
      transactionCount = .init(start: 1)
    }

    let productIndex = activeTriggerSession?
      .products
      .allProducts
      .firstIndex {
        $0.productIdentifier == product.productIdentifier
      } ?? 0
    activeTriggerSession?.transaction = await .init(
      startAt: Date(),
      count: transactionCount,
      product: .init(from: product, index: productIndex)
    )
    await enqueueCurrentTriggerSession()
  }

  /// When a transaction error occurred.
  func trackTransactionError() async {
    transactionCount?.fail += 1

    activeTriggerSession?
      .transaction?
      .count = transactionCount

    activeTriggerSession?
      .transaction?
      .endAt = Date()

    activeTriggerSession?
      .transaction?
      .status = .fail

    await enqueueCurrentTriggerSession()

    activeTriggerSession?
      .transaction = nil
  }

  /// When a transaction has been abandoned.
  func trackTransactionAbandon() async {
    transactionCount?.abandon += 1

    activeTriggerSession?
      .transaction?
      .count = transactionCount

    activeTriggerSession?
      .transaction?
      .status = .abandon

    activeTriggerSession?
      .transaction?
      .endAt = Date()

    await enqueueCurrentTriggerSession()

    activeTriggerSession?
      .transaction = nil
  }

  /// When a transaction is restored. A restore is triggered without any other transaction occurring.
  func trackTransactionRestoration(
    withId id: String? = nil,
    product: StoreProduct? = nil
  ) async {
    if transactionCount != nil {
      transactionCount?.restore += 1
    } else {
      transactionCount = .init(restore: 1)
    }

    var transaction: TriggerSession.Transaction

    var transactingProduct: TriggerSession.Transaction.Product?

    if let product = product {
      let productIndex = activeTriggerSession?
        .products
        .allProducts
        .firstIndex {
          $0.productIdentifier == product.productIdentifier
        } ?? 0
      transactingProduct = await .init(from: product, index: productIndex)
    }

    let date = Date()
    transaction = .init(
      id: id,
      startAt: date,
      endAt: date,
      count: transactionCount,
      status: .complete,
      product: transactingProduct
    )

    activeTriggerSession?
      .transaction = transaction

    await enqueueCurrentTriggerSession()

    activeTriggerSession?
      .transaction = nil
  }

  func trackPendingTransaction() async {
    transactionCount?.fail += 1

    activeTriggerSession?
      .transaction?
      .count = transactionCount

    activeTriggerSession?
      .transaction?
      .status = .fail

    activeTriggerSession?
      .transaction?
      .endAt = Date()
    await enqueueCurrentTriggerSession()

    activeTriggerSession?
      .transaction = nil
  }

  func trackTransactionSucceeded(
    withId id: String?,
    for product: StoreProduct,
    isFreeTrialAvailable: Bool
  ) async {
    transactionCount?.complete += 1

    activeTriggerSession?
      .transaction?
      .count = transactionCount

    activeTriggerSession?
      .transaction?
      .id = id

    activeTriggerSession?
      .transaction?
      .endAt = Date()

    activeTriggerSession?
      .transaction?
      .status = .complete

    activeTriggerSession?
      .paywall?
      .action
      .convertedAt = Date()

    let transactionOutcome = TriggerSessionManagerLogic.getTransactionOutcome(
      for: product,
      isFreeTrialAvailable: isFreeTrialAvailable
    )
    activeTriggerSession?
      .transaction?
      .outcome = transactionOutcome

    await enqueueCurrentTriggerSession()

    activeTriggerSession?
      .transaction = nil
  }
}
