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
		}
	}
	
	public func didCompleteWithError(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {

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
				download.progressStatus = .Error

				try moc.save()

			} catch {
				DDLogError("PIGeofencingManager.didReceiveFile error \(error)",asynchronous:false)
			}
		}
	}
	public func didReceiveFile(session: NSURLSession, downloadTask: NSURLSessionDownloadTask,geofencesURL:NSURL) {

		let moc = dataController.writerContext
		moc.performBlock {
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
				download.progressStatus = .OK
				download.progress = 1
				
				try moc.save()
				
			} catch {
				DDLogError("PIGeofencingManager.didReceiveFile error \(error)",asynchronous:false)
			}
		}
	}


}