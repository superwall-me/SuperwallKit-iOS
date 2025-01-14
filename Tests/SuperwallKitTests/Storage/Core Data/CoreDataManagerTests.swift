//
//  File.swift
//  
//
//  Created by Yusuf Tör on 05/07/2022.
//
// swiftlint:disable all

import XCTest
@testable import SuperwallKit

@available(iOS 16.0, *)
class CoreDataManagerTests: XCTestCase {
  var coreDataManager: CoreDataManagerMock!
  var coreDataStack: CoreDataStackMock!

  override func setUp() {
    super.setUp()
    coreDataStack = CoreDataStackMock()
    coreDataManager = CoreDataManagerMock(coreDataStack: coreDataStack)
  }

  override func tearDown() {
    super.tearDown()
    coreDataManager = nil
    coreDataStack = nil
  }

  func test_savePlacementData_withParams() {
    let eventName = "abc"
    let eventData: PlacementData = .stub()
      .setting(\.name, to: eventName)
      .setting(\.parameters, to: ["def": "ghi"])

    let expectation = expectation(description: "Saved event")

    coreDataManager.savePlacementData(eventData) { savedPlacementData in
      XCTAssertEqual(savedPlacementData.name, eventName)
      XCTAssertEqual(savedPlacementData.name, eventName)
      XCTAssertEqual(savedPlacementData.createdAt, eventData.createdAt)

      let encodedParams = try? JSONEncoder().encode(eventData.parameters)
      XCTAssertEqual(savedPlacementData.parameters, encodedParams)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2.0) { error in
      XCTAssertNil(error, "Save did not occur")
    }
  }

  func test_savePlacementData_withoutParams() {
    let eventName = "abc"
    let eventData: PlacementData = .stub()
      .setting(\.name, to: eventName)
      .setting(\.parameters, to: [:])

    let expectation = expectation(description: "Saved event")

    coreDataManager.savePlacementData(eventData) { savedPlacementData in
      XCTAssertEqual(savedPlacementData.name, eventName)
      XCTAssertEqual(savedPlacementData.name, eventName)
      XCTAssertEqual(savedPlacementData.createdAt, eventData.createdAt)

      let encodedParams = try? JSONEncoder().encode(eventData.parameters)
      XCTAssertEqual(savedPlacementData.parameters, encodedParams)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 2.0) { error in
      XCTAssertNil(error, "Save did not occur")
    }
  }

  // MARK: - Delete All Entities
  // TODO: Fix this, doesn't work when run together but works when run individually
//  func test_deleteAllEntities() async {
//    // Save Event Data with Params
//    let placementName = "abc"
//    let placementData: PlacementData = .stub()
//      .setting(\.name, to: placementName)
//      .setting(\.parameters, to: ["def": "ghi"])
//
//    let expectation1 = expectation(description: "Saved event")
//
//    coreDataManager.savePlacementData(eventData) { savedPlacementData in
//      XCTAssertEqual(savedPlacementData.name, placementName)
//      XCTAssertEqual(savedPlacementData.name, placementName)
//      XCTAssertEqual(savedPlacementData.createdAt, eventData.createdAt)
//
//      let encodedParams = try? JSONEncoder().encode(eventData.parameters)
//      XCTAssertEqual(savedPlacementData.parameters, encodedParams)
//      expectation1.fulfill()
//    }
//
//    await fulfillment(of: [expectation1], timeout: 2)
//
//
//    // Save Trigger Rule Occurrence
//    let key = "abc"
//    let maxCount = 10
//    let interval: TriggerAudienceOccurrence.Interval = .minutes(60)
//    let occurrence = TriggerAudienceOccurrence(
//      key: key,
//      maxCount: maxCount,
//      interval: interval
//    )
//    let expectation2 = expectation(description: "Saved event")
//    let date = Date().advanced(by: -5)
//
//    coreDataManager.save(triggerRuleOccurrence: occurrence) { savedPlacementData in
//      XCTAssertEqual(savedPlacementData.occurrenceKey, key)
//      XCTAssertGreaterThan(savedPlacementData.createdAt, date)
//      expectation2.fulfill()
//    }
//
//    await fulfillment(of: [expectation2], timeout: 20)
//
//    let expectation3 = expectation(description: "Cleared events")
//
//    // Delete All Entities
//    coreDataManager.deleteAllEntities() {
//      expectation3.fulfill()
//    }
//
//    await fulfillment(of: [expectation3], timeout: 20)
//
//    try? await Task.sleep(for: .seconds(3))
//
//    // Count triggers
//    let occurrenceCount = await coreDataManager.countTriggerRuleOccurrences(for: occurrence)
//    XCTAssertEqual(occurrenceCount, 0)
//
//    let eventCount = await coreDataManager.countAllEvents()
//    XCTAssertEqual(eventCount, 0)
//  }

  // MARK: - Trigger Rule Occurrence
  func test_saveTriggerRuleOccurrence() {
    let key = "abc"
    let maxCount = 10
    let interval: TriggerAudienceOccurrence.Interval = .minutes(60)
    let occurrence = TriggerAudienceOccurrence(
      key: key,
      maxCount: maxCount,
      interval: interval
    )
    let expectation = expectation(description: "Saved event")
    let date = Date().advanced(by: -5)

    coreDataManager.save(triggerAudienceOccurrence: occurrence) { savedPlacementData in
      XCTAssertEqual(savedPlacementData.occurrenceKey, key)
      XCTAssertGreaterThan(savedPlacementData.createdAt, date)
      expectation.fulfill()
    }

    waitForExpectations(timeout: 20.0) { error in
      XCTAssertNil(error, "Save did not occur")
    }
  }

  func test_countTriggerRuleOccurrences_minutes() {
    var keys: [String] = []
    for i in 0..<200 {
      keys.append("\(i)")
    }

    let expectation1 = expectation(description: "Saved Trigger Occurrences")
    expectation1.expectedFulfillmentCount = keys.count

    for key in keys {
      coreDataStack.batchInsertTriggerOccurrences(
        key: key,
        count: 10,
        completion: {
          expectation1.fulfill()
        }
      )
    }

    waitForExpectations(timeout: 10.0) { error in
      XCTAssertNil(error, "Save did not occur")
    }


    let key = "1"
    let maxCount = 10
    let interval: TriggerAudienceOccurrence.Interval = .minutes(60)
    let occurrence = TriggerAudienceOccurrence(
      key: key,
      maxCount: maxCount,
      interval: interval
    )

    measure {
      let exp = expectation(description: "Finished")
      Task {
        var count = 0
        count = await coreDataManager.countAudienceOccurrences(for: occurrence)
        exp.fulfill()
        XCTAssertEqual(count, 10)
      }
      wait(for: [exp], timeout: 15.0)
    }

  }

  /*
   uncomments to test count of trigger rule occurrence with loads of events
  func test_countTriggerRuleOccurrences_loadsOfEvents() {
    var names: [String] = []
    for i in 0..<200 {
      names.append("\(i)")
    }

    let expectation1 = expectation(description: "Saved Event")
    expectation1.expectedFulfillmentCount = names.count


    for i in 0..<names.count {
      let name = names[i]
      let count = 1000.0/(2.0*(Double(i)+1.0))
      print("COUNT is ", count)
      coreDataStack.batchInsertPlacementData(placementName: name, count: Int(count)) {
        expectation1.fulfill()
      }
    }

    waitForExpectations(timeout: 50.0) { error in
      XCTAssertNil(error, "Save did not occur")
    }

    var keys: [String] = []
    for i in 0..<400 {
      keys.append("\(i)")
    }

    let expectation2 = expectation(description: "Saved Trigger Occurrences")
    expectation2.expectedFulfillmentCount = keys.count

    for key in keys {
      coreDataStack.batchInsertTriggerOccurrences(
        key: key,
        count: 250,
        completion: {
          expectation2.fulfill()
        }
      )
    }

    let key = "1"
    let maxCount = 10
    let interval: TriggerRuleOccurrence.Interval = .minutes(60)
    let occurrence = TriggerRuleOccurrence(
      key: key,
      maxCount: maxCount,
      interval: interval
    )

    var count = 0
    measure {
      count = coreDataManager.countAudienceOccurrences(for: occurrence)
    }

    waitForExpectations(timeout: 2.0) { error in
      XCTAssertNil(error, "Save did not occur")
    }

    XCTAssertEqual(count, 10)
  }*/
}
