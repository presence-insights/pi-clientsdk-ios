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
public class PIOrg:NSObject {
    
    // Org properties
    public let code: String?
    public let name: String?
    public let piDescription: String?
    public let registrationTypes: [String]?
    public let publicKey: String?
    
    /**
    Default object initializer.

    - parameter name:                Org name
    - parameter description:         Org description
    - parameter registrationTypes:   List of the organizations registration types
    - parameter publicKey:           public key used by the organization
   */
    public init(name: String, description: String, registrationTypes: [String], publicKey: String) {
        self.code = nil
        self.name = name
        self.piDescription = description
        self.registrationTypes = registrationTypes
        self.publicKey = publicKey
    }
    
    /**
    Convenience initializer to init an empty Object.
    
    - returns: An initialized PIOrg.
    */
    public override init() {
        self.code = nil
        self.name = nil
        self.piDescription = nil
        self.registrationTypes = nil
        self.publicKey = nil
    }
    
    /**
    Convenience initializer that uses a dictionary to populate the objects properties.

    - parameter dictionary: PIOrg represented as a dictionary

    - returns: An initialized PIOrg.
    */
    public init(dictionary: [String: AnyObject]) {
        self.code = dictionary[Org.JSON_CODE_KEY] as? String
        self.name = dictionary[Org.JSON_NAME_KEY] as? String
        self.piDescription = dictionary[Beacon.JSON_DESCRIPTION_KEY] as? String
        self.registrationTypes = dictionary[Org.JSON_REGISTRATION_TYPES_KEY] as? [String]
        self.publicKey = dictionary[Org.JSON_PUBLIC_KEY_KEY] as? String
        
    }
    
    /**
    Helper function that provides the PIOrg object as a dictionary

    - returns: a dictionary representation of PIOrg
    */
    public func toDictionary() -> [String: AnyObject] {
        
        var dictionary: [String: AnyObject] = [:]
        
        if let code = code {
            dictionary[Org.JSON_CODE_KEY] = code
        }
        if let name = name {
            dictionary[Org.JSON_NAME_KEY] = name
        }
        if let piDescription = piDescription {
            dictionary[Org.JSON_DESCRIPTION_KEY] = piDescription
        }
        if let registrationTypes = registrationTypes {
            dictionary[Org.JSON_REGISTRATION_TYPES_KEY] = registrationTypes
        }
        if let publicKey = publicKey {
            dictionary[Org.JSON_PUBLIC_KEY_KEY] = publicKey
        }
        
        return dictionary
        
    }
   
}
