/**
*  PresenceInsightsSDK
*  RegionManager.swift
*
*  Object to contain all zone information.
*
*  © Copyright 2015 IBM Corp.
*
*  Licensed under the Presence Insights Client iOS Framework License (the "License");
*  you may not use this file except in compliance with the License. You may find
*  a copy of the license in the license.txt file in this package.
*
*  Unless required by applicable law or agreed to in writing, software
*  distributed under the License is distributed on an "AS IS" BASIS,
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*  See the License for the specific language governing permissions and
*  limitations under the License.
**/

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
        _locationManager = locationManager

        let regions = _locationManager.monitoredRegions
        for region: CLRegion in regions {
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
        for uuidRegion in _uuidRegions {
            if uuidRegion.identifier.lowercaseString == region.identifier.lowercaseString {
                _locationManager.startRangingBeaconsInRegion(uuidRegion)
                break
            }
        }
    }
    
    func didDetermineState(state: CLRegionState, region: CLRegion) {
        if state.rawValue == CLRegionState.Inside.rawValue {
            didEnterRegion(region)
        }
    }

    func didExitRegion(region: CLRegion){
        for uuidRegion in _uuidRegions {
            if uuidRegion.identifier.lowercaseString == region.identifier.lowercaseString {
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
        
        // beacon region (id = uuid;major;minor)
        if (components.count > 1) {
            beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: components[0])!, major: CUnsignedShort(components[1])!, minor: CUnsignedShort(components[2])!, identifier: region.identifier)
        } else {
            beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: components[0])!, identifier: region.identifier)
        }
        return beaconRegion
    }
}
