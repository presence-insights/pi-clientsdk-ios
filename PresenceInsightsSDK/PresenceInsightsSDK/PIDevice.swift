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
    
    // Defined Values
    let JSON_NAME_KEY = "name"
    let JSON_TYPE_KEY = "registrationType"
    let JSON_DESCRIPTOR_KEY = "descriptor"
    let JSON_REGISTERED_KEY = "registered"
    let JSON_CODE_KEY = "@code"
    let JSON_DATA_KEY = "data"
    let JSON_UNENCRYPTED_DATA_KEY = "unencryptedData"
    
    // Values every device has.
    private var _descriptor: String!
    private var _registered: Bool!
    
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
        
        _registered = registered
        _descriptor = UIDevice.currentDevice().identifierForVendor?.UUIDString
        
    }
    
    public convenience init(name: String) {
        self.init(name: name, type: String(), data: [:], unencryptedData: [:], registered: false)
    }
    
    public convenience init(dictionary: NSDictionary) {
        
        self.init(name: nil, type: nil, data: [:], unencryptedData: [:], registered: false)
        
        if let name = dictionary[JSON_NAME_KEY] as? String {
            self.name = name
        }
        if let type =  dictionary[JSON_TYPE_KEY] as? String {
            self.type = type;
        }
        if let dictionary = dictionary[JSON_DATA_KEY] as? [String: String] {
            self.data = dictionary
        }
        if let dictionary = dictionary[JSON_UNENCRYPTED_DATA_KEY] as? [String: String] {
            self.unencryptedData = dictionary
        }
        
        self._registered = dictionary[JSON_REGISTERED_KEY] as! Bool
        
        if let code = dictionary[JSON_CODE_KEY] as? String {
            self.setDeviceCode(code)
        }
        
    }
    
    public func setDataObject(object: String, key: String) {
        if data == nil {
            data![key] = object
        } else {
            data = [:]
            data![key] = object
        }
    }
    
    public func setUnencryptedDataObject(object: String, key: String) {
        if unencryptedData != nil {
            unencryptedData![key] = object
        } else {
            unencryptedData = [:]
            unencryptedData![key] = object
        }
    }
    
    public func setRegistered(registered: Bool) {
        _registered = registered
    }
    
    public func setRegistrationType(type: String) {
        self.type = type;
    }
    
    public func setDeviceCode(code: String) {
        self.code = code
    }
    
    public func getDescriptor() -> String {
        return _descriptor
    }
    
    public func isRegistered() -> Bool {
        return _registered
    }
    
    public func toDictionary() -> [String: AnyObject] {
        
        var dictionary: [String: AnyObject] = [:]
        
        dictionary[JSON_DESCRIPTOR_KEY] = _descriptor
        dictionary[JSON_REGISTERED_KEY] = _registered
        
        if let n = name {
            dictionary[JSON_NAME_KEY] = n
        }
        if let t = type {
            dictionary[JSON_TYPE_KEY] = t
        }
        if let d = data {
            dictionary[JSON_DATA_KEY] = d
        }
        if let uD = unencryptedData {
            dictionary[JSON_UNENCRYPTED_DATA_KEY] = uD
        }
        if let c = code {
            dictionary[JSON_CODE_KEY] = c
        }
        
        return dictionary
    }
    
}