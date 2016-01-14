/**
*  PresenceInsightsSDK
*  PIAdapter.swift
*
*  Performs all communication to the PI Rest API.
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

// MARK: - PIAdapter object
public class PIAdapter: NSObject {
    
    private let TAG = "[PresenceInsightsSDK] "
    
    private let _configSegment = "/pi-config/v1/"
    private let _configSegment_v2 = "/pi-config/v2/"
    private let _beaconSegment = "/conn-beacon/v1/"
    private let _analyticsSegment = "/analytics/v1/"
    private let _httpContentTypeHeader = "Content-Type"
    private let _httpAuthorizationHeader = "Authorization"
    private let _contentTypeJSON = "application/json"
    private let GET = "GET"
    private let POST = "POST"
    private let PUT = "PUT"
    
    private let _baseURL: String
    private let _configURL: String
    private let _configURL_v2: String
    private let _tenantCode: String
    private let _orgCode: String
    private let _authorization: String
    
    private var _debug: Bool = false
    
    /**
    Default object initializer.
    
    - parameter tenant:   PI Tenant Code
    - parameter org:      PI Org Code
    - parameter baseURL:  The base URL of your PI service.
    - parameter username: PI Username
    - parameter password: PI Password
    
    - returns: An initialized PIAdapter.
    */
    public init(tenant:String, org:String, baseURL:String, username:String, password:String) {
        
        _tenantCode = tenant
        _orgCode = org
        _baseURL = baseURL
        _configURL = _baseURL + _configSegment + "tenants/" + _tenantCode + "/orgs/" + _orgCode
        _configURL_v2 = _baseURL + _configSegment_v2 + "tenants/" + _tenantCode + "/orgs/" + _orgCode
        
        let authorizationString = username + ":" + password
        _authorization = "Basic " + (authorizationString.dataUsingEncoding(NSASCIIStringEncoding)?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding76CharacterLineLength))!
        
        print(TAG + "Adapter Initialized with URL: \(_configURL)")
        
    }
    
    /**
    Convenience initializer which sets a default baseURL.
    
    - parameter tenant:   PI Tenant Code
    - parameter org:      PI Org Code
    - parameter username: PI Username
    - parameter password: PI Password
    
    - returns: An initialized PIAdapter.
    */
    public convenience init(tenant:String, org:String, username:String, password:String) {
        let defaultURL = "https://presenceinsights.ng.bluemix.net"
        self.init(tenant: tenant, org: org, baseURL: defaultURL, username: username, password: password)
    }
    
    /**
    Public function to enable logging for debug purposes.
    */
    public func enableLogging() {
        _debug = true
    }
}

// MARK: - Device related functions
extension PIAdapter {
    
    /**
    Public function to register a device in PI. 
    If the device already exists it will be updated.
    
    - parameter device:   PIDevice to be registered.
    - parameter callback: Returns a copy of the registered PIDevice upon task completion.
    */
    public func registerDevice(device: PIDevice, callback:(PIDevice?, NSError?)->()) {
        
        guard device.name != nil && device.type != nil else {
            let errorDetails = [NSLocalizedFailureReasonErrorKey: "PIDevice type or name cannot be registered as nil."]
            let error = NSError(domain: "PresenceInsightsSDK", code: 0, userInfo: errorDetails)
            callback(nil, error)
            return
        }
        
        var device = device
        
        let endpoint = _configURL + "/devices"
        
        device.registered = true
        
        if device.data == nil {
            device.data = [:]
        }
        
        if device.unencryptedData == nil {
            device.unencryptedData = [:]
        }
        
        let deviceData = dictionaryToJSON(device.toDictionary())
        
        let request = buildRequest(endpoint, method: POST, body: deviceData)
        performRequest(request, callback: {response, error in
            
            self.printDebug("Register Response: \(response)")
            
            guard let response = response where error == nil else {
                callback(PIDevice(), error)
                return
            }
            
            // If device doesn't exist:
            if let _ = response["@code"] as? String {
                // This is a safeguard to ensure that all fields are uploaded appropriatly
                self.updateDevice(device, callback: {newDevice, error in
                    
                    guard let newDevice = newDevice where error == nil else {
                        callback(PIDevice(), error)
                        return
                    }
                    
                    callback(newDevice, nil)
                })
                // If device does exist:
            } else if
                let headers = response["headers"] as? [String: AnyObject],
                let location = headers["Location"] as? String {
                    self.getDevice(location, callback: {deviceData, error in
                        guard let deviceData = deviceData where error == nil else {
                            callback(nil, error)
                            return
                        }
                        self.updateDeviceDictionary(location, dictionary: deviceData, device: device, callback: {newDevice, error in
                            guard error == nil else {
                                callback(PIDevice(), error)
                                return
                            }
                            callback(newDevice, nil)
                        })
                    })
            } else {
                // TODO : NSError
                callback(nil,nil)
            }
        })
    }
    
    /**
    Public function to unregister a device in PI.
    Sets device registered property to false and updates the device.
    
    - parameter device:   PIDevice to unregister.
    - parameter callback: Returns a copy of the unregistered PIDevice upon task completion.
    */
    public func unregisterDevice(device: PIDevice, callback:(PIDevice?, NSError?)->()) {
        
        var device_ = device
        device_.registered = false
        updateDevice(device_, callback: {newDevice, error in
            guard let newDevice = newDevice where error == nil else {
                callback(nil, error)
                return
            }
            callback(newDevice, nil)
        })
    }
    
    /**
    Public function to update a device in PI. 
    It pulls down the remote version of the device then modifies it for re-upload.
    
    - parameter device:   PIDevice to be updated.
    - parameter callback: Returns a copy of the updated PIDevice upon task completion.
    */
    public func updateDevice(device: PIDevice, callback:(PIDevice?, NSError?)->() ) {
        
        guard let descriptor = device.descriptor else {
            // TODO: NSError or throw exception
            callback(nil,nil)
            return
        }
        
        let endpoint = _configURL + "/devices?rawDescriptor=" + descriptor
        getDevice(endpoint, callback: {deviceData, error in
            guard let deviceData = deviceData where error == nil else {
                callback(nil, error)
                return
            }
            guard let code = deviceData["@code"] as? String else {
                // TODO: NSError or throw exception
                callback(nil,nil)
                return
            }
            let endpoint = self._configURL + "/devices/" + code
            self.updateDeviceDictionary(endpoint, dictionary: deviceData, device: device, callback: {newDevice, error in
                callback(newDevice, error)
            })
        })
    }
    
    /**
    Private function that modifies the remote device dictionary object with a local PIDevice and uploads it to PI.
    
    - parameter endpoint:   The device endpoint to update.
    - parameter dictionary: Current version of device in PI.
    - parameter device:     Local PIDevice used to update remote device.
    - parameter callback:   Returns the updated PIDevice object upon task completion.
    */
    private func updateDeviceDictionary(endpoint: String, dictionary: [String: AnyObject], device: PIDevice, callback:(PIDevice?, NSError?)->()) {
        
        var newDevice = dictionary
        
        newDevice[Device.JSON_REGISTERED_KEY] = device.registered
        
        if device.registered {
            newDevice[Device.JSON_NAME_KEY] = device.name
            newDevice[Device.JSON_TYPE_KEY] = device.type
            newDevice[Device.JSON_DATA_KEY] = device.data
            newDevice[Device.JSON_UNENCRYPTED_DATA_KEY] = device.unencryptedData
        }
        
        let deviceJSON = self.dictionaryToJSON(newDevice)
        
        let request = self.buildRequest(endpoint, method: self.PUT, body: deviceJSON)
        self.performRequest(request, callback: {response, error in
            guard let response = response where error == nil else {
                callback(nil, error)
                return
            }
            self.printDebug("Update Response: \(response)")
            // TODO: check if this test is at the right place
            if let _ = response["@code"] as? String {
                callback(PIDevice(dictionary: response), nil)
            } else {
                // TODO: Create an NSError or throw an exception
                callback(nil, nil)
            }
        })
        
    }
    
    /**
    Public function to retrieve a device from PI using the device's code.
    
    - parameter code:     The device's code.
    - parameter callback: Returns the PIDevice upon task completion.
    */
    public func getDeviceByCode(code: String, callback:(PIDevice?, NSError?)->()) {
        
        let endpoint = _configURL + "/devices/" + code
        getDevice(endpoint, callback: {deviceData, error in
            guard let deviceData = deviceData where error == nil else {
                callback(nil, error)
                return
            }
            let device = PIDevice(dictionary: deviceData)
            callback(device, nil)
        })
    }
    
    /**
    Public function to retrice a device from PI using the device's descriptor.
    
    - parameter descriptor: The unhashed device descriptor. (Usually the UUID)
    - parameter callback:   Returns the PIDevice upon task completion.
    */
    public func getDeviceByDescriptor(descriptor: String, callback:(PIDevice?, NSError?)->()) {
        
        let endpoint = _configURL + "/devices?rawDescriptor=" + descriptor
        getDevice(endpoint, callback: {deviceData, error in
            guard let deviceData = deviceData where error == nil else {
                callback(nil, error)
                return
            }
            let device = PIDevice(dictionary: deviceData)
            callback(device, nil)
        })
        
    }
    
    /**
    Private function to get a device using either code of descriptor.
    
    - parameter endpoint: The Rest API endpoint of the device object.
    - parameter callback: Returns the dictionary object of the device upon task completion.
    */
    private func getDevice(endpoint: String, callback: ([String: AnyObject]?, NSError?)->()) {
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response, error in
            
            guard let response = response where error == nil else {
                callback(nil, error)
                return
            }
            
            self.printDebug("Get Device Response: \(response)")
            
            var deviceData = response
            if let rows = response["rows"] as? [AnyObject] {
                if rows.count > 0 {
                    deviceData = rows[0] as! [String: AnyObject]
                } else {
                    return
                }
            }
            
            callback(deviceData, nil)
            
        })
    }
    
    /**
    Public function to retrieve all registered and unregistered devices from PI.
    
    NOTE: Getting devices currently returns the first 100 devices.
    A future implementation should probably account for page size and number.
    
    - parameter callback: Returns an array of PIDevices upon task completion.
    */
    public func getAllDevices(callback:([PIDevice]?, NSError?)->()) {
        
        let endpoint = _configURL + "/devices?pageSize=100"
        
        getDevices(endpoint, callback: {devices, error in
            guard let devices = devices where error == nil else {
                callback(nil, error)
                return
            }
            callback(devices, nil)
        })
    }
    
    /**
    Public function to retrieve only registered devices from PI.
    
    NOTE: Getting devices currently returns the first 100 devices.
    A future implementation should probably account for page size and number.
    
    - parameter callback: Returns an array of PIDevices upon task completion.
    */
    public func getRegisteredDevices(callback:([PIDevice]?, NSError?)->()) {
        
        let endpoint = _configURL + "/devices?pageSize=100&registered=true"
        
        getDevices(endpoint, callback: {devices, error in
            guard let devices = devices where error == nil else {
                callback(nil, error)
                return
            }
            callback(devices, nil)
        })
    }
    
    /**
    Private function to handle getting multiple devices.
    
    - parameter endpoint: The Rest API endpoint of the devices.
    - parameter callback: Returns an array of PIDevices upon task completion.
    */
    private func getDevices(endpoint: String, callback:([PIDevice]?, NSError?)->()) {
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response, error in
            
            guard let response = response where error == nil else {
                callback(nil, error)
                return
            }
            
            self.printDebug("Get Devices Response: \(response)")
            
            var devices: [PIDevice] = []
            if let rows = response["rows"] as? [AnyObject] {
                for case let row as [String: AnyObject] in rows {
                    let device = PIDevice(dictionary: row)
                    devices.append(device)
                }
            }
            
            callback(devices, nil)
        })
    }
}

// MARK: - Beacon related functions
extension PIAdapter {
    
    /**
    Public function to get all beacon proximity UUIDs.
    
    - parameter callback: Returns a String array of all beacon proximity UUIDs upon task completion.
    */
    public func getAllBeaconRegions(callback:([String]?, NSError?) -> ()) {
        
        let endpoint = _configURL + "/views/proximityUUID"
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response, error in
            
            guard let response = response where error == nil else {
                callback(nil, error)
                return
            }
            
            self.printDebug("Get All Beacon Regions Response: \(response)")
            
            if let regions = response["dataArray"] as? [String] {
                callback(regions, nil)
            } else {
                // TODO: NSError or throw exception
                callback(nil, nil)
            }
        })
        
    }
    
    /**
    Public function to get all beacons on a specific floor.
    
    - parameter site:     PI Site code
    - parameter floor:    PI Floor code
    - parameter callback: Returns an array of PIBeacons upon task completion.
    */
    public func getAllBeacons(site: String, floor: String, callback:([PIBeacon]?, NSError?)->()) {
        
        // Swift cannot handle this complex of an expression without breaking it down.
        var endpoint =  _configURL_v2 + "/sites/" + site
        endpoint += "/floors/" + floor + "/beacons"
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response, error in
            
            guard let response = response where error == nil else {
                callback(nil, error)
                return
            }
            
            self.printDebug("Get Beacons Response: \(response)")
            
            var beacons: [PIBeacon] = []
            if let rows = response[GeoJSON.FEATURES_KEY] as? [AnyObject] {
                for case let row as [String: AnyObject] in rows {
                    if let beacon = PIBeacon(dictionary: row) {
                        beacons.append(beacon)
                    }
                }
            }
            
            callback(beacons, nil)
        })
    }
    
    /**
    Public function to send a payload of all beacons ranged by the device back to PI.
    
    - parameter beaconData: Array containing all ranged beacons and the time they were detected.
    */
    public func sendBeaconPayload(beaconData:[[String: AnyObject]]) {
        
        let endpoint = _baseURL + _beaconSegment + "tenants/" + _tenantCode + "/orgs/" + _orgCode
        let notificationMessage =  ["bnm": beaconData]
        
        let notificationData = dictionaryToJSON(notificationMessage)
        
        self.printDebug("Sending Beacon Payload: \(notificationMessage)")
        
        let request = buildRequest(endpoint, method: POST, body: notificationData)
        performRequest(request, callback: {response, error in
            guard let response = response where error == nil else {
                self.printDebug("Could not send beacon payload: \(error)")
                return
            }
            self.printDebug("Sent Beacon Payload Response: \(response)")
        })
    }
}

// MARK: - Zone related functions
extension PIAdapter {
    
    /**
    Public function to retrieve all zones in a floor.
    
    - parameter site:     PI Site code
    - parameter floor:    PI Floor code
    - parameter callback: Returns an array of PIZones upon task completion.
    */
    public func getAllZones(site: String, floor: String, callback:([PIZone]?, NSError?)->()) {
        
        // Swift cannot handle this complex of an expression without breaking it down.
        var endpoint =  _configURL_v2 + "/sites/" + site
        endpoint += "/floors/" + floor + "/zones"
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response, error in
            
            guard let response = response where error == nil else {
                callback(nil, error)
                return
            }
            
            self.printDebug("Get Zones Response: \(response)")
            
            var zones = [PIZone]()
            if let rows = response[GeoJSON.FEATURES_KEY] as? [AnyObject] {
                for case let row as [String: AnyObject] in rows {
                    let zone = PIZone(dictionary: row)
                    zones.append(zone)
                }
            }
            
            callback(zones, nil)
        })
    }
}

// MARK: - Map related functions
extension PIAdapter {
    
    /**
    Public function to retrieve a floor's map image.
    
    - parameter site:     PI Site code
    - parameter floor:    PI Floor code
    - parameter callback: Returns a UIImage of the map upon task completion.
    */
    public func getMap(site: String, floor: String, callback:(UIImage?, NSError?)->()) {
        
        // Swift cannot handle this complex of an expression without breaking it down.
        var endpoint =  _configURL + "/sites/" + site
        endpoint += "/floors/" + floor + "/map"
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response, error in
            
            guard let response = response where error == nil else {
                callback(nil, error)
                return
            }
            
            self.printDebug("Get Map Response: \(response)")
            
            if let data = response["rawData"] as? NSData {
                if let image = UIImage(data: data) {
                    callback(image, nil)
                } else {
                    self.printDebug("Invalid Image: \(data)")
                    // TODO: NSError or throw exception
                    callback(nil, nil)
                }
            } else {
                self.printDebug("Invalid Data")
                // TODO: NSError or throw exception
                callback(nil, nil)
            }
        })
        
    }
}

// MARK: - Org related functions
extension PIAdapter {
    
    /**
    Public function to retrive the org from PI.
    
    - parameter callback: Returns the raw dictionary from the Rest API upon task completion.
    */
    public func getOrg(callback:(PIOrg?, NSError?)->()) {
        
        let endpoint =  _configURL
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response, error in
            
            guard let response = response where error == nil else {
                callback(nil, error)
                return
            }
            
            self.printDebug("Get Org Response: \(response)")
            
            let org = PIOrg(dictionary: response)
            
            callback(org, nil)
        })
    }
}

// MARK: - Site related functions
extension PIAdapter {
    
    /**
    Public function to get all sites within the org.
    
    - parameter callback: Returns a dictionary with site code as the keys and site name as the values.
    */
    public func getAllSites(callback:([String: String]?, NSError?)->()) {
        
        let endpoint =  _configURL + "/sites"
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response, error in
            
            guard let response = response where error == nil else {
                callback([:], error)
                return
            }
            
            self.printDebug("Get Sites Response: \(response)")
            
            var sites: [String: String] = [:]
            if let rows = response["rows"] as? [AnyObject] {
                for case let row as [String: AnyObject] in rows {
                    if
                        let site = row["@code"] as? String,
                        let name = row["name"] as? String  {
                            sites[site] = name
                    }
                }
            }
            
            callback(sites, nil)
        })
    }
}

// MARK: - Floor related functions
extension PIAdapter {

    /**
    Public function to get all floors in a site.

    - parameter site:     PI Site code
    - parameter floor:     PI Floor code
    - parameter callback: Returns a dictionary with floor code as the keys and floor name as the values.
    */
    public func getAllSensors(site: String, floor: String, callback:([PISensor]?, NSError?)->()) {

        let endpoint = String(format: "%@/sites/%@/floors/%@/sensors", arguments: [_configURL_v2, site, floor])

        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response, error in

            guard let response = response where error == nil else {
                callback(nil, error)
                return
            }

            self.printDebug("Get Floors Response: \(response)")

            var sensors = [PISensor]()
            if let rows = response[GeoJSON.FEATURES_KEY] as? [AnyObject] {
                for case let row as [String: AnyObject] in rows {
                    let sensor = PISensor(dictionary: row)
                    sensors.append(sensor)
                }
            }

            callback(sensors, nil)
        })
    }
}

// MARK: - Floor related functions
extension PIAdapter {
    
    /**
    Public function to get all floors in a site.
    
    - parameter site:     PI Site code
    - parameter callback: Returns a dictionary with floor code as the keys and floor name as the values.
    */
    public func getAllFloors(site: String, callback:([PIFloor]?, NSError?)->()) {
        
        let endpoint =  _configURL_v2 + "/sites/" + site + "/floors"
        
        let request = buildRequest(endpoint, method: GET, body: nil)
        performRequest(request, callback: {response, error in
            
            guard let response = response where error == nil else {
                callback(nil, error)
                return
            }
            
            self.printDebug("Get Floors Response: \(response)")
            
            var floors = [PIFloor]()
            if let rows = response[GeoJSON.FEATURES_KEY] as? [AnyObject] {
                for case let row as [String: AnyObject] in rows {
                    let floor = PIFloor(dictionary: row)
                    floors.append(floor)
                }
            }
            
            callback(floors, nil)
        })
    }
}

// MARK: - Catch-all function
extension PIAdapter {
    
    /**
    Public function to perform a custom API request not covered elsewhere.
    
    - parameter endpoint: The URL substring that comes after the base URL. (/pi-config/v1/...)
    - parameter method:   The HTTP Method to use. (GET, POST, PUT, etc.)
    - parameter body:     Optional value if the method is a PUT or POST and needs to send data.
    - parameter callback: Returns an Dictionary of the response upon completion.
    */
    public func piRequest(endpoint: String, method: String, body: NSData?, callback: ([String: AnyObject]?, NSError?)->()){
        
        let url = _baseURL + endpoint
        
        let request = buildRequest(url, method: method, body: body)
        performRequest(request, callback: {response, error in
            guard error == nil else {
                callback(nil, error)
                return
            }
            callback(response, nil)
        })
        
    }
    
}

// MARK: - Utility functions
extension PIAdapter {
    
    /**
    Private function to build an http/s request
    
    - parameter endpoint: The URL to connect to.
    - parameter method:   The http method to use for the request.
    - parameter body:     (Optional) The body of the request.
    
    - returns: A built NSURLRequest to execute.
    */
    private func buildRequest(endpoint:String, method:String, body: NSData?) -> NSURLRequest {
        
        guard let url = NSURL(string: endpoint) else {
            printDebug("Invalid URL: \(endpoint)")
            // TODO: Should we throw ??
            fatalError("Shouldn't be there ")
        }
        
        let request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = method
        request.addValue(_authorization, forHTTPHeaderField: _httpAuthorizationHeader)
        request.addValue(_contentTypeJSON, forHTTPHeaderField: _httpContentTypeHeader)
        
        if let bodyData = body {
            request.HTTPBody = bodyData
        }
        
        return request
        
    }
    
    /**
    Private function to perform a URL request.
    Will always massage response data into a dictionary.
    
    - parameter request:  The NSURLRequest to perform.
    - parameter callback: Returns an Dictionary of the response on task completion.
    */
    private func performRequest(request:NSURLRequest, callback:([String: AnyObject]?, NSError?)->()) {
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error in
            
            guard error == nil else {
                print(error, terminator: "")
                callback(nil, error)
                return
            }

            if let data = data {
                do {
                    if let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableLeaves) as? [String: AnyObject] {
                        
                        if let _ = json["code"] as? String,  message = json["message"] as? String {
                            let errorDetails = [NSLocalizedFailureReasonErrorKey: message]
                            let error = NSError(domain: "PresenceInsightsSDK", code: 1, userInfo: errorDetails)
                            callback( nil, error)
                            return
                        }
                        callback(json, nil)
                        return
                    } else if let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableLeaves) as? [AnyObject] {
                        let returnVal = [ "dataArray" : json]
                        callback(returnVal, nil)
                        return
                    }
                } catch let error {
                    let returnVal = [ "rawData": data, "error": error as NSError]
                    callback(returnVal, nil)
                }
    
            } else {
                self.printDebug("No response data.")
            }
        })
        task.resume()
    }
    
    /**
    Private function to convert a dictionary to a JSON object.
    
    - parameter dictionary: The dictionary to convert.
    
    - returns: An NSData object containing the raw JSON of the dictionary.
    */
    private func dictionaryToJSON(dictionary: [String: AnyObject]) -> NSData {

        do {
            let deviceJSON = try NSJSONSerialization.dataWithJSONObject(dictionary, options: NSJSONWritingOptions())
            return deviceJSON
        } catch let error as NSError {
            printDebug("Could not convert dictionary object to JSON. \(error)")
        }
        
        return NSData()
        
    }
    
    /**
    Public function to print statements in the console when debug is enabled.
    Also appends the TAG to the message.
    
    - parameter message: The message to print in the console.
    */
    public func printDebug(message:String) {
        if _debug {
            print(TAG + message)
        }
    }
}