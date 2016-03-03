/**
 *  PIOutdoorSDK
 *  PIGeofenceMonitoringOperation.swift
 *
 *  Performs all communication to the PI Rest API.
 *
 *  © Copyright 2016 IBM Corp.
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


import Foundation
import CocoaLumberjack

final class PIGeofenceMonitoringOperation:ServiceOperation {
    
    let geofenceCode:String
    
    let eventTime:NSDate
    
    let event:PIGeofenceEvent
    
	let geofenceName:String?

	init(service: PIService,geofenceCode:String,eventTime:NSDate,event:PIGeofenceEvent,geofenceName:String?) {
        self.geofenceCode = geofenceCode
        self.eventTime = eventTime
        self.event = event
		self.geofenceName = geofenceName
        super.init(service: service)
        self.name = "com.ibm.PI.GeofenceMonitoringOperation"

		DDLogVerbose("Create PIGeofenceMonitoringOperation \(geofenceCode) , \(geofenceName)",asynchronous:false)
    }
    
    override func main() {
        let path = "conn-geofence/v1/tenants/\(service.tenantCode)/orgs/\(service.orgCode!)"
        
		DDLogVerbose("Main PIGeofenceMonitoringOperation \(path)",asynchronous:false)

        var json:[String:AnyObject] = [:]
        var notification:[String:AnyObject] = [:]
        
        notification["descriptor"] = UIDevice.currentDevice().identifierForVendor?.UUIDString
        notification["detectedTime"] = self.eventTime.ISO8601

        var data:[String:AnyObject] = [:]
        data["geofenceCode"] = self.geofenceCode
		data["geofenceName"] = self.geofenceName
        data["crossingType"] = self.event.rawValue
        notification["data"] = data
        
        json["notifications"] = [notification]
		json["sdkVersion"] = PIOutdoorUtils.version

        
        let url = NSURL(string:path,relativeToURL:self.service.baseURL)
        let URLComponents = NSURLComponents(URL:url!,resolvingAgainstBaseURL:true)!
        
        let request = NSMutableURLRequest(URL:URLComponents.URL!,cachePolicy:.ReloadIgnoringLocalCacheData,timeoutInterval:service.timeout)
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        setBasicAuthHeader(request)
        
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(json, options: [])
        request.HTTPMethod = "POST"
                
        performRequest(request) {
            self.executing = false
            self.finished = true
			DDLogVerbose("End PIGeofenceMonitoringOperation \(path)",asynchronous:false)
        }
        
        
    }
}