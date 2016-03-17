/**
*  IBMPIGeofence
*  PIGeofencePreferences.swift
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

private let kLastDownloadDate = "com.ibm.pi.LastDownloadDate"
private let kLastDownloadErrorDate = "com.ibm.pi.lastDownloadErrorDate"
private let kErrorDownloadCountKey = "com.ibm.pi.downloads.errorCount"
private let kLastSyncDate = "com.ibm.pi.downloads.lastSyncDate"
private let kMaxDownloadRetry = "com.ibm.pi.downloads.maxDownloadRetry"

struct PIGeofencePreferences {
	static var lastDownloadDate:NSDate? {
		set {
			if let newValue = newValue {
				PIUnprotectedPreferences.sharedInstance.setObject(newValue, forKey: kLastDownloadDate)
			} else {
				PIUnprotectedPreferences.sharedInstance.removeObjectForKey(kLastDownloadDate)
			}
		}
		get {
			return PIUnprotectedPreferences.sharedInstance.objectForKey(kLastDownloadDate) as? NSDate
		}
	}

	static var lastDownloadErrorDate:NSDate? {
		set {
			if let newValue = newValue {
				PIUnprotectedPreferences.sharedInstance.setObject(newValue, forKey: kLastDownloadErrorDate)
			} else {
				PIUnprotectedPreferences.sharedInstance.removeObjectForKey(kLastDownloadErrorDate)
			}
		}
		get {
			return PIUnprotectedPreferences.sharedInstance.objectForKey(kLastDownloadErrorDate) as? NSDate
		}
	}

	static var downloadErrorCount:Int? {
		set {
			if let newValue = newValue {
				PIUnprotectedPreferences.sharedInstance.setInteger(newValue, forKey: kErrorDownloadCountKey)
			} else {
				PIUnprotectedPreferences.sharedInstance.removeObjectForKey(kErrorDownloadCountKey)
			}
		}
		get {
			return PIUnprotectedPreferences.sharedInstance.integerForKey(kErrorDownloadCountKey)
		}
	}

	static func resetDownloadErrors() {
		downloadErrorCount = nil
		lastDownloadErrorDate = nil
		synchronize()
	}

	static func downloadError() {
		guard downloadErrorCount < maxDownloadRetry else {
			DDLogError("Too many errors for the download, wait until tomorrow")
			resetDownloadErrors()
			return
		}
		lastDownloadErrorDate = NSDate()
		downloadErrorCount = (downloadErrorCount ?? 0) + 1
		synchronize()
	}

	static var lastSyncDate:NSDate? {
		set {
			if let newValue = newValue {
				PIUnprotectedPreferences.sharedInstance.setObject(newValue, forKey: kLastSyncDate)
			} else {
				PIUnprotectedPreferences.sharedInstance.removeObjectForKey(kLastSyncDate)
			}
			synchronize()
		}
		get {
			return PIUnprotectedPreferences.sharedInstance.objectForKey(kLastSyncDate) as? NSDate
		}
	}

	static func synchronize() {
		PIUnprotectedPreferences.sharedInstance.synchronize()
	}

	static var maxDownloadRetry:Int {
		set {
			PIUnprotectedPreferences.sharedInstance.setInteger(newValue, forKey: kMaxDownloadRetry)
			synchronize()
		}
		get {
			let max = PIUnprotectedPreferences.sharedInstance.integerForKey(kMaxDownloadRetry)
			if max > 0 {
				return max
			} else {
				return 10
			}
		}
	}


}