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
    private var _maxRegions: Int = 20
    private var _numRegions: Int {
        get {
            return _beaconRegions.count + _uuidRegions.count
        }
    }
    private var _didFindUuidRegion: Bool = false
    
    init() {
        let regions = _locationManager.monitoredRegions
        for region: CLBeaconRegion in regions {
            if region.major == nil {
                // this will be a uuid region
                _uuidRegions.append(region)
            } else {
                _beaconRegions.append(region)
            }
        }
    }
    
    func addUuidRegions(uuids: [String]) {
        for u in uuids {
            if let uuid = NSUUID(UUIDString: u) {
                let region = CLBeaconRegion(proximityUUID: uuid, identifier: u)
                self._locationManager.startMonitoringForRegion(region)
                self._uuidRegions.append(region)
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
        // stop ranging
        for region: CLBeaconRegion in self._locationManager.rangedRegions {
            _locationManager.stopRangingBeaconsInRegion(region)
        }

        // stop monitoring
        for region: CLBeaconRegion in self._locationManager.monitoredRegions {
            _locationManager.stopMonitoringForRegion(region)
        }

        // clear region arrays
        _uuidRegions = []
        _beaconRegions = []
    }
    
}