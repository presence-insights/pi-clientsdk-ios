/**
*  PIOutdoorSDK
*  PIGeofencingManager+CLLocationManagerDelegate.swift
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


import CoreLocation
import CocoaLumberjack


extension PIGeofencingManager: CLLocationManagerDelegate {

	public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus){
		switch status {
		case .AuthorizedAlways:
			fallthrough
		case .AuthorizedWhenInUse:
			self.locationManager.startMonitoringSignificantLocationChanges()
			DDLogVerbose("startMonitoringSignificantLocationChanges")
		case .Denied:
			break
		case .NotDetermined:
			break
		case .Restricted:
			break

		}

	}

	public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		DDLogVerbose("didUpdateLocations")
		self.updateGeofenceMonitoring()
	}

	public func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion){
		guard let geofence = self.queryGeofence(region.identifier) else {
			DDLogError("didEnterRegion Region \(region.identifier) not found")
			self.delegate?.geofencingManager(self, didEnterGeofence: nil)
			return
		}

		DDLogVerbose("didEnterRegion \(region.identifier) \(geofence.name)")

		self.sendPIGeofenceEvent(.Enter, geofence: geofence)

		self.delegate?.geofencingManager(self, didEnterGeofence: geofence)

	}

	public func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion){

		guard let geofence = self.queryGeofence(region.identifier) else {
			DDLogError("didExitRegion Region \(region.identifier) not found")
			self.delegate?.geofencingManager(self, didExitGeofence: nil)
			return
		}

		DDLogVerbose("didExitRegion \(region.identifier) \(geofence.name)")

		self.sendPIGeofenceEvent(.Exit, geofence: geofence)

		self.delegate?.geofencingManager(self, didExitGeofence: geofence)

	}


	private func sendPIGeofenceEvent(event:PIGeofenceEvent,geofence: PIGeofence?) {

		guard privacy == false else {
			DDLogVerbose("sendPIGeofenceEvent \(geofence?.name) \(event), privacyOn !!!")
			return
		}

		guard let geofence = geofence else {
			DDLogError("****** sendPIGeofenceEvent, Missing fence",asynchronous:false)
			return
		}

		guard let _ = service.orgCode else {
			DDLogError("****** sendPIGeofenceEvent, No Organization Code",asynchronous:false)
			return
		}

		let application = UIApplication.sharedApplication()
		var bkgTaskId = UIBackgroundTaskInvalid
		bkgTaskId = application.beginBackgroundTaskWithExpirationHandler {
			if bkgTaskId != UIBackgroundTaskInvalid {
				DDLogError("****** PIGeofenceMonitoringRequest ExpirationHandler \(bkgTaskId)",asynchronous:false)
				self.service.cancelAll()
				let id = bkgTaskId
				bkgTaskId = UIBackgroundTaskInvalid
				application.endBackgroundTask(id)
			}
		}
		if bkgTaskId == UIBackgroundTaskInvalid {
			DDLogError("****** No background time for PIGeofenceMonitoringRequest",asynchronous:false)
		}

		DDLogInfo("PIGeofenceMonitoringRequest beginBackgroundTaskWithExpirationHandler \(bkgTaskId)")

		DDLogInfo("Create PIGeofenceMonitoringRequest \(geofence.code) , \(geofence.name), \(event.rawValue)")

		let piRequest = PIGeofenceMonitoringRequest(geofenceCode:geofence.code,eventTime:NSDate(),event:event,geofenceName: geofence.name) {
			response in
			switch response.result {
			case let .HTTPStatus(status,_)?:
				DDLogError("****** PIGeofenceMonitoringRequest status \(status)",asynchronous:false)
				DDLogError("****** PIGeofenceMonitoringRequest \(response.httpRequest)",asynchronous:false)
			case let .Error(error)?:
				DDLogError("****** PIGeofenceMonitoringRequest error \(error)",asynchronous:false)
			case let .Exception(exception)?:
				DDLogError("****** PIGeofenceMonitoringRequest exception \(exception)",asynchronous:false)
			case .Cancelled?:
				DDLogVerbose("****** PIGeofenceMonitoringRequest cancelled")
			case .OK?:
				DDLogInfo("PIGeofenceMonitoringRequest OK \(event.rawValue) : \(geofence.code)")
			case nil:
				break
			}
			dispatch_async(dispatch_get_main_queue()) {
				if bkgTaskId != UIBackgroundTaskInvalid {
					DDLogInfo("****** PIGeofenceMonitoringRequest endBackgroundTask \(bkgTaskId)")
					let id = bkgTaskId
					bkgTaskId = UIBackgroundTaskInvalid
					application.endBackgroundTask(id)
				}
			}
		}

		service.executeRequest(piRequest)

	}


}