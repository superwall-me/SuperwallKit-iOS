//
//  File.swift
//
//
//  Created by Jake Mor on 3/22/23.

import Foundation

/// The handler for ``Superwall/register(placement:params:handler:feature:)`` whose
/// functions provide status updates for a paywall.
@objc(SWKPaywallPresentationHandler)
@objcMembers
public final class PaywallPresentationHandler: NSObject {
  /// A block called when the paywall did present.
  var onPresentHandler: ((PaywallInfo) -> Void)?

  /// A block called when the paywall did dismiss.
  var onDismissHandler: ((PaywallInfo, PaywallResult) -> Void)?

  /// A block called when the paywall did dismiss.
  ///
  /// Note the ``StoreProduct`` is only non-nil when ``PaywallResultObjc`` is ``PaywallResultObjc/purchased``.
  var onDismissHandlerObjc: ((PaywallInfo, PaywallResultObjc, StoreProduct?) -> Void)?

  /// A block called when an error occurred while trying to present a paywall.
  var onErrorHandler: ((Error) -> Void)?

  /// A block called when an error occurred while trying to present a paywall.
  var onSkipHandler: ((PaywallSkippedReason) -> Void)?

  /// An objective-c only block called when an error occurred while trying to present a paywall.
  var onSkipHandlerObjc: ((PaywallSkippedReasonObjc) -> Void)?

  /// Sets the handler that will be called when the paywall did present.
  ///
  /// - Parameter handler: A block that accepts a ``PaywallInfo`` object associated with
  /// the presented paywall.
  public func onPresent(_ handler: @escaping (PaywallInfo) -> Void) {
    self.onPresentHandler = handler
  }

  /// Sets the handler that will be called when the paywall did dismissed.
  ///
  /// - Parameter handler: A block that accepts a ``PaywallInfo`` and ``PaywallResult`` object associated with
  /// the dismissed paywall.
  public func onDismiss(_ handler: @escaping (PaywallInfo, PaywallResult) -> Void) {
    self.onDismissHandler = handler
  }

  /// Sets the handler that will be called when a paywall is skipped, but no error has occurred.
  ///
  /// - Parameter handler: A block that accepts a ``PaywallSkippedReasonObjc`` indicating why the paywall
  /// was skipped.
  @available(swift, obsoleted: 1.0)
  public func onDismiss(
    _ handler: @escaping (PaywallInfo, PaywallResultObjc, StoreProduct?) -> Void
  ) {
    self.onDismissHandlerObjc = handler
  }

  /// Sets the handler that will be called when an error occurred while trying to present a paywall.
  ///
  /// - Parameter handler: A block that accepts an `Error` indicating why the paywall
  /// could not present.
  public func onError(_ handler: @escaping (Error) -> Void) {
    self.onErrorHandler = handler
  }

  /// Sets the handler that will be called when a paywall is skipped, but no error has occurred.
  ///
  /// - Parameter handler: A block that accepts a ``PaywallSkippedReason`` indicating why the paywall
  /// was skipped.
  public func onSkip(_ handler: @escaping (PaywallSkippedReason) -> Void) {
    self.onSkipHandler = handler
  }

  /// Sets the handler that will be called when a paywall is skipped, but no error has occurred.
  ///
  /// - Parameter handler: A block that accepts a ``PaywallSkippedReasonObjc`` indicating why the paywall
  /// was skipped.
  @available(swift, obsoleted: 1.0)
  public func onSkip(_ handler: @escaping (PaywallSkippedReasonObjc) -> Void) {
    self.onSkipHandlerObjc = handler
  }
}
