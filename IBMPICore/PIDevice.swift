/**
*  PresenceInsightsSDK
*  PIDevice.swift
*
*  Object to contain all device information.
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

// MARK: - PIDevice object
public class PIDevice:NSObject {
    
    // Every device document
    /// The unique identifier of the device object.
    public let descriptor: String?
    /// The unique identifier automatically generated when the device document is first created.
    public let code: String?
    /// Is this a registered device?
    public var registered: Bool
    
    // Optional values only registered devices have.
    /// The name of the device
    public var name: String?
    /// The type of device (list of types can be found in PIOrg)
    public var type: String?
    /// The encrypted data of the device (personal information)
    public var data: [String: AnyObject]?
    /// The unencrypted data of the device (non-personal information)
    public var unencryptedData: [String: AnyObject]?
    /// Should this device be ignored by analytics?
    public var blacklist: Bool?
    
    /**
     Initializer for a registered device object.

     - parameter name:          Device name
     - parameter type:          Device registration type

     - returns: An initialized PIDevice.
     */
    public init(name: String?, type: String?) {
        
        self.name = name
        self.type = type
        self.data = nil
        self.unencryptedData = nil
        
        self.registered = true
        self.blacklist = false
        self.descriptor = UIDevice.currentDevice().identifierForVendor?.UUIDString
        self.code = nil
    }
    
    /**
     Initializer for a registered device object with custom descriptor.

     - parameter name:          Device name
     - parameter type:          Device registration type
     - parameter descriptor:    Device descriptor used to uniquely identify device

     - returns: An initialized PIDevice.
     */
    public init(name: String?, type: String?, descriptor: String?) {

        self.name = name
        self.type = type
        self.data = nil
        self.unencryptedData = nil

        self.registered = true
        self.blacklist = false
        self.descriptor = descriptor
        self.code = nil
    }

    /**
     Initializer for an anonymous device object.

     - returns: An initialized PIDevice.
     */
    public override init() {
        self.name = nil
        self.type = nil
        self.data = nil
        self.unencryptedData = nil

        self.registered = false
        self.blacklist = false
        self.descriptor = UIDevice.currentDevice().identifierForVendor?.UUIDString
        self.code = nil
    }

    /**
     Initializer for an anonymous device object with custom descriptor.

     - parameter descriptor:    Device descriptor used to uniquely identify device

     - returns: An initialized PIDevice.
     */
    public init(descriptor: String?) {
        self.registered = false
        self.blacklist = false
        self.descriptor = descriptor

        self.name = nil
        self.type = nil
        self.data = nil
        self.unencryptedData = nil
        self.code = nil
    }

    /**
     Initializer for a device object.

     - parameter name:            Device name
     - parameter type:            Device registration type
     - parameter data:            Data about device (encrypted)
     - parameter unencryptedData: Data about device (unencrytped)
     - parameter registered:      Device registered with PI
     */
    @available(*, deprecated=1.3.0, message="Created new constructors for registered and anonymous devices to simplify the use of PIDevice.")
    public init(name: String?, type: String?, data: [String: String]?, unencryptedData: [String: String]?, registered: Bool, blacklist: Bool) {

        self.name = name
        self.type = type
        self.data = data
        self.unencryptedData = unencryptedData

        self.registered = registered
        self.blacklist = blacklist
        self.descriptor = UIDevice.currentDevice().identifierForVendor?.UUIDString
        self.code = nil
    }
    
    /**
     Convenience initializer which sets the device name, and sets defaults for the remaining properties.

     - parameter name: Device name

     - returns: An initialized PIDevice.
     */
    @available(*, deprecated=1.3.0, message="Created new constructors for registered and anonymous devices to simplify the use of PIDevice.")
    public init(name: String) {
        self.name = name
        self.type = nil
        self.data = nil
        self.unencryptedData = nil
        
        self.registered = false
        self.blacklist = nil
        self.descriptor = nil
        self.code = nil
    }
    
    /**
     Convenience initializer that uses a dictionary to populate the objects properties.

     - parameter dictionary: PIDevice represented as a dictionary

     - returns: An initialized PIDevice.
     */
    public init(dictionary: [String: AnyObject]) {
        
        self.descriptor = UIDevice.currentDevice().identifierForVendor?.UUIDString
        
        self.name = dictionary[Device.JSON_NAME_KEY] as? String
        
        self.type =  dictionary[Device.JSON_TYPE_KEY] as? String
        
        self.data = dictionary[Device.JSON_DATA_KEY] as? [String: String]
        
        self.unencryptedData = dictionary[Device.JSON_UNENCRYPTED_DATA_KEY] as? [String: String]
        
        self.blacklist = dictionary[Device.JSON_BLACKLIST_KEY] as? Bool
        
        self.registered = dictionary[Device.JSON_REGISTERED_KEY] as? Bool ?? false
        
        self.code = dictionary[Device.JSON_CODE_KEY] as? String
        
    }
    
    /**
     Adds key/value pair to the data dictionary.

     - parameter object:   Object to be stored
     - parameter key:      Key to use to store object
     */
    public func addToDataObject(object: AnyObject, key: String) {
        if data == nil {
            data = [:]
        }
        
        data?[key] = object
    }
    
    /**
     Adds key/value pair to the unencryptedData dictionary.

     - parameter object:   Object to be stored
     - parameter key:      Key to use to store object
    */
    public func addToUnencryptedDataObject(object: AnyObject, key: String) {
        if unencryptedData == nil {
            unencryptedData = [:]
        }
        unencryptedData?[key] = object
    }
    
    /**
     Helper function that provides the PIDevice object as a dictionary

     - returns: dictionary representation of PIDevice
     */
    public func toDictionary() -> [String: AnyObject] {
        
        var dictionary: [String: AnyObject] = [:]
        
        dictionary[Device.JSON_DESCRIPTOR_KEY] = descriptor
        dictionary[Device.JSON_REGISTERED_KEY] = registered
        dictionary[Device.JSON_BLACKLIST_KEY] = blacklist
        
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