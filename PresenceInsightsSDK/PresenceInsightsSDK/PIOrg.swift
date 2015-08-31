/**
*   PresenceInsightsSDK
*   PIZone.swift
*
*   Object to contain all zone information.
*
*   Copyright (c) 2015 IBM Corporation. All rights reserved.
*
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*
*   http://www.apache.org/licenses/LICENSE-2.0
*
*   Unless required by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
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
