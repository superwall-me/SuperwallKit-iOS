//
//  File.swift
//  
//
//  Created by Yusuf Tör on 31/05/2022.
//

import Foundation
@testable import SuperwallKit

class AppManagerDelegateMock: AppManagerDelegate, DeviceHelperFactory, UserAttributesEventFactory {
  func makeDeviceInfo() -> SuperwallKit.DeviceInfo {
    return .init(appInstalledAtString: "", locale: "")
  }
  func makeIsSandbox() -> Bool { return true}
  func makeSessionDeviceAttributes() async -> [String : Any] { [:] }
  func makeUserAttributesEvent() -> InternalSuperwallEvent.Attributes { 
    return InternalSuperwallEvent.Attributes(appInstalledAtString: "")
  }

  func didUpdateAppSession(_ appSession: AppSession) async {}
}
