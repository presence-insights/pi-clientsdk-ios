/**
*  PIOutdoorSDK
*  PIGeofencingManager+PIServiceDelegate.swift
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

import UIKit
import CocoaLumberjack

extension PIGeofencingManager: PIServiceDelegate {

	public func didProgress(session: NSURLSession, downloadTask: NSURLSessionDownloadTask,progress:Float) {

		let application = UIApplication.sharedApplication()
		var bkgTaskId = UIBackgroundTaskInvalid
		bkgTaskId = application.beginBackgroundTaskWithExpirationHandler {
			if bkgTaskId != UIBackgroundTaskInvalid {
				DDLogError("****** PIGeofencingManager.didProgress ExpirationHandler \(bkgTaskId)",asynchronous:false)
				let id = bkgTaskId
				bkgTaskId = UIBackgroundTaskInvalid
				application.endBackgroundTask(id)
			}
		}
		if bkgTaskId == UIBackgroundTaskInvalid {
			DDLogError("****** No background time for PIGeofencingManager.didProgress!!!",asynchronous:false)
		}

		DDLogVerbose("PIGeofencingManager.didProgress beginBackgroundTaskWithExpirationHandler \(bkgTaskId)")

		DDLogVerbose("PIGeofencingManager.didProgress \(progress)")

		let moc = dataController.writerContext
		moc.performBlock {
			let request = PIDownload.fetchRequest
			request.predicate = NSPredicate(format: "sessionIdentifier = %@ and taskIdentifier = %@", session.configuration.identifier!,downloadTask.taskIdentifier)
			do {
				let downloads = try moc.executeFetchRequest(request) as! [PIDownload]
				guard let download = downloads.first  else {
					DDLogError("PIGeofencingManager.didReceiveFile download not found")
					return
				}
				guard downloads.count == 1 else {
					DDLogError("PIGeofencingManager.didReceiveFile more than one download!")
					return
				}
				download.progress = progress

				try moc.save()

			} catch {
				DDLogError("PIGeofencingManager.didReceiveFile error \(error)",asynchronous:false)
			}
			dispatch_async(dispatch_get_main_queue()) {
				if bkgTaskId != UIBackgroundTaskInvalid {
					DDLogVerbose("****** PIGeofencingManager.didProgress endBackgroundTask \(bkgTaskId)",asynchronous:false)
					let id = bkgTaskId
					bkgTaskId = UIBackgroundTaskInvalid
					application.endBackgroundTask(id)
				}
			}

		}
	}

	public func didCompleteWithError(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {

		guard let _ = error else {
			return
		}

		let application = UIApplication.sharedApplication()
		var bkgTaskId = UIBackgroundTaskInvalid
		bkgTaskId = application.beginBackgroundTaskWithExpirationHandler {
			if bkgTaskId != UIBackgroundTaskInvalid {
				DDLogError("****** PIGeofencingManager.didCompleteWithError ExpirationHandler \(bkgTaskId)",asynchronous:false)
				let id = bkgTaskId
				bkgTaskId = UIBackgroundTaskInvalid
				application.endBackgroundTask(id)
			}
		}
		if bkgTaskId == UIBackgroundTaskInvalid {
			DDLogError("****** No background time for PIGeofencingManager.didCompleteWithError!!!",asynchronous:false)
		}

		DDLogVerbose("PIGeofencingManager.didCompleteWithError beginBackgroundTaskWithExpirationHandler \(bkgTaskId)")
		
		let moc = dataController.writerContext
		moc.performBlock {
			let request = PIDownload.fetchRequest
			request.predicate = NSPredicate(format: "sessionIdentifier = %@ and taskIdentifier = %lu", session.configuration.identifier!,task.taskIdentifier)
			do {
				let downloads = try moc.executeFetchRequest(request) as! [PIDownload]
				guard let download = downloads.first  else {
					DDLogError("PIGeofencingManager.didReceiveFile download not found",asynchronous:false)
					return
				}
				guard downloads.count == 1 else {
					DDLogError("PIGeofencingManager.didReceiveFile more than one download!",asynchronous:false)
					return
				}
				download.progressStatus = .NetworkError
				download.endDate = NSDate()

				try moc.save()

			} catch {
				DDLogError("PIGeofencingManager.didReceiveFile error \(error)",asynchronous:false)
			}
			dispatch_async(dispatch_get_main_queue()) {
				if bkgTaskId != UIBackgroundTaskInvalid {
					DDLogVerbose("****** PIGeofencingManager.didCompleteWithError endBackgroundTask \(bkgTaskId)",asynchronous:false)
					let id = bkgTaskId
					bkgTaskId = UIBackgroundTaskInvalid
					application.endBackgroundTask(id)
				}
			}
		}
	}
	
	public func didReceiveFile(session: NSURLSession, downloadTask: NSURLSessionDownloadTask,geofencesURL:NSURL) {

		let application = UIApplication.sharedApplication()
		var bkgTaskId = UIBackgroundTaskInvalid
		bkgTaskId = application.beginBackgroundTaskWithExpirationHandler {
			if bkgTaskId != UIBackgroundTaskInvalid {
				DDLogError("****** PIGeofencingManager.didReceiveFile ExpirationHandler \(bkgTaskId)",asynchronous:false)
				let id = bkgTaskId
				bkgTaskId = UIBackgroundTaskInvalid
				application.endBackgroundTask(id)
			}
		}
		if bkgTaskId == UIBackgroundTaskInvalid {
			DDLogError("****** No background time for PIGeofencingManager.didReceiveFile!!!",asynchronous:false)
		}

		let moc = dataController.writerContext
		moc.performBlock {
			defer {
				moc.reset()
			}
			let request = PIDownload.fetchRequest
			request.predicate = NSPredicate(format: "sessionIdentifier = %@ and taskIdentifier = %lu", session.configuration.identifier!,downloadTask.taskIdentifier)
			do {
				let downloads = try moc.executeFetchRequest(request) as! [PIDownload]
				guard let download = downloads.first  else {
					DDLogError("PIGeofencingManager.didReceiveFile download not found",asynchronous:false)
					return
				}
				guard downloads.count == 1 else {
					DDLogError("PIGeofencingManager.didReceiveFile more than one download!",asynchronous:false)
					return
				}
				download.progressStatus = .Received
				download.progress = 1
				download.endDate = NSDate()
				download.url = geofencesURL.absoluteString
				try moc.save()
				do {
					let data = try NSData(contentsOfURL: geofencesURL, options: .DataReadingMappedAlways)
					if let jsonObject = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject] {
						if let _ = self.seedGeojson(moc, geojson: jsonObject)  {
							download.progressStatus = .ProcessingError
						} else {
							download.progressStatus = .Processed
							DDLogInfo("PIGeofencingManager.updateGeofences OK!!!",asynchronous:false)
						}
					} else {
						DDLogError("PIGeofencingManager.updateGeofences Can't read json file",asynchronous:false)
						download.progressStatus = .ProcessingError
					}
				} catch {
					DDLogError("PIGeofencingManager.updateGeofences error \(error)",asynchronous:false)
					download.progressStatus = .ProcessingError
				}
				try moc.save()

			} catch {
				DDLogError("PIGeofencingManager.didReceiveFile error \(error)",asynchronous:false)
			}
			self.updateMonitoredGeofencesWithMoc(moc)
			dispatch_async(dispatch_get_main_queue()) {
				if bkgTaskId != UIBackgroundTaskInvalid {
					DDLogVerbose("****** PIGeofencingManager.didReceiveFile endBackgroundTask \(bkgTaskId)",asynchronous:false)
					let id = bkgTaskId
					bkgTaskId = UIBackgroundTaskInvalid
					application.endBackgroundTask(id)
				}
			}
		}
	}

}