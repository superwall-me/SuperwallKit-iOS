//
//  File.swift
//  
//
//  Created by Yusuf Tör on 31/05/2022.
//

import Foundation
@testable import SuperwallKit

class AppManagerDelegateMock: DeviceHelperFactory, UserAttributesPlacementFactory {
  func makeDeviceInfo() -> SuperwallKit.DeviceInfo {
    return .init(appInstalledAtString: "", locale: "")
  }
  func makeIsSandbox() -> Bool { return true}
  func makeSessionDeviceAttributes() async -> [String : Any] { [:] }
  func makeUserAttributesPlacement() -> InternalSuperwallPlacement.Attributes { 
    return InternalSuperwallPlacement.Attributes(appInstalledAtString: "")
  }
}
