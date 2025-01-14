//
//  File.swift
//  
//
//  Created by Yusuf Tör on 05/07/2022.
//

import Foundation
import CoreData

class CoreDataStack {
  static let modelName = "SuperwallKit_Model"

  static let managedObject: NSManagedObjectModel = {
    guard let modelUrl = Bundle.module.url(
      forResource: modelName,
      withExtension: "momd"
    ) else {
      Logger.debug(
        logLevel: .error,
        scope: .coreData,
        message: "Error finding Core Data model."
      )
      return .init()
    }
    guard let model = NSManagedObjectModel(contentsOf: modelUrl) else {
      Logger.debug(
        logLevel: .error,
        scope: .coreData,
        message: "Error loading Core Data model."
      )
      return .init()
    }
    return model
  }()

  var persistentContainer: NSPersistentContainer?
  var backgroundContext: NSManagedObjectContext?
  var mainContext: NSManagedObjectContext?

  init() {
    // First load persistent container
    let persistentContainer = NSPersistentContainer(
      name: Self.modelName,
      managedObjectModel: Self.managedObject
    )

    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()
    var containerError: Error?
    persistentContainer.loadPersistentStores { _, error in
      containerError = error
      if let error = error as NSError? {
        Logger.debug(
          logLevel: .error,
          scope: .coreData,
          message: "Error loading Core Data persistent stores.",
          info: error.userInfo,
          error: error
        )
      }
      dispatchGroup.leave()
    }
    dispatchGroup.wait()
    guard containerError == nil else {
      return
    }

    self.persistentContainer = persistentContainer

    // Then load background and main context
    let backgroundContext = persistentContainer.newBackgroundContext()
    backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    self.backgroundContext = backgroundContext

    let mainContext = persistentContainer.viewContext
    mainContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    self.mainContext = mainContext
  }

  func count<T: NSFetchRequestResult>(
    for fetchRequest: NSFetchRequest<T>,
    completion: @escaping ((Int) -> Void)
  ) {
    guard
      let backgroundContext = backgroundContext,
      persistentContainer != nil
    else {
      return completion(0)
    }
    backgroundContext.perform {
      do {
        let count = try backgroundContext.count(for: fetchRequest)
        completion(count)
      } catch let error as NSError {
        Logger.debug(
          logLevel: .error,
          scope: .coreData,
          message: "Error counting from Core Data.",
          info: error.userInfo,
          error: error
        )
        completion(0)
      }
    }
  }

  func getLastSavedPlacement(
    name: String,
    before date: Date?,
    completion: @escaping ((ManagedEventData?) -> Void)
  ) {
    guard let backgroundContext = backgroundContext else {
      return completion(nil)
    }

    backgroundContext.perform {
      let fetchRequest = ManagedEventData.fetchRequest()
      if let date = date {
        fetchRequest.predicate = NSPredicate(format: "name == %@ AND createdAt < %@", name, date as NSDate)
      } else {
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
      }
      fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
      fetchRequest.fetchLimit = 1

      do {
        let results = try backgroundContext.fetch(fetchRequest)
        guard let placement = results.first else {
          return completion(nil)
        }
        completion(placement)
      } catch {
        Logger.debug(
          logLevel: .error,
          scope: .coreData,
          message: "Error getting last saved event from Core Data.",
          info: ["placement": name],
          error: error
        )
        completion(nil)
      }
    }
  }
}
