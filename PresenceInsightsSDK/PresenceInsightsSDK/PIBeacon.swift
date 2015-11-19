/**
*  PresenceInsightsSDK
*  PIBeacon.swift
*
*  Object to contain all beacon information.
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

import UIKit
import CoreLocation

// MARK: - PIBeacon object
public class PIBeacon: NSObject {
    
    // Beacon properties
    public var name: String!
    public var beaconDescription: String!
    public var proximityUUID: NSUUID!
    public var major: String!
    public var minor: String!
    public var x: CGFloat!
    public var y: CGFloat!
    public var site: String!
    public var floor: String!
    
    /**
    Default object initializer.

    - parameter name:            Beacon name
    - parameter description:     Beacon description
    - parameter proximityUUID:   Universally unique identifier for the beacon
    - parameter major:           Unique identifier within the proximity UUID space
    - parameter minor:           Unique identifier within the major space
    */
    public init(name: String, description: String, proximityUUID: NSUUID, major: String, minor: String) {
        self.name = name
        self.beaconDescription = description
        self.proximityUUID = proximityUUID
        self.major = major
        self.minor = minor
        self.x = 0.0
        self.y = 0.0
        self.site = ""
        self.floor = ""
    }
    
    /**
    Convenience initializer to init an empty Object.
    
    - returns: An initialized PIBeacon.
    */
    public convenience override init() {
        self.init(name: "", description: "", proximityUUID: NSUUID(), major: "", minor: "")
    }
    
    /**
    Convenience initializer which sets the beacons name, description, and uses a CLBeacon object to populate the proximityUUID, major, and minor properties.

    - parameter name:        Beacon name
    - parameter description: Beacon description
    - parameter beacon:      CLBeacon object

    - returns: An initialized PIBeacon.
    */
    public convenience init(name: String, description: String, beacon: CLBeacon) {
        let proximityUUID = beacon.proximityUUID
        let major = beacon.major.stringValue
        let minor = beacon.minor.stringValue
        
        self.init(name: name, description: description, proximityUUID: proximityUUID, major: major, minor: minor)
    }
    
    /**
    Convenience initializer that uses a dictionary to populate the objects properties.

    - parameter dictionary: PIBeacon represented as a dictionary

    - returns: An initialized PIBeacon.
    */
    public convenience init(dictionary: [String: AnyObject]) {
        
        // I prefer this method because if the dictionary isn't built correctly it will at least throw a nil error at runtime.
        self.init(name: "", description: "", proximityUUID: NSUUID(), major: "", minor: "")
        
        // retrieve dictionaries from feature object
        let geometry = dictionary[GeoJSON.GEOMETRY_KEY] as! [String: AnyObject]
        let properties = dictionary[GeoJSON.PROPERTIES_KEY] as! [String: AnyObject]
        
        self.name = properties[Beacon.JSON_NAME_KEY] as! String
        if let beaconDescription = properties[Beacon.JSON_DESCRIPTION_KEY] as? String {
            self.beaconDescription = beaconDescription;
        }
        if let uuid = NSUUID(UUIDString: properties[Beacon.JSON_UUID_KEY] as! String) {
            self.proximityUUID = uuid
        }
        self.major = properties[Beacon.JSON_MAJOR_KEY] as! String
        self.minor = properties[Beacon.JSON_MINOR_KEY] as! String
        self.site = properties[Beacon.JSON_SITE_KEY] as! String
        self.floor = properties[Beacon.JSON_FLOOR_KEY] as! String
        
        let coords = geometry[GeoJSON.COORDINATES_KEY] as! [CGFloat]
        
        self.x = coords[0]
        self.y = coords[1]
    }
    
    /**
    Helper function that provides the PIBeacon object as a dictionary

    - returns: a dictionary representation of PIBeacon
    */
    public func toDictionary() -> [String: AnyObject] {
        
        var dictionary: [String: AnyObject] = [:]
        
        dictionary[Beacon.JSON_NAME_KEY] = name
        dictionary[Beacon.JSON_DESCRIPTION_KEY] = description
        dictionary[Beacon.JSON_UUID_KEY] = proximityUUID
        dictionary[Beacon.JSON_MAJOR_KEY] = major
        dictionary[Beacon.JSON_MINOR_KEY] = minor
        dictionary[Beacon.JSON_X_KEY] = x
        dictionary[Beacon.JSON_Y_KEY] = y
        dictionary[Beacon.JSON_SITE_KEY] = site
        dictionary[Beacon.JSON_FLOOR_KEY] = floor
        
        return dictionary
        
    }
    
}
