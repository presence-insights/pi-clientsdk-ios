/**
*  PIOutdoorSDK
*  PIGeofencingManager+UpdateMonitoredGeofences.swift
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


import CoreData
import CocoaLumberjack
import MapKit

extension PIGeofencingManager {
	/**
	This function should be called when a significant location changed is detected
	It updates the list of the monitored region, the limit being 20 regions per app
	*/
	func updateMonitoredGeofences(completionHandler: (()-> Void)? = nil) {

		let moc = self.dataController.writerContext

		moc.performBlock {
			self.updateMonitoredGeofencesWithMoc(moc)
			dispatch_async(dispatch_get_main_queue()) {
				completionHandler?()
			}
		}

	}

	func compareGeofence(currentPosition:CLLocation)(a:PIGeofence,b:PIGeofence) -> Bool {
		let aLocation = CLLocation(latitude: a.latitude.doubleValue, longitude: a.longitude.doubleValue)
		var aDistance = currentPosition.distanceFromLocation(aLocation)
		if aDistance > a.radius.doubleValue {
			aDistance -= a.radius.doubleValue
		}
		let bLocation = CLLocation(latitude: b.latitude.doubleValue, longitude: b.longitude.doubleValue)
		var bDistance = currentPosition.distanceFromLocation(bLocation)
		if bDistance > b.radius.doubleValue {
			bDistance -= b.radius.doubleValue
		}

		return aDistance < bDistance

	}

	func updateMonitoredGeofencesWithMoc(moc:NSManagedObjectContext) {
		// https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/RegionMonitoring/RegionMonitoring.html
		/*

		Be judicious when specifying the set of regions to monitor. Regions are a shared system resource, and the total number of regions available systemwide is limited. For this reason, Core Location limits to 20 the number of regions that may be simultaneously monitored by a single app. To work around this limit, consider registering only those regions in the user’s immediate vicinity. As the user’s location changes, you can remove regions that are now farther way and add regions coming up on the user’s path. If you attempt to register a region and space is unavailable, the location manager calls the locationManager:monitoringDidFailForRegion:withError: method of its delegate with the kCLErrorRegionMonitoringFailure error code.
		*/

		/*
		When testing your region monitoring code in iOS Simulator or on a device, realize that region events may not happen immediately after a region boundary is crossed. To prevent spurious notifications, iOS doesn’t deliver region notifications until certain threshold conditions are met. Specifically, the user’s location must cross the region boundary, move away from the boundary by a minimum distance, and remain at that minimum distance for at least 20 seconds before the notifications are reported.

		The specific threshold distances are determined by the hardware and the location technologies that are currently available. For example, if Wi-Fi is disabled, region monitoring is significantly less accurate. However, for testing purposes, you can assume that the minimum distance is approximately 200 meters.
		*/


		guard let currentPosition = locationManager.location else {
			DDLogError("A significant location change occurred, but there is no location data")
			return
		}

		DDLogVerbose("Current position \(currentPosition.coordinate)")

		// Compute North East and South West coordinates of the bbox of the regions
		// which could be monitored
		let region = MKCoordinateRegionMakeWithDistance(currentPosition.coordinate, Double(maxDistance), Double(maxDistance))

		let nw_lat_ = region.center.latitude + 0.5 * region.span.latitudeDelta
		let nw_lon_ = region.center.longitude - 0.5 * region.span.longitudeDelta
		let se_lat_ = region.center.latitude - 0.5 * region.span.latitudeDelta
		let se_lon_ = region.center.longitude + 0.5 * region.span.longitudeDelta

		let nw = CLLocationCoordinate2D(latitude: nw_lat_, longitude: nw_lon_)
		let se = CLLocationCoordinate2D(latitude: se_lat_, longitude: se_lon_)

		do {
			if self.regions == nil {
				// either the first time we monitor or the app has been unloaded
				// find the regions currently being monitored
				DDLogVerbose("Initialize the regions to monitor")
				let fetchMonitoredRegionsRequest = PIGeofence.fetchRequest

				fetchMonitoredRegionsRequest.predicate = NSPredicate(format: "monitored == true")
				guard let monitoredGeofences = try moc.executeFetchRequest(fetchMonitoredRegionsRequest) as? [PIGeofence] else {
					DDLogError("Programming error",asynchronous:false)
					assertionFailure("Programming error")
					return
				}

				if monitoredGeofences.count == 0 {
					DDLogVerbose("No region to monitor!")
				}

				self.regions = [:]
				for geofence in monitoredGeofences {
					let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: geofence.latitude.doubleValue, longitude: geofence.longitude.doubleValue), radius: geofence.radius.doubleValue, identifier: geofence.code)
					DDLogVerbose("already monitoring \(geofence.name) \(geofence.code)")
					self.regions?[geofence.code] = region
					let monitoredRegions = self.locationManager.monitoredRegions.filter {
						$0.identifier == region.identifier
					}
					if monitoredRegions.isEmpty {
						DDLogError("Error \(geofence.name) \(geofence.code) not found in CLLocationManager.monitoredRegions")
					}

				}
			}

			// find the geofences in the bbox of the current position
			let fetchRequest = PIGeofence.fetchRequest
			// We will need to access properties of all returned objects
			fetchRequest.returnsObjectsAsFaults = false
			// Filter out regions which are too far
			fetchRequest.predicate = NSPredicate(format: "latitude < \(nw.latitude) and latitude > \(se.latitude) and longitude > \(nw.longitude) and longitude < \(se.longitude)")
			guard let nearFences = try moc.executeFetchRequest(fetchRequest) as? [PIGeofence] else {
				DDLogError("Programming error",asynchronous:false)
				assertionFailure("Programming error")
				return
			}

			// Sort fences in ascending order starting from the nearest fence
			let sortedFences = nearFences.sort(self.compareGeofence(currentPosition))

			// Keep the first maxRegions regions to stay under the system wide limit
			let max = sortedFences.count < self.maxRegions ? sortedFences.count : self.maxRegions
			let fencesToMonitor = sortedFences[0..<max]

			let geofenceCodes = Set(fencesToMonitor.map { $0.code })

			var keepRegions = [String:CLCircularRegion]()

			var regionsToStop: [CLRegion] = []

			// Stop monitoring regions that are too far
			for (geofenceCode,region) in self.regions! {
				if geofenceCodes.contains(geofenceCode) == false {
					regionsToStop.append(region)
					let fetchRequest =  PIGeofence.fetchRequest
					fetchRequest.predicate = NSPredicate(format: "code == %@", geofenceCode)
					let geofences = try moc.executeFetchRequest(fetchRequest) as? [PIGeofence]
					if let geofence = geofences?.first {
						geofence.monitored = false
						DDLogVerbose("Too far, will stopMonitoringForRegion \(geofence.name) \(geofenceCode)")
					} else {
						DDLogError("Region \(geofenceCode) not found, can't stopMonitoringForRegion")
					}
				} else {
					// keep the region
					keepRegions[geofenceCode] = region
				}
			}

			self.regions = keepRegions

			var regionsToStart: [CLRegion] = []
			// Start monitoring new regions near our current position
			for geofence in fencesToMonitor {
				guard self.regions?[geofence.code] == nil else {
					// We are already monitoring this fence
					continue
				}
				geofence.monitored = true
				let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: geofence.latitude.doubleValue, longitude: geofence.longitude.doubleValue), radius: geofence.radius.doubleValue, identifier: geofence.code)
				regionsToStart.append(region)
				self.regions?[geofence.code] = region
				DDLogVerbose("will startMonitoringForRegion \(geofence.name) \(region.identifier)")
			}

			try moc.save()

			for region in regionsToStop {
				self.locationManager.stopMonitoringForRegion(region)
				DDLogVerbose("did stopMonitoringForRegion \(region.identifier)")
			}
			for region in regionsToStart {
				self.locationManager.startMonitoringForRegion(region)
				DDLogVerbose("did startMonitoringForRegion \(region.identifier)")
			}

		} catch {
			DDLogError("Core Data Error \(error)")
			assertionFailure("Core Data Error \(error)")
		}

	}
}
