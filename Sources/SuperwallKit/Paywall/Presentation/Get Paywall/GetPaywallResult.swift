//
//  File.swift
//  
//
//  Created by Yusuf Tör on 05/05/2023.
//

import Foundation

/// An object that represents the result of calling
/// ``Superwall/getPaywall(forPlacement:params:paywallOverrides:delegate:completion:)``.
@objc(SWKGetPaywallResult)
@objcMembers
public final class GetPaywallResultObjc: NSObject {
  /// The ``PaywallViewController``.
  public let paywall: PaywallViewController?

  /// The reason that the paywall retrieval was intentionally skipped.
  public let skippedReason: PaywallSkippedReasonObjc

  /// Any errors that occurred when trying to retrieve the ``PaywallViewController``.
  public let error: Error?

  init(
    paywall: PaywallViewController?,
    skippedReason: PaywallSkippedReasonObjc,
    error: Error?
  ) {
    self.paywall = paywall
    self.skippedReason = skippedReason
    self.error = error
  }
}
