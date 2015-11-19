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
    private var _locationManager: CLLocationManager
    private var _beaconRegions: [CLBeaconRegion] = []
    private var _uuidRegions: [CLBeaconRegion] = []
    private var _maxRegions: Int = 20
    private var _numRegions: Int {
        get {
            return _beaconRegions.count + _uuidRegions.count
        }
    }
    
    init(locationManager: CLLocationManager) {
        print("Initializing RegionManger...")
        _locationManager = locationManager

        let regions = _locationManager.monitoredRegions
        for region: CLRegion in regions {
            print("monitored region: " + region.identifier)
            if NSUUID(UUIDString: region.identifier) == nil {
                _beaconRegions.append(createBeaconRegionFromCLRegion(region))
            } else {
                // this will be a uuid region
                _uuidRegions.append(createBeaconRegionFromCLRegion(region))
            }
        }
    }

    func start() {
        // to enable ranging in the background for iOS 9
        if #available(iOS 9, *) {
            _locationManager.allowsBackgroundLocationUpdates = true
        }
        _locationManager.startUpdatingLocation()
        // we are only interested in beacons, so this accuracy will not require Wifi or GPS, which will save battery
        _locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    func stop() {
        removeAllRegions()
        _locationManager.stopUpdatingLocation()
    }

    func addUuidRegions(uuids: [String]) {
        for u in uuids {
            if let uuid = NSUUID(UUIDString: u) {
                let region = CLBeaconRegion(proximityUUID: uuid, identifier: u)
                
                // will notify state of uuid region whenever the user turns on the screen of their device
                region.notifyEntryStateOnDisplay = true
                
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
        let region = CLBeaconRegion(proximityUUID: beacon.proximityUUID, major: beacon.major.unsignedShortValue, minor: beacon.minor.unsignedShortValue, identifier: "\(beacon.proximityUUID.UUIDString);\(beacon.major);\(beacon.minor)")
        if _numRegions >= _maxRegions {
            let removedRegion = _beaconRegions.removeLast()
            _locationManager.stopMonitoringForRegion(removedRegion)
        }
        _beaconRegions.append(region)
        _locationManager.startMonitoringForRegion(region)
    }
    
    func didEnterRegion(region: CLRegion) {
        print("didEnterRegion of RegionManager with Region: " + region.identifier)
        for uuidRegion in _uuidRegions {
            if uuidRegion.identifier.lowercaseString == region.identifier.lowercaseString {
                print("found a matching uuid region! lets start ranging!")
                _locationManager.startRangingBeaconsInRegion(uuidRegion)
                break
            }
        }
    }
    
    func didDetermineState(state: CLRegionState, region: CLRegion) {
        print("did determine state of region " + region.identifier)
        print("we are " + (state.rawValue == CLRegionState.Inside.rawValue ? "Inside" : "Outside") + " that region")
        if state.rawValue == CLRegionState.Inside.rawValue {
            didEnterRegion(region)
        }
    }

    func didExitRegion(region: CLRegion){
        print("did exit region")
        for uuidRegion in _uuidRegions {
            if uuidRegion.identifier.lowercaseString == region.identifier.lowercaseString {
                print("found a matching uuid region! lets start ranging!")
                _locationManager.stopRangingBeaconsInRegion(uuidRegion)
                for beaconRegion in _beaconRegions {
                    _locationManager.stopMonitoringForRegion(beaconRegion)
                }
                _beaconRegions = []
                break
            }
        }
    }
    
    func removeAllRegions() {
        // stop ranging
        for region: CLRegion in self._locationManager.rangedRegions {
            let beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: region.identifier)!, identifier: region.identifier)
            _locationManager.stopRangingBeaconsInRegion(beaconRegion)
        }

        // stop monitoring
        for region: CLRegion in self._locationManager.monitoredRegions {
            _locationManager.stopMonitoringForRegion(region)
        }

        // clear region arrays
        _uuidRegions = []
        _beaconRegions = []
    }
    
    func createBeaconRegionFromCLRegion(region: CLRegion) -> CLBeaconRegion {
        let components = region.identifier.componentsSeparatedByString(";")
        var beaconRegion: CLBeaconRegion
        
        print("components of region id: \(components)")
        // beacon region (id = uuid;major;minor)
        if (components.count > 1) {
            beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: components[0])!, major: CUnsignedShort(components[1])!, minor: CUnsignedShort(components[2])!, identifier: region.identifier)
        } else {
            beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: components[0])!, identifier: region.identifier)
        }
        return beaconRegion
    }
}
