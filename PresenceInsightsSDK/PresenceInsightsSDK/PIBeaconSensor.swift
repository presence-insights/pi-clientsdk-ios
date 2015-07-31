//
//  PIBeaconSensor.swift
//  PresenceInsightsSDK
//
//  Created by Kyle Craig on 7/16/15.
//  Copyright (c) 2015 IBM MIL. All rights reserved.
//

import UIKit
import CoreLocation

public protocol PIBeaconSensorDelegate {
    func didRangeBeacons(beacons:[CLBeacon])
}

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
        
    }
    
    public func start() {
        _piAdapter.getAllBeaconRegions({regions in
            
            if regions.count > 0 {
                for r in regions {
                    let region = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: r), identifier: r)
                    self.startForRegion(region)
                }
            } else {
                self._piAdapter.printDebug("No Regions to monitor.")
            }
            
        })
    }
    
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
    
    public func startForRegion(region: CLBeaconRegion) {
        
        self._locationManager.startMonitoringForRegion(region)
        self._locationManager.startRangingBeaconsInRegion(region)
        self._monitoredRegions.append(region)
        
    }
    
    public func setReportInterval(interval: NSTimeInterval) {
        PI_REPORT_INTERVAL = interval
    }
    
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
        default:
            return ""
        }
    }
    
    private func timeAsISO8601String(detectedTime: NSDate) -> String {
        var dateFormatter = NSDateFormatter()
        var enUSPOSIXLocale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.locale = enUSPOSIXLocale
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        
        return dateFormatter.stringFromDate(detectedTime)
    }
    
    private func createDictionaryWith(beacon: CLBeacon, detectedTime: NSDate) -> NSDictionary {
        var dictionary = NSMutableDictionary()
        dictionary.setObject(UIDevice.currentDevice().identifierForVendor.UUIDString.lowercaseString, forKey: "descriptor")
        dictionary.setObject(timeAsISO8601String(detectedTime), forKey: "detectedTime")
        
        var data = NSMutableDictionary()
        
        data.setObject( beacon.rssi, forKey:"rssi")
        data.setObject( beacon.accuracy, forKey:"accuracy")
        data.setObject( beacon.proximityUUID.UUIDString.lowercaseString, forKey:"proximityUUID")
        data.setObject( beacon.major.stringValue, forKey:"major")
        data.setObject( beacon.minor.stringValue, forKey:"minor")
        data.setObject( proximityToString(beacon.proximity),  forKey:"proximity")
        
        dictionary.setObject(data, forKey:"data")
        
        return dictionary
    }
    
}

extension PIBeaconSensor: CLLocationManagerDelegate {
    
    public func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        _piAdapter.printDebug("Did Enter Region: " + region.description)
        
    }
    
    public func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        _piAdapter.printDebug("Did Exit Region: " + region.description)
        
    }
    
    public func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
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
            var beaconData: [NSDictionary] = []
            for beacon in beacons as! [CLBeacon] {
                beaconData.append(self.createDictionaryWith(beacon, detectedTime: detectedTime))
            }
            _piAdapter.sendBeaconPayload(NSArray(array: beaconData))
        }
        
        if let d = delegate {
            d.didRangeBeacons(beacons as! [CLBeacon])
        }
        
    }
    
    public func locationManager(manager: CLLocationManager!, didStartMonitoringForRegion region: CLRegion!) {
        if let r = region as? CLBeaconRegion {
            _piAdapter.printDebug("Started monitoring region: " + r.proximityUUID.UUIDString)
        }
    }
    
    public func locationManager(manager: CLLocationManager!, monitoringDidFailForRegion region: CLRegion!, withError error: NSError!) {
        if let r = region as? CLBeaconRegion {
            _piAdapter.printDebug("Failed to monitor for region: " + r.proximityUUID.UUIDString + " Error: \(error)")
        }
    }
    
    public func locationManager(manager: CLLocationManager!, rangingBeaconsDidFailForRegion region: CLBeaconRegion!, withError error: NSError!) {
        _piAdapter.printDebug("Failed to range beacons in region: " + region.proximityUUID.UUIDString + " Error: \(error)")
    }
    
    public func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        _piAdapter.printDebug("Location Manager failed with error: \(error)")
    }
    
}