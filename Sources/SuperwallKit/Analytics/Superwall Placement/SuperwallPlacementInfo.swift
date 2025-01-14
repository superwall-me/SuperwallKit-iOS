//
//  File.swift
//  
//
//  Created by Yusuf Tör on 07/11/2022.
//

import Foundation

/// Contains information about the internally tracked superwall placement.
@objc(SWKSuperwallPlacementInfo)
@objcMembers
public final class SuperwallPlacementInfo: NSObject {
  /// The placement that was tracked.
  public let placement: SuperwallPlacement

  /// Objective-C compatible ``SuperwallPlacement``.
  @objc(placement)
  public lazy var objcPlacement: SuperwallPlacementObjc = {
    return SuperwallPlacementObjc(placement: placement)
  }()

  /// A dictionary of params associated with the placement.
  public let params: [String: Any]

  /// Initializes an instance of the the internally tracked superwall placement result.
  /// - Parameters:
  ///   - placement: The placement that was tracked.
  ///   - params: A dictionary of params associated with the placement.
  public init(placement: SuperwallPlacement, params: [String: Any]) {
    self.placement = placement
    self.params = params
  }
}
