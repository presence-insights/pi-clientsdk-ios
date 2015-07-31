//
//  PIDevice.swift
//  PresenceInsightsSDK
//
//  Created by Kyle Craig on 7/16/15.
//  Copyright (c) 2015 IBM MIL. All rights reserved.
//

import UIKit

public enum PIDeviceType: String {
    case Internal = "Internal"
    case External = "External"
}

public class PIDevice: NSObject {
    
    // Defined Values
    let JSON_NAME_KEY = "name"
    let JSON_TYPE_KEY = "registrationType"
    let JSON_DESCRIPTOR_KEY = "descriptor"
    let JSON_REGISTERED_KEY = "registered"
    let JSON_CODE_KEY = "@code"
    let JSON_DATA_KEY = "data"
    
    // Values every device has.
    private var _descriptor: String!
    private var _registered: Bool!
    
    // Optional values only registered devices have.
    public var code: String?
    public var name: String?
    public var type: PIDeviceType?
    public var data: NSMutableDictionary?
    
    public init(name: String?, type: PIDeviceType?, data: NSMutableDictionary?, registered: Bool) {
        
        self.name = name
        self.type = type
        self.data = data
        
        _registered = registered
        _descriptor = UIDevice.currentDevice().identifierForVendor?.UUIDString
        
        
    }
    
    public convenience init(name: String) {
        self.init(name: name, type: PIDeviceType.External, data: NSMutableDictionary(), registered: true)
    }
    
    public convenience init(dictionary: NSDictionary) {
        
        self.init(name: nil, type: nil, data: nil, registered: false)
        
        if let name = dictionary[JSON_NAME_KEY] as? String {
            self.name = name
        }
        if let type =  dictionary[JSON_TYPE_KEY] as? String {
            self.type = PIDeviceType(rawValue: type)
        }
        if let dictionary = dictionary[JSON_DATA_KEY] as? NSDictionary {
            self.data = NSMutableDictionary(dictionary: dictionary)
        }
        
        self._registered = dictionary[JSON_REGISTERED_KEY] as! Bool
        
        if let code = dictionary[JSON_CODE_KEY] as? String {
            self.setDeviceCode(code)
        }
        
    }
    
    public func setDataObject(object: String, key: String) {
        if let deviceData = data {
            deviceData.setObject(object, forKey: key)
        } else {
            data = NSMutableDictionary()
            data!.setObject(object, forKey: key)
        }
    }
    
    public func setRegistered(registered: Bool) {
        _registered = registered
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
    
    public func toDictionary() -> NSDictionary {
        
        let dictionary = NSMutableDictionary()
        
        dictionary.setObject(_descriptor, forKey: JSON_DESCRIPTOR_KEY)
        dictionary.setObject(_registered, forKey: JSON_REGISTERED_KEY)
        
        if let n = name {
            dictionary.setObject(n, forKey: JSON_NAME_KEY)
        }
        if let t = type?.rawValue {
            dictionary.setObject(t, forKey: JSON_TYPE_KEY)
        }
        if let d = data {
            dictionary.setObject(d, forKey: JSON_DATA_KEY)
        }
        if let c = code {
            dictionary.setObject(c, forKey: JSON_CODE_KEY)
        }
        
        return dictionary
    }
    
}