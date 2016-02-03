/**
 *  PIOutdoorSDK
 *  PIGeofenceDeleteOperation.swift
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

final class PIGeofenceDeleteOperation:ServiceOperation {
    
    let geofenceCode:String
    
    init(service: PIService,geofenceCode:String) {
        self.geofenceCode = geofenceCode
        super.init(service: service)
        self.name = "com.ibm.PI.PIGeofenceDeleteOperation"
    }
    
    override func main() {
        let path = "pi-config/v2/tenants/\(service.tenantCode)/orgs/\(service.orgCode!)/geofences/\(geofenceCode)"
        
        
        
        let url = NSURL(string:path,relativeToURL:self.service.baseURL)
        let URLComponents = NSURLComponents(URL:url!,resolvingAgainstBaseURL:true)!
        
        DDLogVerbose("\(URLComponents.URL)")
        
        let request = NSMutableURLRequest(URL:URLComponents.URL!,cachePolicy:.ReloadIgnoringLocalCacheData,timeoutInterval:service.timeout)
        
        setBasicAuthHeader(request)
        
        request.HTTPMethod = "DELETE"
        
        performRequest(request) {
            self.executing = false
            self.finished = true
        }
        
        
    }
}