//
//  File.swift
//  
//
//  Created by Yusuf Tör on 09/05/2023.
//

import Foundation

/// An interface for responding to user interactions with a ``PaywallViewController`` that
/// has been retrieved using
/// ``Superwall/getPaywall(forPlacement:params:paywallOverrides:delegate:)``.
public protocol PaywallViewControllerDelegate: AnyObject {
  /// Tells the delegate that the user finished interacting with the paywall and whether the delegate
  /// should dismiss the paywall.
  ///
  /// You should always check the `shouldDismiss` parameter to decide what to do when this method
  /// is called. If `shouldDismiss` is `true`, make sure to dismiss the paywall.
  ///
  /// - Parameters:
  ///   - paywall: The ``PaywallViewController`` that the user is interacting with.
  ///   - result: A ``PaywallResult`` enum that contains the reason for the dismissal of
  ///   the ``PaywallViewController``.
  ///   - shouldDismiss: A `boolean` indicating whether the delegate should dismiss the paywall.
  @MainActor
  func paywall(
    _ paywall: PaywallViewController,
    didFinishWith result: PaywallResult,
    shouldDismiss: Bool
  )

  /// Tells the delegate that the loading state of the paywall did change.
  ///
  /// - Parameters:
  ///   - paywall: The ``PaywallViewController`` that the user is interacting with.
  ///   - loadingState: A ``PaywallLoadingState`` enum that contains the loading state of
  ///   the ``PaywallViewController``.
  @MainActor
  func paywall(
    _ paywall: PaywallViewController,
    loadingStateDidChange loadingState: PaywallLoadingState
  )
}

extension PaywallViewControllerDelegate {
  @MainActor
  func paywall(
    _ paywall: PaywallViewController,
    loadingStateDidChange loadingState: PaywallLoadingState
  ) {}
}

/// Objective-C-only interface for responding to user interactions with a ``PaywallViewController`` that
/// has been retrieved using
/// ``Superwall/getPaywall(forPlacement:params:paywallOverrides:delegate:completion:)-5vtpb``.
@objc(SWKPaywallViewControllerDelegate)
public protocol PaywallViewControllerDelegateObjc: AnyObject {
  /// Tells the delegate that the user finished interacting with the paywall and whether the delegate
  /// should dismiss the paywall.
  ///
  /// You should always check the `shouldDismiss` parameter to decide what to do when this method
  /// is called. If `shouldDismiss` is `true`, make sure to dismiss the paywall.
  ///
  /// - Parameters:
  ///   - paywall: The ``PaywallViewController`` that the user is interacting with.
  ///   - result: A ``PaywallResultObjc`` enum that contains the reason for the dismissal of
  ///   the ``PaywallViewController``.
  ///   - shouldDismiss: A `boolean` indicating whether the delegate should dismiss the paywall.
  @MainActor
  func paywall(
    _ paywall: PaywallViewController,
    didFinishWithResult result: PaywallResultObjc,
    shouldDismiss: Bool
  )

  /// Tells the delegate that the loading state of the paywall did change.
  ///
  /// - Parameters:
  ///   - paywall: The ``PaywallViewController`` that the user is interacting with.
  ///   - loadingState: A ``PaywallLoadingState`` enum that contains the loading state of
  ///   the ``PaywallViewController``.
  @MainActor
  func paywall(
    _ paywall: PaywallViewController,
    loadingStateDidChange loadingState: PaywallLoadingState
  )
}

extension PaywallViewControllerDelegateObjc {
  @MainActor
  func paywall(
    _ paywall: PaywallViewController,
    loadingStateDidChange loadingState: PaywallLoadingState
  ) {}
}

protocol PaywallViewControllerEventDelegate: AnyObject {
  @MainActor func eventDidOccur(
    _ paywallEvent: PaywallWebEvent,
    on paywallViewController: PaywallViewController
  ) async
}
