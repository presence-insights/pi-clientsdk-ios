//
//  PIBeacon.swift
//  PresenceInsightsSDK
//
//  Created by Kyle Craig on 7/16/15.
//  Copyright (c) 2015 IBM MIL. All rights reserved.
//

import UIKit
import CoreLocation

public class PIBeacon: NSObject {
    
    let JSON_NAME_KEY = "name"
    let JSON_DESCRIPTION_KEY = "description"
    let JSON_UUID_KEY = "proximityUUID"
    let JSON_MAJOR_KEY = "major"
    let JSON_MINOR_KEY = "minor"
    let JSON_X_KEY = "x"
    let JSON_Y_KEY = "y"
    let JSON_SITE_KEY = "@site"
    let JSON_FLOOR_KEY = "@floor"
    
    public var name: String!
    public var beaconDescription: String!
    public var proximityUUID: String!
    public var major: String!
    public var minor: String!
    
    public var x: CGFloat!
    public var y: CGFloat!
    public var site: String!
    public var floor: String!
    
    public init(name: String, description: String, proximityUUID: String, major: String, minor: String) {
        
        self.name = name
        self.beaconDescription = description
        self.proximityUUID = proximityUUID
        self.major = major
        self.minor = minor
        
    }
    
    public convenience init(name: String, description: String, beacon: CLBeacon) {
        
        let proximityUUID = beacon.proximityUUID.UUIDString
        let major = beacon.major.stringValue
        let minor = beacon.minor.stringValue
        
        self.init(name: name, description: description, proximityUUID: proximityUUID, major: major, minor: minor)
        
    }
    
    public convenience init(dictionary: NSDictionary) {
        
        // I prefer this method because if the dictionary isn't built correctly it will at least throw a nil error at runtime.
        
        self.init(name: "", description: "", proximityUUID: "", major: "", minor: "")
        
        self.name = dictionary[JSON_NAME_KEY] as! String
        self.beaconDescription = dictionary[JSON_DESCRIPTION_KEY] as! String
        self.proximityUUID = dictionary[JSON_UUID_KEY] as! String
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
    
    public func toDictionary() -> NSDictionary {
        
        let dictionary = NSMutableDictionary()
        
        dictionary.setObject(name, forKey: JSON_NAME_KEY)
        dictionary.setObject(beaconDescription, forKey: JSON_DESCRIPTION_KEY)
        dictionary.setObject(proximityUUID, forKey: JSON_UUID_KEY)
        dictionary.setObject(major, forKey: JSON_MAJOR_KEY)
        dictionary.setObject(minor, forKey: JSON_MINOR_KEY)
        
        dictionary.setObject(x, forKey: JSON_X_KEY)
        dictionary.setObject(y, forKey: JSON_Y_KEY)
        dictionary.setObject(site, forKey: JSON_SITE_KEY)
        dictionary.setObject(floor, forKey: JSON_FLOOR_KEY)
        
        return dictionary
        
    }
    
}
