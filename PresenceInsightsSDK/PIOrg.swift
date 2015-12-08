/**
*  PresenceInsightsSDK
*  PIOrg.swift
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

import UIKit

// MARK: - PIOrg object
public class PIOrg: NSObject {
    
    // Org properties
    public var name: String!
    public var piDescription: String!
    public var registrationTypes: [String]!
    public var publicKey: String!
    
    /**
    Default object initializer.

    - parameter name:                Org name
    - parameter description:         Org description
    - parameter registrationTypes:   List of the organizations registration types
    - parameter publicKey:           public key used by the organization
   */
    public init(name: String, description: String, registrationTypes: [String], publicKey: String) {
        self.name = name
        self.piDescription = description
        self.registrationTypes = registrationTypes
        self.publicKey = publicKey
    }
    
    /**
    Convenience initializer to init an empty Object.
    
    - returns: An initialized PIOrg.
    */
    public convenience override init() {
        self.init(name: "", description: "", registrationTypes: [], publicKey: "")
    }
    
    /**
    Convenience initializer that uses a dictionary to populate the objects properties.

    - parameter dictionary: PIOrg represented as a dictionary

    - returns: An initialized PIOrg.
    */
    public convenience init(dictionary: [String: AnyObject]) {
        
        self.init(name: "", description: "", registrationTypes: [], publicKey: "")
        
        self.name = dictionary[Org.JSON_NAME_KEY] as! String
        if let piDescription = dictionary[Beacon.JSON_DESCRIPTION_KEY] as? String {
            self.piDescription = piDescription;
        }
        self.registrationTypes = dictionary[Org.JSON_REGISTRATION_TYPES_KEY] as! [String]
        if let publicKey = dictionary[Org.JSON_PUBLIC_KEY_KEY] as? String {
            self.publicKey = publicKey
        } else {
            self.publicKey = ""
        }
        
    }
    
    /**
    Helper function that provides the PIOrg object as a dictionary

    - returns: a dictionary representation of PIOrg
    */
    public func toDictionary() -> [String: AnyObject] {
        
        var dictionary: [String: AnyObject] = [:]
        
        dictionary[Org.JSON_NAME_KEY] = name
        dictionary[Org.JSON_DESCRIPTION_KEY] = description
        dictionary[Org.JSON_REGISTRATION_TYPES_KEY] = registrationTypes
        dictionary[Org.JSON_PUBLIC_KEY_KEY] = publicKey
        
        return dictionary
        
    }
   
}
