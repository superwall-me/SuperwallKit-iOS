//
//  File.swift
//  
//
//  Created by Yusuf Tör on 11/07/2022.
//

import CoreData
@testable import SuperwallKit

@available(iOS 14.0, *)
final class CoreDataManagerFakeDataMock: CoreDataManager {
  var internalOccurrenceCount: Int

  init(internalOccurrenceCount: Int = 1) {
    self.internalOccurrenceCount = internalOccurrenceCount
    super.init(coreDataStack: CoreDataStackMock())
  }

  override func countAudienceOccurrences(for ruleOccurrence: TriggerAudienceOccurrence) async -> Int {
    return internalOccurrenceCount
  }
}
