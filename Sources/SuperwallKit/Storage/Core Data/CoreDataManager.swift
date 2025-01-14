//
//  File.swift
//  
//
//  Created by Yusuf Tör on 16/06/2022.
//

import Foundation
import CoreData

class CoreDataManager {
  private let coreDataStack: CoreDataStack
  private var backgroundContext: NSManagedObjectContext?

  init(coreDataStack: CoreDataStack = CoreDataStack()) {
    self.coreDataStack = coreDataStack
    if let persistentContainer = coreDataStack.persistentContainer {
      backgroundContext = persistentContainer.newBackgroundContext()
    }
  }

  func savePlacementData(
    _ placementData: PlacementData,
    completion: ((ManagedEventData) -> Void)? = nil
  ) {
    guard let backgroundContext = backgroundContext else {
      return
    }
    backgroundContext.perform {
      let data = try? JSONEncoder().encode(placementData.parameters)
      guard let managedEventData = ManagedEventData(
        context: backgroundContext,
        id: placementData.id,
        createdAt: placementData.createdAt,
        name: placementData.name,
        parameters: data ?? Data()
      ) else {
        return
      }

      do {
        if backgroundContext.hasChanges {
          try backgroundContext.save()
        }
        completion?(managedEventData)
      } catch let error as NSError {
        Logger.debug(
          logLevel: .error,
          scope: .coreData,
          message: "Error saving to Core Data.",
          info: error.userInfo,
          error: error
        )
      }
    }
  }

  func save(
    triggerAudienceOccurrence audienceOccurence: TriggerAudienceOccurrence,
    completion: ((ManagedTriggerRuleOccurrence) -> Void)? = nil
  ) {
    guard let backgroundContext = backgroundContext else {
      return
    }
    backgroundContext.perform {
      guard let managedAudienceOccurrence = ManagedTriggerRuleOccurrence(
        context: backgroundContext,
        createdAt: Date(),
        occurrenceKey: audienceOccurence.key
      ) else {
        return
      }

      do {
        if backgroundContext.hasChanges {
          try backgroundContext.save()
        }
        completion?(managedAudienceOccurrence)
      } catch let error as NSError {
        Logger.debug(
          logLevel: .error,
          scope: .coreData,
          message: "Error saving to Core Data.",
          info: error.userInfo,
          error: error
        )
      }
    }
  }

  func deleteAllEntities(completion: (() -> Void)? = nil) {
    guard let backgroundContext = backgroundContext else {
      return
    }
    let eventDataRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(
      entityName: ManagedEventData.entityName
    )
    let deletePlacementDataRequest = NSBatchDeleteRequest(fetchRequest: eventDataRequest)

    let occurrenceRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(
      entityName: ManagedTriggerRuleOccurrence.entityName
    )
    let deleteOccurrenceRequest = NSBatchDeleteRequest(fetchRequest: occurrenceRequest)

    backgroundContext.performAndWait {
      do {
        try backgroundContext.executeAndMergeChanges(using: deletePlacementDataRequest)
        try backgroundContext.executeAndMergeChanges(using: deleteOccurrenceRequest)
        completion?()
      } catch {
        Logger.debug(
          logLevel: .error,
          scope: .coreData,
          message: "Could not delete core data.",
          error: error
        )
      }
    }
  }

  func getComputedPropertySincePlacement(
    _ placement: PlacementData?,
    request: ComputedPropertyRequest
  ) async -> Int? {
    var lastEventDate: Date?
    if let placement = placement {
      lastEventDate = placement.name == request.placementName ? placement.createdAt : nil
    }

    return await withCheckedContinuation { continuation in
      coreDataStack.getLastSavedPlacement(
        name: request.placementName,
        before: lastEventDate
      ) { placement in
        guard let placement = placement else {
          return continuation.resume(returning: nil)
        }
        let createdAt = placement.createdAt
        let calendar = Calendar.current
        let currentDate = Date()
        let components = calendar.dateComponents(
          [request.type.calendarComponent],
          from: createdAt,
          to: currentDate
        )

        continuation.resume(returning: request.type.dateComponent(from: components))
      }
    }
  }

  func countAudienceOccurrences(
    for audienceOccurrence: TriggerAudienceOccurrence
  ) async -> Int {
    let fetchRequest = ManagedTriggerRuleOccurrence.fetchRequest()
    fetchRequest.fetchLimit = audienceOccurrence.maxCount

    switch audienceOccurrence.interval {
    case .minutes(let minutes):
      guard let date = Calendar.current.date(
        byAdding: .minute,
        value: -minutes,
        to: Date()
      ) else {
        Logger.debug(
          logLevel: .error,
          scope: .coreData,
          message: "Calendar couldn't calculate date by adding \(minutes) minutes and returned nil."
        )
        // Return maxCount so that it won't fire the trigger.
        return audienceOccurrence.maxCount
      }
      fetchRequest.predicate = NSPredicate(
        format: "createdAt >= %@ AND occurrenceKey == %@",
        date as NSDate,
        audienceOccurrence.key
      )

      return await withCheckedContinuation { continuation in
        coreDataStack.count(for: fetchRequest) { count in
          continuation.resume(returning: count)
        }
      }
    case .infinity:
      fetchRequest.predicate = NSPredicate(format: "occurrenceKey == %@", audienceOccurrence.key)
      return await withCheckedContinuation { continuation in
        coreDataStack.count(for: fetchRequest) { count in
          continuation.resume(returning: count)
        }
      }
    }
  }
}
