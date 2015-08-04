//
//  PIAdapter.swift
//  PresenceInsightsSDK
//
//  Created by Kyle Craig on 7/16/15.
//  Copyright (c) 2015 IBM MIL. All rights reserved.
//

import UIKit

// TODO: Handle error states with throw once 2.0 is released.

public class PIAdapter: NSObject {
    
    private let TAG = "[MILPresenceInsightsSDK] "
    
    private let _configSegment = "/pi-config/v1/"
    private let _beaconSegment = "/conn-beacon/v1/"
    private let _analyticsSegment = "/analytics/v1/"
    private let _httpContentTypeHeader = "Content-Type"
    private let _httpAuthorizationHeader = "Authorization"
    private let _contentTypeJSON = "application/json"
    private let GET = "GET"
    private let POST = "POST"
    private let PUT = "PUT"
    
    private var _baseURL: String!
    private var _configURL: String!
    private var _tenantCode: String!
    private var _orgCode: String!
    private var _authorization: String!
    
    private var _debug: Bool = false
    
    /**
        INITIALIZERS
    */
    public init(tenant:String, org:String, baseURL:String, username:String, password:String) {
        
        _tenantCode = tenant
        _orgCode = org
        _baseURL = baseURL
        _configURL = _baseURL + _configSegment + "tenants/" + _tenantCode + "/orgs/" + _orgCode
        
        let authorizationString = username + ":" + password
        _authorization = "Basic " + (authorizationString.dataUsingEncoding(NSASCIIStringEncoding)?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding76CharacterLineLength))!
        
        println(TAG + "Adapter Initialized with URL: \(_configURL)")
        
    }
    
    public convenience init(tenant:String, org:String, username:String, password:String) {
        let defaultURL = "https://presenceinsights.ng.bluemix.net"
        self.init(tenant: tenant, org: org, baseURL: defaultURL, username: username, password: password)
    }
    
    public func enableLogging() {
        _debug = true
    }
    
    /** 
        BEGIN DEVICE RELATED FUNCTIONS
    */
    
    public func registerDevice(device: PIDevice, callback:(PIDevice)->()) {
        
        let endpoint = _configURL + "/devices"
        
        device.setRegistered(true)
        
        let deviceData = dictionaryToJSON(device.toDictionary())
        
        let request = buildRequest(endpoint, method: POST, body: deviceData)
        performRequest(request, callback: {response in
            
            self.printDebug("Register Response: \(response)")
            
            // If device doesn't exist:
            if let code = response["@code"] as? String {
                /**
                This is a safeguard to ensure that all fields are uploaded appropriatly and may not be needed in the future once the PI service is more stable.
                Ideally the code should be:
                
                callback(MILPIDevice(dictionary: response))
                */
                
                self.updateDevice(device, callback: {newDevice in
                    callback(newDevice)
                })
                // If device does exist:
            } else if let headers = response["headers"] as? NSDictionary {
                if let location = headers["Location"] as? String {
                    self.getDevice(location, callback: {deviceData in
                        self.updateDeviceDictionary(location, dictionary: deviceData, device: device, callback: {newDevice in
                            callback(newDevice)
                        })
                    })
                }
            }
        })
    }
    
    public func unregisterDevice(device: PIDevice, callback:(PIDevice)->()) {
        
        device.setRegistered(false)
        updateDevice(device, callback: {newDevice in
            callback(newDevice)
        })
    }
    
    public func updateDevice(device: PIDevice, callback:(PIDevice)->()) {
        
        var endpoint = _configURL + "/devices?rawDescriptor=" + device.getDescriptor()
        getDevice(endpoint, callback: {deviceData in
            endpoint = self._configURL + "/devices/" + (deviceData["@code"] as! String)
            self.updateDeviceDictionary(endpoint, dictionary: deviceData, device: device, callback: {newDevice in
                callback(newDevice)
            })
        })
    }
    
    private func updateDeviceDictionary(endpoint: String, dictionary: NSDictionary, device: PIDevice, callback:(PIDevice)->()) {
        
        var newDevice = NSMutableDictionary(dictionary: dictionary)
        
        newDevice.setObject(device.isRegistered(), forKey: device.JSON_REGISTERED_KEY)
        
        if device.isRegistered() {
            newDevice.setObject(device.name!, forKey: device.JSON_NAME_KEY)
            newDevice.setObject(device.type!, forKey: device.JSON_TYPE_KEY)
            newDevice.setObject(device.data!, forKey: device.JSON_DATA_KEY)
            newDevice.setObject(device.unencryptedData!, forKey: device.JSON_UNENCRYPTED_DATA_KEY)
        }
        
        let deviceJSON = self.dictionaryToJSON(newDevice)
        
        let request = self.buildRequest(endpoint, method: self.PUT, body: deviceJSON)
        self.performRequest(request, callback: {response in
            self.printDebug("Update Response: \(response)")
            if let code = response["@code"] as? String {
                callback(PIDevice(dictionary: response))
            }
        })
        
    }
    
    public func getDeviceByCode(code: String, callback:(PIDevice)->()) {
        
        let endpoint = _configURL + "/devices/" + code
        getDevice(endpoint, callback: {deviceData in
            let device = PIDevice(dictionary: deviceData)
            callback(device)
        })
    }
    
    public func getDeviceByDescriptor(descriptor: String, callback:(PIDevice)->()) {
        
        let endpoint = _configURL + "/devices?rawDescriptor=" + descriptor
        getDevice(endpoint, callback: {deviceData in
            let device = PIDevice(dictionary: deviceData)
            callback(device)
        })
        
    }
    
    private func getDevice(endpoint: String, callback: (NSDictionary)->()) {
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response in
            
            self.printDebug("Get Device Response: \(response)")
            
            var deviceData = response
            if let rows = response["rows"] as? NSArray {
                if rows.count > 0 {
                    deviceData = rows[0] as! NSDictionary
                } else {
                    return
                }
            }
            
            callback(deviceData)
            
        })
    }
    
    /** 
        NOTE: Getting devices will only return the first 100 devices.
        A future implementation should probably account for page size and number
    */
    public func getAllDevices(callback:([PIDevice])->()) {
        
        let endpoint = _configURL + "/devices?pageSize=100"
        
        getDevices(endpoint, callback: {devices in
            callback(devices)
        })
    }
    
    public func getRegisteredDevices(callback:([PIDevice])->()) {
        
        let endpoint = _configURL + "/devices?pageSize=100&registered=true"
        
        getDevices(endpoint, callback: {devices in
            callback(devices)
        })
    }
    
    private func getDevices(endpoint: String, callback:([PIDevice])->()) {
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response in
            
            self.printDebug("Get Devices Response: \(response)")
            
            var devices: [PIDevice] = []
            if let rows = response["rows"] as? NSArray {
                for row in rows as! [NSDictionary] {
                    let device = PIDevice(dictionary: row)
                    devices.append(device)
                }
            }
            
            callback(devices)
        })
    }
    
    /**
        END DEVICE RELATED FUNCTIONS
    */
    
    /**
        BEGIN BEACON RELATED FUNCTIONS
    */
    
    public func getAllBeaconRegions(callback:([String]) -> ()) {
        
        let endpoint = _configURL + "/views/proximityUUID"
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response in
            
            self.printDebug("Get All Beacon Regions Response: \(response)")
            
            if let regions = response["dataArray"] as? [String] {
                callback(regions)
            }
        })
        
    }
    
    public func getAllBeacons(site: String, floor: String, callback:([PIBeacon])->()) {
        
        // Swift cannot handle this complex of an expression without breaking it down.
        var endpoint =  _configURL + "/sites/" + site
        endpoint += "/floors/" + floor + "/beacons"
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response in
            
            self.printDebug("Get Beacons Response: \(response)")
            
            var beacons: [PIBeacon] = []
            if let rows = response["rows"] as? NSArray {
                for row in rows as! [NSDictionary] {
                    let beacon = PIBeacon(dictionary: row)
                    beacons.append(beacon)
                }
            }
            
            callback(beacons)
        })
    }
    
    public func sendBeaconPayload(beaconData:NSArray) {
        
        let endpoint = _baseURL + _beaconSegment + "tenants/" + _tenantCode + "/orgs/" + _orgCode
        let notificationMessage = NSDictionary(object: beaconData, forKey: "bnm")
        
        let notificationData = dictionaryToJSON(notificationMessage)
        
        self.printDebug("Sending Beacon Payload: \(notificationMessage)")
        
        let request = buildRequest(endpoint, method: POST, body: notificationData)
        performRequest(request, callback: {response in
            self.printDebug("Sent Beacon Payload Response: \(response)")
        })
    }
    
    /**
        END BEACON RELATED FUNCTIONS
    */
    
    /**
    BEGIN ORG RELATED FUNCTIONS
    */
    
    public func getOrg(callback:(NSDictionary)->()) {
        
        // Swift cannot handle this complex of an expression without breaking it down.
        var endpoint =  _configURL
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response in
            
            self.printDebug("Get Org Response: \(response)")
            
            callback(response as NSDictionary)
        })
    }
    
    /**
    END ORG RELATED FUNCTIONS
    */
    
    /**
        BEGIN ZONE RELATED FUNCTIONS
    */
    
    public func getAllZones(site: String, floor: String, callback:([PIZone])->()) {
        
        // Swift cannot handle this complex of an expression without breaking it down.
        var endpoint =  _configURL + "/sites/" + site
        endpoint += "/floors/" + floor + "/zones"
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response in
            
            self.printDebug("Get Zones Response: \(response)")
            
            var zones: [PIZone] = []
            if let rows = response["rows"] as? NSArray {
                for row in rows as! [NSDictionary] {
                    let zone = PIZone(dictionary: row)
                    zones.append(zone)
                }
            }
            
            callback(zones)
        })
    }
    
    /**
        END ZONE RELATED FUNCTIONS
    */
    
    /**
        BEGIN MAP RELATED FUNCTIONS
    */
    
    public func getMap(site: String, floor: String, callback:(UIImage)->()) {
        
        // Swift cannot handle this complex of an expression without breaking it down.
        var endpoint =  _configURL + "/sites/" + site
        endpoint += "/floors/" + floor + "/map"
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response in
            
            self.printDebug("Get Map Response: \(response)")
            
            if let data = response["rawData"] as? NSData {
                if let image = UIImage(data: data) {
                    callback(image)
                } else {
                    self.printDebug("Invalid Image: \(data)")
                }
            } else {
                self.printDebug("Invalid Data")
            }
        })
        
    }
    
    /**
        END MAP RELATED FUNCTIONS
    */
    
    /**
        BEGIN SITE RELATED FUNCTIONS
    */
    
    // TODO: Add PISite object that will also handle the address, etc.
    public func getAllSites(callback:([String: String])->()) {
        
        var endpoint =  _configURL + "/sites"
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response in
            
            self.printDebug("Get Sites Response: \(response)")
            
            var sites: [String: String] = [:]
            if let rows = response["rows"] as? NSArray {
                for row in rows as! [NSDictionary] {
                    if let site = row["@code"] as? String {
                        if let name = row["name"] as? String {
                            sites[site] = name
                        }
                    }
                }
            }
            
            callback(sites)
        })
    }
    
    /**
        END SITE RELATED FUNCTIONS
    */
    
    /**
        BEGIN FLOOR RELATED FUNCTIONS
    */
    
    // TODO: Add PIFloor object that will also handle the z, pixelsToMeter, etc.
    public func getAllFloors(site: String, callback:([String: String])->()) {
        
        var endpoint =  _configURL + "/sites/" + site + "/floors"
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response in
            
            self.printDebug("Get Floors Response: \(response)")
            
            var floors: [String: String] = [:]
            if let rows = response["rows"] as? NSArray {
                for row in rows as! [NSDictionary] {
                    if let floor = row["@code"] as? String {
                        if let name = row["name"] as? String {
                            floors[floor] = name
                        }
                    }
                }
            }
            
            callback(floors)
        })
    }
    
    /**
        END FLOOR RELATED FUNCTIONS
    */
    
    /**
        BEGIN ANALYTICS FUNCTIONS
    */
    
    // TODO: Add functions to handle some analytics functions.
    
    /**
        END ANALYTICS FUNCTIONS
    */
    
    /**
        BEGIN UTILS
    */
    
    private func buildRequest(endpoint:String, method:String, body: NSData?) -> NSURLRequest {
        
        if let url = NSURL(string: endpoint) {
            
            let request = NSMutableURLRequest(URL: url)
            
            request.HTTPMethod = method
            request.addValue(_authorization, forHTTPHeaderField: _httpAuthorizationHeader)
            request.addValue(_contentTypeJSON, forHTTPHeaderField: _httpContentTypeHeader)
            
            if let bodyData = body {
                request.HTTPBody = bodyData
            }
            
            return request
        } else {
            printDebug("Invalid URL: \(endpoint)")
        }
        
        return NSURLRequest()
        
    }
    
    private func performRequest(request:NSURLRequest, callback:(NSDictionary!)->()) {
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error in
            
            if (error != nil) {
                print(error)
            } else {
                if let responseData = data {
                    
                    var error: NSError?
                    if let json = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableLeaves, error: &error) as? NSDictionary {
                        if (error != nil) {
                            let dataString = NSString(data: responseData, encoding: NSUTF8StringEncoding)
                            self.printDebug("Could not parse response. " + (dataString as! String) + "\(error)")
                        } else {
                            callback(json)
                        }
                    } else if let json = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableLeaves, error: &error) as? NSArray {
                        if (error != nil) {
                            let dataString = NSString(data: responseData, encoding: NSUTF8StringEncoding)
                            self.printDebug("Could not parse response. " + (dataString as! String) + "\(error)")
                        } else {
                            let returnVal = NSDictionary(object: json, forKey: "dataArray")
                            callback(returnVal)
                        }
                    } else {
                        let returnVal = NSDictionary(object: responseData, forKey: "rawData")
                        callback(returnVal)
                    }
                    
                } else {
                    self.printDebug("No response data.")
                }
                
            }
        })
        task.resume()
    }
    
    private func dictionaryToJSON(dictionary: NSDictionary) -> NSData {
        var error: NSError?
        if let deviceJSON = NSJSONSerialization.dataWithJSONObject(dictionary, options: NSJSONWritingOptions.allZeros, error: &error) {
            if (error != nil) {
                printDebug("Could not convert dictionary object to JSON. \(error)")
            } else {
                return deviceJSON
            }
            
        } else {
            printDebug("Could not convert dictionary object to JSON.")
        }
        
        return NSData()
        
    }
    
    public func printDebug(message:String) {
        if _debug {
            println(TAG + message)
        }
    }
    
    /**
        END UTILS
    */
    
}