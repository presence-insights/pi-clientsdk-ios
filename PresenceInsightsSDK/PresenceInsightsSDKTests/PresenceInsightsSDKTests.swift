/**
*   Copyright (c) 2015 IBM Corporation. All rights reserved.
*
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*
*   http://www.apache.org/licenses/LICENSE-2.0
*
*   Unless required by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
**/

import UIKit
import XCTest
import PresenceInsightsSDK

class PresenceInsightsSDKTests: XCTestCase {
    
    private var _adapter: PIAdapter!
    private var _device: PIDevice!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        _adapter = PIAdapter(tenant: PI.Tenant, org: PI.Org, baseURL: PI.Hostname, username: PI.Username, password: PI.Password)
        _device = PIDevice(name: "test device")
        _device.type = "External"
        _device.registered = true
        _device.blacklist = false
        _adapter.enableLogging()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // proximity uuids
    func testGetProximityUuids() {
        var expectation = expectationWithDescription("Test retrieving proximityUUIDs from org")
        _adapter.getAllBeaconRegions { (result:[String]) -> () in
            XCTAssertGreaterThan(result.count, 0)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // org
    func testGetOrg() {
        var expectation = expectationWithDescription("Test retrieving the org")
        _adapter.getOrg { (result: PIOrg) -> () in
            XCTAssertNotNil(result, "Should not be nil")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    
    // all sites
    func testGetAllSites() {
        var expectation = expectationWithDescription("Test retrieving all the sites in the org")
        _adapter.getAllSites { (result: [String : String]) -> () in
            XCTAssertGreaterThan(result.count, 0)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // all floors
    func testGetAllFloors() {
        var expectation = expectationWithDescription("Test retrieving all the floors in the site")
        _adapter.getAllFloors(PI.Site) { (result: [String : String]) -> () in
            XCTAssertGreaterThan(result.count, 0)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // all beacons
    func testGetAllBeacons() {
        var expectation = expectationWithDescription("Test retrieving all the beacons on a floor")
        _adapter.getAllBeacons(PI.Site, floor: PI.Floor) { (result: [PIBeacon]) -> () in
            XCTAssertGreaterThan(result.count, 0)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // all zones
    func testGetAllZones() {
        var expectation = expectationWithDescription("Test retrieving all the zones on a floor")
        _adapter.getAllZones(PI.Site, floor: PI.Floor) { (result: [PIZone]) -> () in
            XCTAssertGreaterThan(result.count, 0)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // get map
    func testGetMap() {
        var expectation = expectationWithDescription("Test retrieving the floor map")
        _adapter.getMap(PI.Site, floor: PI.Floor) { (result: UIImage) -> () in
            XCTAssertNotNil(result)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(30.0, handler: nil)
    }
    // register device
    func testRegisterDevice() {
        var expectation = expectationWithDescription("Test registering a device")
        _adapter.registerDevice(_device, callback: { (result: PIDevice) -> () in
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // update device by changing name
    func testUpdateDevice() {
        var expectation = expectationWithDescription("Test updating a device")
        _device.name = "UpdatedTest"
        _adapter.updateDevice(_device, callback: { (result: PIDevice) -> () in
            XCTAssert(result.name == "UpdatedTest")
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // unregister device
    func testUnregisterDevice() {
        var expectation = expectationWithDescription("Test unregistering a device")
        _adapter.unregisterDevice(_device, callback: { (result: PIDevice) -> () in
            XCTAssertFalse(result.registered)
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
