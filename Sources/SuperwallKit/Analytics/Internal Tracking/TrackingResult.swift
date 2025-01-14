//
//  File.swift
//  
//
//  Created by Yusuf Tör on 22/04/2022.
//

import Foundation

struct TrackingResult {
  var data: PlacementData
  let parameters: TrackingParameters
}
extension TrackingResult: Stubbable {
  static func stub() -> TrackingResult {
    return TrackingResult(
      data: .stub(),
      parameters: .stub()
    )
  }
}
