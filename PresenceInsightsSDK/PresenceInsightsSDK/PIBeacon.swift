/**
*   PresenceInsightsSDK
*   PIBeacon.swift
*
*   Object to contain all beacon information.
*
*   Created by Kyle Craig on 7/16/15.
*   Copyright (c) 2015 IBM Corporation. All rights reserved.
**/

import UIKit
import CoreLocation

public class PIBeacon: NSObject {
    
    // Defined Values
    let JSON_NAME_KEY = "name"
    let JSON_DESCRIPTION_KEY = "description"
    let JSON_UUID_KEY = "proximityUUID"
    let JSON_MAJOR_KEY = "major"
    let JSON_MINOR_KEY = "minor"
    let JSON_X_KEY = "x"
    let JSON_Y_KEY = "y"
    let JSON_SITE_KEY = "@site"
    let JSON_FLOOR_KEY = "@floor"
    
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
    
    public convenience init(name: String, description: String, beacon: CLBeacon) {
        let proximityUUID = beacon.proximityUUID
        let major = beacon.major.stringValue
        let minor = beacon.minor.stringValue
        
        self.init(name: name, description: description, proximityUUID: proximityUUID, major: major, minor: minor)
    }
    
    public convenience init(dictionary: [String: AnyObject]) {
        
        // I prefer this method because if the dictionary isn't built correctly it will at least throw a nil error at runtime.
        self.init(name: "", description: "", proximityUUID: NSUUID(), major: "", minor: "")
        
        self.name = dictionary[JSON_NAME_KEY] as! String
        if let beaconDescription = dictionary[JSON_DESCRIPTION_KEY] as? String {
            self.beaconDescription = beaconDescription;
        }
        if let uuid = NSUUID(UUIDString: dictionary[JSON_UUID_KEY] as! String) {
            self.proximityUUID = uuid
        }
        self.major = dictionary[JSON_MAJOR_KEY] as! String
        self.minor = dictionary[JSON_MINOR_KEY] as! String
        self.x = dictionary[JSON_X_KEY] as! CGFloat
        self.y = dictionary[JSON_Y_KEY] as! CGFloat
        self.site = dictionary[JSON_SITE_KEY] as! String
        self.floor = dictionary[JSON_FLOOR_KEY] as! String
        
        // This is a way to do it with nil checking, but it won't throw an error and will still init (just empty not nil).
        /**
        if let name = dictionary["name"] as? String,
        let description = dictionary["description"] as? String,
        let proximityUUID = dictionary["proximityUUID"] as? String,
        let major = dictionary["major"] as? UInt,
        let minor = dictionary["minor"] as? UInt {
        
        self.init(name: name, description: description, proximityUUID: proximityUUID, major: major, minor: minor)
        
        }
        
        self.init(name: "", description: "", proximityUUID: "", major: 0, minor: 0)
        */
    }
    
    public func toDictionary() -> [String: AnyObject] {
        
        var dictionary: [String: AnyObject] = [:]
        
        dictionary[JSON_NAME_KEY] = name
        dictionary[JSON_DESCRIPTION_KEY] = description
        dictionary[JSON_UUID_KEY] = proximityUUID
        dictionary[JSON_MAJOR_KEY] = major
        dictionary[JSON_MINOR_KEY] = minor
        dictionary[JSON_X_KEY] = x
        dictionary[JSON_Y_KEY] = y
        dictionary[JSON_SITE_KEY] = site
        dictionary[JSON_FLOOR_KEY] = floor
        
        return dictionary
        
    }
    
}
