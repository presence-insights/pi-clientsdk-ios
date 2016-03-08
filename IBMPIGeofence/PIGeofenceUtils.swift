/**
 *  PIOutdoorSDK
 *  PIOutdoorUtils.swift
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


func StringFromClass(obj: AnyClass) -> String {
    return obj.description().componentsSeparatedByString(".").last!
}


class PIGeofenceUtils {
    
    static let documentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls.first!
    }()
    
    
	static let libraryDirectory: NSURL = {
		let urls = NSFileManager.defaultManager().URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask)
		return urls.first!
	}()


    static let applicationCachesDirectory:NSURL = {
        
        return NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first!
    }()

	static let version:String = {
		let infoDictionary = NSBundle(forClass: PIGeofenceUtils.self).infoDictionary!
		let appVersionName = infoDictionary["CFBundleShortVersionString"] as! String
		let appBuildNumber = infoDictionary["CFBundleVersion"] as! String

		return "\(appVersionName) (\(appBuildNumber))"

	}()

	static func setBasicAuthHeader(request:NSMutableURLRequest,username:String,password:String) -> Bool {
		let authorization = username + ":" + password
		guard let authorizationData = authorization.dataUsingEncoding(NSUTF8StringEncoding) else {
			return false
		}
		let authorizationbase64 = authorizationData.base64EncodedStringWithOptions([])
		request.setValue("Basic " + authorizationbase64, forHTTPHeaderField: "Authorization")

		return true
	}

	static func buildQueryStringWithParams(params:[String:Any]) -> String? {

		let pairs:NSMutableArray = []

		for (key,value) in params {
			let param = "\(key)=\(value)"
			pairs.addObject(param)
		}

		let queryString = pairs.componentsJoinedByString("&")

		let encodedQueryString = queryString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())

		return encodedQueryString
	}



}


private let dateFormatter:NSDateFormatter = {
    let dateFormatter = NSDateFormatter()
    let enUSPOSIXLocale = NSLocale(localeIdentifier: "en_US_POSIX")
    dateFormatter.locale = enUSPOSIXLocale
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    
    return dateFormatter
    
}()

extension NSDate {
    var ISO8601:String {
        return dateFormatter.stringFromDate(self)
    }
}


