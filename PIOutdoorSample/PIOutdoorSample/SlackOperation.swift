/**
 *  PIOutdoorSDK
 *  SlackOperation.swift
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
import PIOutdoorSDK

enum SlackAPI:ErrorType {
    case WrongAPI
}

public class SlackOperation: HTTPOperation {
    
    let slackAPI:String
    
    let params:[String:String]
    
    let token: String
    
    public init(session:NSURLSession,slackAPI:String,params:[String:String],token:String) {
        
        self.slackAPI = slackAPI
        self.params = params
        self.token = token
        let url = NSURL(string: "https://slack.com/api/")!

        super.init(session:session, url: url,maxRetry:1)
        
        self.name = "com.ibm.PI.SlackOperation"
    }
    
    
    override public func main() {
        guard let url = NSURL(string:slackAPI,relativeToURL:self.url) else {
            self.result = .Exception(SlackAPI.WrongAPI)
            self.executing = false
            self.finished = true
            return
        }
        
        let URLComponents = NSURLComponents(URL:url,resolvingAgainstBaseURL:true)!
        var queryItems:[String:Any] = [:]
        for (key,value) in params {
            queryItems[key] = value
        }
        queryItems["token"] = self.token
        queryItems["username"] = "geofence"
        URLComponents.percentEncodedQuery = buildQueryStringWithParams(queryItems)
        
        guard let urlAPI = URLComponents.URL else {
            self.result = .Exception(SlackAPI.WrongAPI)
            self.executing = false
            self.finished = true
            return
        }
        
        print(urlAPI)
        
        let request = NSMutableURLRequest(URL:urlAPI,cachePolicy:.UseProtocolCachePolicy,timeoutInterval:self.timeout)
        
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        performRequest(request) {
            [unowned self] result in
            self.result = result
			self.executing = false
            self.finished = true
        }
    }
    
}

func buildQueryStringWithParams(params:[String:Any]) -> String {
    
    let pairs:NSMutableArray = []
    
    for (key,value) in params {
        let param = "\(key)=\(value)"
        pairs.addObject(param)
    }
    
    let queryString = pairs.componentsJoinedByString("&")
    
    let encodedQueryString = queryString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
    
    return encodedQueryString!
}



