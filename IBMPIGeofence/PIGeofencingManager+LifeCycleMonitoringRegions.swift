//
//  PIGeofencingManager+LifeCycleMonitoringRegions.swift
//  PIOutdoorSDK
//
//  Created by slizeray on 23/02/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation
import CocoaLumberjack
import CoreLocation
import CoreData

extension PIGeofencingManager {


	public func startMonitoringRegions() {
		DDLogInfo("Start Monitoring",asynchronous:false)
		self.locationManager.startMonitoringSignificantLocationChanges()

	}


	public func stopMonitoringRegions(completionHandler: (()-> Void)? = nil) {

		DDLogInfo("Stop Monitoring",asynchronous:false)
		locationManager.stopMonitoringSignificantLocationChanges()

		let moc = self.dataController.writerContext

		moc.performBlock {
			self.stopMonitoringRegionsWithMoc(moc)
			dispatch_async(dispatch_get_main_queue()) {
				completionHandler?()
			}
		}

	}

	func stopMonitoringRegionsWithMoc(moc:NSManagedObjectContext) {
		do {
			// find the regions currently being monitored
			DDLogVerbose("Stop monitoring all the regions",asynchronous:false)
			let fetchMonitoredRegionsRequest = PIGeofence.fetchRequest

			fetchMonitoredRegionsRequest.predicate = NSPredicate(format: "monitored == true")
			guard let monitoredGeofences = try moc.executeFetchRequest(fetchMonitoredRegionsRequest) as? [PIGeofence] else {
				DDLogError("Programming error",asynchronous:false)
				assertionFailure("Programming error")
				return
			}

			if monitoredGeofences.count == 0 {
				DDLogVerbose("No region to stop!",asynchronous:false)
				return
			}

			var regionsToStop: [CLRegion] = []
			for geofence in monitoredGeofences {
				geofence.monitored = false
				if let region = self.regions?[geofence.code] {
					regionsToStop.append(region)
				} else {
					DDLogError("Region to stop not found \(geofence.code)")
				}
			}

			try moc.save()

			self.regions = nil

			dispatch_async(dispatch_get_main_queue()) {
				for region in regionsToStop {
					self.locationManager.stopMonitoringForRegion(region)
					DDLogVerbose("Stop monitoring \(region.identifier)",asynchronous:false)
				}
			}

		} catch {
			DDLogError("Core Data Error \(error)",asynchronous:false)
		}

	}


	public func reset(completionHandler: ((Void) -> Void)? = nil) {
		self.stopMonitoringRegions {
			do {
				try self.dataController.removeStore()
				completionHandler?()
			} catch {
				DDLogError("Core Data Error \(error)",asynchronous:false)
				assertionFailure()
				completionHandler?()
			}
			
		}
	}

}