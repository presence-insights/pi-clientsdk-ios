//
//  IBMPICoreTests.swift
//  IBMPICoreTests
//
//  Created by Ciaran Hannigan on 4/4/16.
//  Copyright © 2016 Ciaran Hannigan. All rights reserved.
//

import XCTest
@testable import IBMPICore

class IBMPICoreTests: XCTestCase {
    
    private var _adapter: PIAdapter!
    private var _device: PIDevice!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        _adapter = PIAdapter(tenant: PI.Tenant, org: PI.Org, baseURL: PI.Hostname, username: PI.Username, password: PI.Password)
        _device = PIDevice(name: "test device", type: "External", data: [:], unencryptedData: [:], registered: true, blacklist: false)
        _adapter.enableLogging()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // proximity uuids
    func testGetProximityUuids() {
        let expectation = expectationWithDescription("Test retrieving proximityUUIDs from org")
        _adapter.getAllBeaconRegions { (result, error) -> () in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            XCTAssertGreaterThan(result!.count, 0)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // org
    func testGetOrg() {
        let expectation = expectationWithDescription("Test retrieving the org")
        _adapter.getOrg { (result, error) -> () in
            XCTAssertNil(error)
            XCTAssertNotNil(result, "Should not be nil")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    
    // all sites
    func testGetAllSites() {
        let expectation = expectationWithDescription("Test retrieving all the sites in the org")
        _adapter.getAllSites { (result, error) -> () in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            XCTAssertGreaterThan(result!.count, 0)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // all floors
    func testGetAllFloors() {
        let expectation = expectationWithDescription("Test retrieving all the floors in the site")
        _adapter.getAllFloors(PI.Site) { (result, error) -> () in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            XCTAssertGreaterThan(result!.count, 0)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // all beacons
    func testGetAllBeacons() {
        let expectation = expectationWithDescription("Test retrieving all the beacons on a floor")
        _adapter.getAllBeacons(PI.Site, floor: PI.Floor) { (result, error) -> () in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            XCTAssertGreaterThan(result!.count, 0)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // all sensors
    func testGetAllSensors() {
        let expectation = expectationWithDescription("Test retrieving all the sensors on a floor")
        _adapter.getAllSensors(PI.Site, floor: PI.Floor) { (result, error) -> () in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            XCTAssertGreaterThan(result!.count, 0)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // all zones
    func testGetAllZones() {
        let expectation = expectationWithDescription("Test retrieving all the zones on a floor")
        _adapter.getAllZones(PI.Site, floor: PI.Floor) { (result, error) -> () in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            XCTAssertGreaterThan(result!.count, 0)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // get map
    func testGetMap() {
        let expectation = expectationWithDescription("Test retrieving the floor map")
        _adapter.getMap(PI.Site, floor: PI.Floor) { (result, error) -> () in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(30.0, handler: nil)
    }
    // register device
    func testRegisterDevice() {
        let expectation = expectationWithDescription("Test registering a device")
        _adapter.registerDevice(_device, callback: { (result, error) -> () in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // update device by changing name
    func testUpdateDevice() {
        let expectation = expectationWithDescription("Test updating a device")
        _device.name = "UpdatedTest"
        _adapter.updateDevice(_device, callback: { (result, error) -> () in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            XCTAssert(result?.name == "UpdatedTest")
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // unregister device
    func testUnregisterDevice() {
        let expectation = expectationWithDescription("Test unregistering a device")
        _adapter.unregisterDevice(_device, callback: { (result, error) -> () in
            XCTAssertNil(error)
            XCTAssertNotNil(result)
            XCTAssertFalse(result!.registered)
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    
    //    func testPerformanceExample() {
    //        // This is an example of a performance test case.
    //        self.measureBlock() {
    //            // Put the code you want to measure the time of here.
    //        }
    //    }
    
}
