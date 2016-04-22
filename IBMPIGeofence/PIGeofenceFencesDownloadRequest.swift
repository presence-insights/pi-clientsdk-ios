/**
*  IBMPIGeofence
*  PIGeofenceFencesDownloadRequest.swift
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

/// Get the geofences defined on the PI backend
@objc(IBMPIGeofenceFencesDownloadRequest)
public final class PIGeofenceFencesDownloadRequest:NSObject,PIDownloadRequest {

	let lastSyncDate:NSDate?

	public init(lastSyncDate:NSDate?) {
		self.lastSyncDate = lastSyncDate
	}

	public func executeDownload(service:PIService) -> PIDownloadResponse? {

		DDLogVerbose("PIGeofenceFencesDownloadRequest.executeDownload",asynchronous:false)

		guard let orgCode = service.orgCode else {
			DDLogError("Missing orgCode for executing the download")
			return nil
		}
		let path = "pi-config/v2/tenants/\(service.tenantCode)/orgs/\(orgCode)/geofences"
		let url = NSURL(string:path,relativeToURL:service.baseURL)
		let URLComponents = NSURLComponents(URL:url!,resolvingAgainstBaseURL:true)!

		var queryItems:[String:Any] = ["paginate":false]
		if let lastSyncDate = lastSyncDate {
			queryItems["updatedAfter"] = "\(Int64(lastSyncDate.timeIntervalSince1970))"
		}
		URLComponents.percentEncodedQuery = PIGeofenceUtils.buildQueryStringWithParams(queryItems)


		DDLogInfo("PIGeofenceFencesDownloadRequest \(URLComponents.URL!)",asynchronous:false)

		let request = NSMutableURLRequest(URL: URLComponents.URL!)
		PIGeofenceUtils.setBasicAuthHeader(request, username: service.username, password: service.password)

		let task = service.backgroundServiceSession.downloadTaskWithRequest(request)
		task.taskDescription = "PIGeofenceFencesDownloadRequest"
		task.resume()
		let taskIdentifier = task.taskIdentifier
		guard let backgroundSessionIdentifier = service.backgroundServiceSession.configuration.identifier else {
			DDLogError("No Background session identifier")
			return nil
		}

		return PIDownloadResponse(backgroundSessionIdentifier: backgroundSessionIdentifier, taskIdentifier: taskIdentifier)
	}
}