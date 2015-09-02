/**
*   PresenceInsightsSDK
*   PIDevice.swift
*
*   Object to contain all device information.
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

public class PIDevice: NSObject {
    
    // Values every device has.
    public var descriptor: String!
    public var registered: Bool = false
    
    // Optional values only registered devices have.
    public var code: String?
    public var name: String?
    public var type: String?
    public var data: [String: String]?
    public var unencryptedData: [String: String]?
    
    public init(name: String?, type: String?, data: [String: String]?, unencryptedData: [String: String]?, registered: Bool) {
        
        self.name = name
        self.type = type
        self.data = data
        self.unencryptedData = unencryptedData
        
        self.registered = registered
        self.descriptor = UIDevice.currentDevice().identifierForVendor?.UUIDString
        
    }
    
    public convenience init(name: String) {
        self.init(name: name, type: String(), data: [:], unencryptedData: [:], registered: false)
    }
    
    public convenience init(dictionary: NSDictionary) {
        
        self.init(name: nil, type: nil, data: [:], unencryptedData: [:], registered: false)
        
        if let name = dictionary[Device.JSON_NAME_KEY] as? String {
            self.name = name
        }
        if let type =  dictionary[Device.JSON_TYPE_KEY] as? String {
            self.type = type;
        }
        if let dictionary = dictionary[Device.JSON_DATA_KEY] as? [String: String] {
            self.data = dictionary
        }
        if let dictionary = dictionary[Device.JSON_UNENCRYPTED_DATA_KEY] as? [String: String] {
            self.unencryptedData = dictionary
        }
        
        self.registered = dictionary[Device.JSON_REGISTERED_KEY] as! Bool
        
        if let code = dictionary[Device.JSON_CODE_KEY] as? String {
            self.code = code
        }
        
    }
    
    public func addToDataObject(object: String, key: String) {
        if data == nil {
            data![key] = object
        } else {
            data = [:]
            data![key] = object
        }
    }
    
    public func addToUnencryptedDataObject(object: String, key: String) {
        if unencryptedData != nil {
            unencryptedData![key] = object
        } else {
            unencryptedData = [:]
            unencryptedData![key] = object
        }
    }
    
    public func toDictionary() -> [String: AnyObject] {
        
        var dictionary: [String: AnyObject] = [:]
        
        dictionary[Device.JSON_DESCRIPTOR_KEY] = descriptor
        dictionary[Device.JSON_REGISTERED_KEY] = registered
        
        if let n = name {
            dictionary[Device.JSON_NAME_KEY] = n
        }
        if let t = type {
            dictionary[Device.JSON_TYPE_KEY] = t
        }
        if let d = data {
            dictionary[Device.JSON_DATA_KEY] = d
        }
        if let uD = unencryptedData {
            dictionary[Device.JSON_UNENCRYPTED_DATA_KEY] = uD
        }
        if let c = code {
            dictionary[Device.JSON_CODE_KEY] = c
        }
        
        return dictionary
    }
    
}