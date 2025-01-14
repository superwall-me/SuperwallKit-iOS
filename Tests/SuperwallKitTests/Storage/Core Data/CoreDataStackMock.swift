//
//  File.swift
//  
//
//  Created by Yusuf Tör on 05/07/2022.
//
// swiftlint:disable all

import CoreData
@testable import SuperwallKit

@available(iOS 14.0, *)
final class CoreDataStackMock: CoreDataStack {
  func deleteAllEntities(named entityName: String, completion: () -> Void) {
    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

    do {
      try mainContext!.executeAndMergeChanges(using: deleteRequest)
      completion()
      print("Deleted entities")
    } catch let error as NSError {
      print("Error deleting!", error)
    }
  }

  func batchInsertPlacementData(
    eventName: String,
    count: Int,
    completion: @escaping () -> Void
  ) {
    var index = 0

    let batchInsert = NSBatchInsertRequest(
      entity: ManagedEventData.entity()
    ) { (managedObject: NSManagedObject) -> Bool in
      guard index < count else {
        return true
      }

      if let eventData = managedObject as? ManagedEventData {
        let stub = PlacementData.stub()
          .setting(\.name, to: eventName)
        eventData.createdAt = stub.createdAt
        eventData.id = stub.id
        eventData.name = stub.name
        let params = try! JSONEncoder().encode(stub.parameters)
        eventData.parameters = params
      }
      index += 1
      return false
    }

    persistentContainer!.performBackgroundTask { context in
      do {
        try context.execute(batchInsert)
        completion()
      } catch {
        print("ERROR!", error)
      }
    }
  }

  func batchInsertTriggerOccurrences(
    key: String,
    count: Int,
    completion: @escaping () -> Void
  ) {
    var index = 0

    let batchInsert = NSBatchInsertRequest(
      entity: ManagedTriggerRuleOccurrence.entity()
    ) { (managedObject: NSManagedObject) -> Bool in
      guard index < count else {
        return true
      }

      if let occurrence = managedObject as? ManagedTriggerRuleOccurrence {
        occurrence.createdAt = Date()
        occurrence.occurrenceKey = key
      }
      index += 1
      return false
    }

    persistentContainer!.performBackgroundTask { context in
      do {
        try context.execute(batchInsert)
        completion()
      } catch {
        print("ERROR!", error)
      }
    }
  }
}
