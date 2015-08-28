/**
*   PresenceInsightsSDK
*   PIZone.swift
*
*   Object to contain all zone information.
*
*   Created by Kyle Craig on 8/5/15.
*   Copyright (c) 2015 IBM Corporation. All rights reserved.
**/

import UIKit

public class PIOrg: NSObject {
    
    // Defined Values
    let JSON_NAME_KEY = "name"
    let JSON_DESCRIPTION_KEY = "description"
    let JSON_REGISTRATION_TYPES_KEY = "registrationTypes"
    let JSON_PUBLIC_KEY_KEY = "publicKey"
    
    // Org properties
    public var name: String!
    public var piDescription: String!
    public var registrationTypes: [String]!
    public var publicKey: String!
    
    public init(name: String, description: String, registrationTypes: [String], publicKey: String) {
        self.name = name
        self.piDescription = description
        self.registrationTypes = registrationTypes
        self.publicKey = publicKey
    }
    
    public convenience init(dictionary: [String: AnyObject]) {
        
        self.init(name: "", description: "", registrationTypes: [], publicKey: "")
        
        self.name = dictionary[JSON_NAME_KEY] as! String
        self.piDescription = dictionary[JSON_DESCRIPTION_KEY] as! String
        self.registrationTypes = dictionary[JSON_REGISTRATION_TYPES_KEY] as! [String]
        if let publicKey = dictionary[JSON_PUBLIC_KEY_KEY] as? String {
            self.publicKey = publicKey
        } else {
            self.publicKey = ""
        }
        
    }
    
    public func toDictionary() -> [String: AnyObject] {
        
        var dictionary: [String: AnyObject] = [:]
        
        dictionary[JSON_NAME_KEY] = name
        dictionary[JSON_DESCRIPTION_KEY] = description
        dictionary[JSON_REGISTRATION_TYPES_KEY] = registrationTypes
        dictionary[JSON_PUBLIC_KEY_KEY] = publicKey
        
        return dictionary
        
    }
   
}
