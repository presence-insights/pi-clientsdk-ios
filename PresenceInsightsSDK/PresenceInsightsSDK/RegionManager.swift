//
//  RegionManager.swift
//  PresenceInsightsSDK
//
//  Created by Ciaran Hannigan on 11/2/15.
//  Copyright © 2015 IBM MIL. All rights reserved.
//

import Foundation
import CoreLocation

internal class RegionManager {
    private var _locationManager: CLLocationManager = CLLocationManager()
    private var _beaconRegions: [CLBeaconRegion] = []
    private var _uuidRegions: [CLBeaconRegion] = []
    private var _maxRegions: Int = 10
    private var _numRegions: Int {
        get {
            return _beaconRegions.count + _uuidRegions.count
        }
    }
    private var _didFindUuidRegion: Bool = false
    
    init() {
    }
    
    func addUuidRegions(uuids: [String]) {
        for u in uuids {
            if let uuid = NSUUID(UUIDString: u) {
                let region = CLBeaconRegion(proximityUUID: uuid, identifier: u)
                self._locationManager.startRangingBeaconsInRegion(region)
                self._uuidRegions.append(region)
            } else {
                //self._piAdapter.printDebug("Failed to create region: \(r)")
            }
        }
    }
    
    func addBeaconRegions(beacons: [CLBeacon]) {
        for b in beacons {
            addBeaconRegion(b)
        }
    }
    
    func addBeaconRegion(beacon: CLBeacon) {
        let region = CLBeaconRegion(proximityUUID: beacon.proximityUUID, major: beacon.major.unsignedShortValue, minor: beacon.minor.unsignedShortValue, identifier: String(format: "%@%@", beacon.major, beacon.minor))
        if _numRegions >= _maxRegions {
            let removedRegion = _beaconRegions.removeLast()
            _locationManager.stopMonitoringForRegion(removedRegion)
        }
        _beaconRegions.append(region)
        _locationManager.startMonitoringForRegion(region)
    }
    
    // we found the region that the beacons belong to
    // lets remove all other uuid regions
    func didRangeInRegion(region: CLBeaconRegion) {
        if !_didFindUuidRegion {
            for uuidRegion in _uuidRegions {
                if region != uuidRegion {
                    self.removeUuidRegion(uuidRegion)
                }
            }
            _didFindUuidRegion = true
        }
    }
    
    func removeBeaconRegion(region: CLBeaconRegion) {
        _locationManager.stopMonitoringForRegion(region)
        removeFromArray(_beaconRegions, obj: region)
    }
    
    func removeUuidRegion(region: CLBeaconRegion) {
        _locationManager.stopRangingBeaconsInRegion(region)
        removeFromArray(_uuidRegions, obj: region)
    }
    
    func removeFromArray(var array: [CLBeaconRegion], obj: CLBeaconRegion) {
        let index = array.indexOf(obj)
        guard index == nil else {
            return
        }
        array.removeAtIndex(index!)
    }
    
    func removeAllRegions() {
        // stop ranging in uuid regions
        for region in _uuidRegions {
            self._locationManager.stopRangingBeaconsInRegion(region)
        }
        _uuidRegions = []
        // stop monitoring in beacon regions
        for region in _beaconRegions {
            self._locationManager.stopMonitoringForRegion(region)
        }
        _beaconRegions = []
    }
    
}