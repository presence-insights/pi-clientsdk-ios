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
        let expectation = expectationWithDescription("Test retrieving proximityUUIDs from org")
        _adapter.getAllBeaconRegions { (result:[String], error) -> () in
            XCTAssertGreaterThan(result.count, 0)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // org
    func testGetOrg() {
        let expectation = expectationWithDescription("Test retrieving the org")
        _adapter.getOrg { (result: PIOrg, error) -> () in
            XCTAssertNotNil(result, "Should not be nil")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    
    // all sites
    func testGetAllSites() {
        let expectation = expectationWithDescription("Test retrieving all the sites in the org")
        _adapter.getAllSites { (result: [String : String], error) -> () in
            XCTAssertGreaterThan(result.count, 0)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // all floors
    func testGetAllFloors() {
        let expectation = expectationWithDescription("Test retrieving all the floors in the site")
        _adapter.getAllFloors(PI.Site) { (result: [String : String], error) -> () in
            XCTAssertGreaterThan(result.count, 0)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // all beacons
    func testGetAllBeacons() {
        let expectation = expectationWithDescription("Test retrieving all the beacons on a floor")
        _adapter.getAllBeacons(PI.Site, floor: PI.Floor) { (result: [PIBeacon], error) -> () in
            XCTAssertGreaterThan(result.count, 0)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // all zones
    func testGetAllZones() {
        let expectation = expectationWithDescription("Test retrieving all the zones on a floor")
        _adapter.getAllZones(PI.Site, floor: PI.Floor) { (result: [PIZone], error) -> () in
            XCTAssertGreaterThan(result.count, 0)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // get map
    func testGetMap() {
        let expectation = expectationWithDescription("Test retrieving the floor map")
        _adapter.getMap(PI.Site, floor: PI.Floor) { (result: UIImage, error) -> () in
            XCTAssertNotNil(result)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(30.0, handler: nil)
    }
    // register device
    func testRegisterDevice() {
        let expectation = expectationWithDescription("Test registering a device")
        _adapter.registerDevice(_device, callback: { (result: PIDevice, error) -> () in
            XCTAssertNotNil(result)
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // update device by changing name
    func testUpdateDevice() {
        let expectation = expectationWithDescription("Test updating a device")
        _device.name = "UpdatedTest"
        _adapter.updateDevice(_device, callback: { (result: PIDevice, error) -> () in
            XCTAssert(result.name == "UpdatedTest")
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(15.0, handler: nil)
    }
    // unregister device
    func testUnregisterDevice() {
        let expectation = expectationWithDescription("Test unregistering a device")
        _adapter.unregisterDevice(_device, callback: { (result: PIDevice, error) -> () in
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
