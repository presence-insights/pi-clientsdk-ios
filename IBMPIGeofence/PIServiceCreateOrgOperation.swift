/**
 *  PIOutdoorSDK
 *  PIServiceCreateOrgOperation
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

final class PIServiceCreateOrgOperation:PIServiceOperation {
    
    let orgName:String
    
    init(service: PIService,orgName:String) {
        self.orgName = orgName
        super.init(service: service)
        self.name = "com.ibm.pi.ServiceCreateOrgOperation"
    }
    
    override func main() {
        let path = "pi-config/v2/tenants/\(service.tenantCode)/orgs"
        
        var json:[String:AnyObject] = [:]
        
        json["name"] = self.orgName
        json["registrationTypes"] = ["Internal"]
        json["description"] = "PIOutdoorSample"
        
        let url = NSURL(string:path,relativeToURL:self.service.baseURL)
        let URLComponents = NSURLComponents(URL:url!,resolvingAgainstBaseURL:true)!
        
        DDLogVerbose("\(URLComponents.URL)",asynchronous:false)
        
        let request = NSMutableURLRequest(URL:URLComponents.URL!)
        request.timeoutInterval = 10
		
        setBasicAuthHeader(request)
        
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(json, options: [])
        request.HTTPMethod = "POST"
        
        let string = NSString(data: request.HTTPBody!, encoding: NSUTF8StringEncoding)
		DDLogVerbose("PIServiceCreateOrgOperation payload: \(string)",asynchronous:false)

        performRequest(request) {
            self.executing = false
            self.finished = true
        }
        
    }
    
}