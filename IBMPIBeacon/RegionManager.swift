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
    private let REGION_IDENTIFIER_PREPEND = "com.ibm.pi" // com.ibm.pi;uuid;major;minor

    private let _locationManager: CLLocationManager
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
            let components = region.identifier.componentsSeparatedByString(";")
            // PREPEND + UUID
            if components.count == 2 {
                _uuidRegions.append(createBeaconRegionFromCLRegion(region))
            } else {
                // this will be a uuid region
                _beaconRegions.append(createBeaconRegionFromCLRegion(region))
            }
        }
    }

    func start() {
        // we are only interested in beacons, so this accuracy will not require Wifi or GPS, which will save battery
        _locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers

        _locationManager.startUpdatingLocation()
    }

    func stop() {
        removeAllRegions()
        _locationManager.stopUpdatingLocation()
    }

    // current implementation will only take the first uuid region in the array
    func addUuidRegions(uuids: [String]) {
        guard let uuidString = uuids.first else {
            return
        }
        if let uuid = NSUUID(UUIDString: uuidString) {
            let region = CLBeaconRegion(proximityUUID: uuid,
                                        identifier: "\(REGION_IDENTIFIER_PREPEND);\(uuidString)")

            // will notify state of uuid region whenever the user turns on the screen of their device
            region.notifyEntryStateOnDisplay = true

            self._locationManager.startMonitoringForRegion(region)
            self._uuidRegions.append(region)
        }
    }
    
    func addBeaconRegions(beacons: [CLBeacon]) {
        for b in beacons {
            addBeaconRegion(b)
        }
    }
    
    func addBeaconRegion(beacon: CLBeacon) {
        let beaconIdentifier = "\(REGION_IDENTIFIER_PREPEND);\(beacon.proximityUUID.UUIDString);\(beacon.major);\(beacon.minor)"
        let filteredRegions = _beaconRegions.filter({$0.identifier == beaconIdentifier})

        // check to see if beacon already exists
        guard filteredRegions.count == 0 else {
            return
        }

        let region = CLBeaconRegion(proximityUUID: beacon.proximityUUID,
                                    major: beacon.major.unsignedShortValue,
                                    minor: beacon.minor.unsignedShortValue,
                                    identifier: beaconIdentifier)

        if _numRegions >= _maxRegions {
            let removedRegion = _beaconRegions.removeLast()
            _locationManager.stopMonitoringForRegion(removedRegion)
        }

        _beaconRegions.append(region)
        _locationManager.startMonitoringForRegion(region)
    }
    
    func didEnterRegion(region: CLBeaconRegion) {
        for uuidRegion in _uuidRegions {
            if uuidRegion.identifier.lowercaseString == region.identifier.lowercaseString {
                _locationManager.startRangingBeaconsInRegion(uuidRegion)
                break
            }
        }
    }
    
    func didDetermineState(state: CLRegionState, region: CLRegion) {
        if let region_ = region as? CLBeaconRegion where state.rawValue == CLRegionState.Inside.rawValue {
            // TODO only care if it is the uuid region
            didEnterRegion(region_)
        }
    }

    func didExitRegion(region: CLBeaconRegion){
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
        for region in self._locationManager.rangedRegions {
            let components = region.identifier.componentsSeparatedByString(";")
            let beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: components[1])!, identifier: region.identifier)
            _locationManager.stopRangingBeaconsInRegion(beaconRegion)
        }

        // stop monitoring
        for case let region as CLBeaconRegion in self._locationManager.monitoredRegions {
            _locationManager.stopMonitoringForRegion(region)
        }

        // clear region arrays
        _uuidRegions = []
        _beaconRegions = []
    }
    
    func createBeaconRegionFromCLRegion(region: CLRegion) -> CLBeaconRegion {
        let components = region.identifier.componentsSeparatedByString(";")
        var beaconRegion: CLBeaconRegion
        
        if (components.count > 2) {
            beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: components[1])!,
                                          major: CUnsignedShort(components[2])!,
                                          minor: CUnsignedShort(components[3])!,
                                          identifier: region.identifier)
        } else {
            beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: components[1])!,
                                          identifier: region.identifier)
        }
        return beaconRegion
    }
}
