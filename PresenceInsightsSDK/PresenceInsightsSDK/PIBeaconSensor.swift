/**
*   PresenceInsightsSDK
*   PIBeaconSensor.swift
*
*   Handles all beacon and location management.
*
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
import CoreLocation

// MARK: - Delegate protocol.
public protocol PIBeaconSensorDelegate {
    func didRangeBeacons(beacons:[CLBeacon])
    func didEnterRegion(region: CLRegion)
    func didExitRegion(region: CLRegion)
}

// MARK: - PIBeaconSensor object
public class PIBeaconSensor: NSObject {
    
    private var PI_REPORT_INTERVAL: NSTimeInterval = 5
    
    public var delegate: PIBeaconSensorDelegate?
    
    private var _piAdapter: PIAdapter!
    private var _locationManager: CLLocationManager!
    private var _monitoredRegions: [CLBeaconRegion] = []
    private var _lastDetected: NSDate!
    
    public init(adapter: PIAdapter) {
        
        super.init()
        
        _piAdapter = adapter
        _locationManager = CLLocationManager()
        _locationManager.delegate = self
        _locationManager.requestAlwaysAuthorization()
        
        // to enable ranging in the background
        _locationManager.startUpdatingLocation()
        // we are only interested in beacons, so this accuracy will not require Wifi or GPS, which will save battery
        _locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }
    
    /**
    Public function to start sensing and ranging beacons.

    - parameter callback: Returns result of starting the sensor as a boolean.
    */
    public func start(callback:(NSError!)->()) {
        _piAdapter.getAllBeaconRegions({regions, error in
            
            guard error == nil else {
                callback(error)
                return
            }
            
            if regions.count > 0 {
                for r in regions {
                    if let uuid = NSUUID(UUIDString: r) {
                        let region = CLBeaconRegion(proximityUUID: uuid, identifier: r)
                        self.startForRegion(region)
                    } else {
                        self._piAdapter.printDebug("Failed to create region: \(r)")
                    }
                }
            } else {
                self._piAdapter.printDebug("No Regions to monitor.")
            }
            callback(nil)
        })
    }
    
    /**
    Convenience function to start sensing and ranging beacons.
    
    - parameter callback: Returns result of starting the sensor as a boolean.
    */
    public func start() {
        start({error in
            self._piAdapter.printDebug("Failed to start beacon sensing: \(error)")
        })
    }
    
    /**
    Public function to stop beacon sensing and ranging.
    */
    public func stop() {
        if _monitoredRegions.count > 0 {
            for region in _monitoredRegions {
                self._locationManager.stopMonitoringForRegion(region)
                self._locationManager.stopRangingBeaconsInRegion(region)
            }
            self._monitoredRegions = []
            _piAdapter.printDebug("Stopped monitoring regions.")
        }
    }
    
    /**
    Public function to start sensing and ranging beacons in a specific region.
    
    - parameter region: The region to look for.
    */
    public func startForRegion(region: CLBeaconRegion) {
        
        region.notifyEntryStateOnDisplay = true

        self._locationManager.startMonitoringForRegion(region)
        self._locationManager.startRangingBeaconsInRegion(region)
        self._monitoredRegions.append(region)
        
    }
    
    /**
    Public function to set the frequency to report to PI.
    
    - parameter interval: The time interval between sending a beacon payload to PI. (milliseconds)
    */
    public func setReportInterval(interval: NSTimeInterval) {
        PI_REPORT_INTERVAL = interval
    }
    
    /**
    Private function to convert a CLProximity to a String.
    
    - parameter proximity: CLProximity to convert.
    
    - returns: String value of CLProximity.
    */
    private func proximityToString(proximity: CLProximity) -> String {
        switch (proximity) {
        case CLProximity.Far:
            return "Far"
        case CLProximity.Immediate:
            return "Immediate"
        case CLProximity.Near:
            return "Near"
        case CLProximity.Unknown:
            return "Unknown"
        }
    }
    
    /**
    Private function to convert an NSDate to an ISO8601 time string.
    
    - parameter detectedTime: NSDate to convert.
    
    - returns: ISO8601 formatted time string.
    */
    private func timeAsISO8601String(detectedTime: NSDate) -> String {
        let dateFormatter = NSDateFormatter()
        let enUSPOSIXLocale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.locale = enUSPOSIXLocale
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        
        return dateFormatter.stringFromDate(detectedTime)
    }
    
    /**
    Private function to append the detected time to the beacon that was detected.
    
    - parameter beacon:       The detected beacon.
    - parameter detectedTime: The time the beacon was detected.
    
    - returns: Dictionary of containing both the beacon data and the detected time.
    */
    private func createDictionaryWith(beacon: CLBeacon, detectedTime: NSDate) -> [String: AnyObject] {
        var dictionary = [String: AnyObject]()
        dictionary["descriptor"] = UIDevice.currentDevice().identifierForVendor?.UUIDString.lowercaseString
        dictionary["detectedTime"] = timeAsISO8601String(detectedTime)
        
        var data = [String: AnyObject]()
        
        data["rssi"] = beacon.rssi
        data["accuracy"] = beacon.accuracy
        data["proximityUUID"] = beacon.proximityUUID.UUIDString.lowercaseString
        data["major"] = beacon.major.stringValue
        data["minor"] = beacon.minor.stringValue
        data["proximity"] = proximityToString(beacon.proximity)
        
        dictionary["data"] = data
        
        return dictionary
    }
    
}

// MARK: - CLLocationManagerDelegate functions
extension PIBeaconSensor: CLLocationManagerDelegate {
    
    public func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        _piAdapter.printDebug("Did Enter Region: " + region.description)
        if let d = delegate {
            d.didEnterRegion(region)
        }
    }
    
    public func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        _piAdapter.printDebug("Did Exit Region: " + region.description)
        if let d = delegate {
            d.didExitRegion(region)
        }
    }
    
    public func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        _piAdapter.printDebug("Did Range Beacons In Region: " + region.description)
        
        let detectedTime = NSDate()
        let lastReport: NSTimeInterval!
        if (_lastDetected != nil) {
            lastReport = detectedTime.timeIntervalSinceDate(_lastDetected)
        } else {
            lastReport = PI_REPORT_INTERVAL + 1
        }
        
        if lastReport > PI_REPORT_INTERVAL {
            _lastDetected = detectedTime
            var beaconData: [[String: AnyObject]] = []
            for beacon in beacons {
                beaconData.append(self.createDictionaryWith(beacon, detectedTime: detectedTime))
            }
            _piAdapter.sendBeaconPayload(beaconData)
        }
        
        if let d = delegate {
            d.didRangeBeacons(beacons)
        }
        
    }
    
    public func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        if let r = region as? CLBeaconRegion {
            _piAdapter.printDebug("Started monitoring region: " + r.proximityUUID.UUIDString)
        }
    }
    
    public func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        if let r = region as? CLBeaconRegion {
            _piAdapter.printDebug("Failed to monitor for region: " + r.proximityUUID.UUIDString + " Error: \(error)")
        }
    }
    
    public func locationManager(manager: CLLocationManager, rangingBeaconsDidFailForRegion region: CLBeaconRegion, withError error: NSError) {
        _piAdapter.printDebug("Failed to range beacons in region: " + region.proximityUUID.UUIDString + " Error: \(error)")
    }
    
    public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        _piAdapter.printDebug("Location Manager failed with error: \(error)")
    }
    
}