//
//  File.swift
//  
//
//  Created by Yusuf Tör on 05/07/2022.
//

import Foundation
import CoreData

final class ManagedPlacementData: NSManagedObject {
  static let entityName = "PlacementData"
  @NSManaged var id: String
  @NSManaged var createdAt: Date
  @NSManaged var name: String
  @NSManaged var parameters: Data

  init?(
    context: NSManagedObjectContext,
    id: String,
    createdAt: Date,
    name: String,
    parameters: Data
  ) {
    guard let entity = NSEntityDescription.entity(
      forEntityName: "PlacementData",
      in: context
    ) else {
      Logger.debug(
        logLevel: .error,
        scope: .coreData,
        message: "Failed to create managed event data for event \(name)"
      )
      return nil
    }
    super.init(entity: entity, insertInto: context)

    self.id = id
    self.createdAt = createdAt
    self.name = name
    self.parameters = parameters
  }

  @nonobjc
  class func fetchRequest() -> NSFetchRequest<ManagedPlacementData> {
    return NSFetchRequest<ManagedPlacementData>(entityName: entityName)
  }

  @objc override private init(
    entity: NSEntityDescription,
    insertInto context: NSManagedObjectContext?
  ) {
    super.init(entity: entity, insertInto: context)
  }

  @available(*, unavailable)
  init() {
    fatalError("\(#function) not implemented")
  }

  @available(*, unavailable)
  convenience init(context: NSManagedObjectContext) {
    fatalError("\(#function) not implemented")
  }
}
