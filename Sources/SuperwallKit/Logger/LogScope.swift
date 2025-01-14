//
//  File.swift
//  
//
//  Created by Yusuf Tör on 22/11/2022.
//

import Foundation

/// The possible scope of logs to print to the console.
@objc(SWKLogScope)
public enum LogScope: Int, Encodable, Sendable, CustomStringConvertible {
  case localizationManager
  case analytics
  case bounceButton
  case coreData
  case configManager
  case identityManager
  case debugManager
  case debugViewController
  case localizationViewController
  case gameControllerManager
  case device
  case network
  case paywallEvents
  case productsManager
  case storeKitManager
  case placements
  case receipts
  case superwallCore
  case paywallPresentation
  case entitlements
  case transactions
  case paywallViewController
  case cache
  case all

  public var description: String {
    switch self {
    case .analytics:
      return "analytics"
    case .localizationManager:
      return "localizationManager"
    case .bounceButton:
      return "bounceButton"
    case .coreData:
      return "coreData"
    case .configManager:
      return "configManager"
    case .identityManager:
      return "identityManager"
    case .debugManager:
      return "debugManager"
    case .debugViewController:
      return "debugViewController"
    case .localizationViewController:
      return "localizationViewController"
    case .gameControllerManager:
      return "gameControllerManager"
    case .device:
      return "device"
    case .network:
      return "network"
    case .paywallEvents:
      return "paywallEvents"
    case .productsManager:
      return "productsManager"
    case .storeKitManager:
      return "storeKitManager"
    case .placements:
      return "placements"
    case .receipts:
      return "receipts"
    case .superwallCore:
      return "superwallCore"
    case .paywallPresentation:
      return "paywallPresentation"
    case .transactions:
      return "transactions"
    case .entitlements:
      return "entitlements"
    case .paywallViewController:
      return "paywallViewController"
    case .cache:
      return "cache"
    case .all:
      return "all"
    }
  }
}
