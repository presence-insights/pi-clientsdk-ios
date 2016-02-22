/**
*  PIOutdoorSDK
*  PIGeofencingManager+Seeding.swift
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

import ZipArchive
import UIKit
import CoreData
import CocoaLumberjack

extension PIGeofencingManager {

	/**
	Sets the list of the fences to be monitored

	- paremeter url:
	- parameter propertiesGenerator:
	- parameter completionHandler:

	*/

	public func seedGeojson(
		url:NSURL,
		propertiesGenerator:GeofencePropertiesGenerator? = nil,
		completionHandler:((error:ErrorType?) -> Void)? = nil) throws {

			let fileManager = NSFileManager.defaultManager()
			let zip = ZipArchive(fileManager:fileManager)

			let tmpDirectoryURL = NSURL.fileURLWithPath(NSTemporaryDirectory(), isDirectory: true)

			guard zip.UnzipOpenFile(url.path!) else {
				throw PIOutdoorError.UnzipOpenFile(url.path!)
			}
			guard zip.UnzipFileTo(tmpDirectoryURL.path!, overWrite: true) else {
				throw PIOutdoorError.UnzipFileTo(tmpDirectoryURL.path!)

			}

			let unzippedFiles = zip.unzippedFiles as! [String]

			guard zip.UnzipCloseFile() else {
				throw PIOutdoorError.UnzipCloseFile
			}

			for file in unzippedFiles {
				DDLogVerbose("geojson \(file)")
				let url = NSURL(fileURLWithPath: file)
				let data = try NSData(contentsOfURL: url, options: .DataReadingMappedAlways)
				guard let jsonObject = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject] else {
					continue
				}
				seedGeojson(jsonObject, propertiesGenerator:propertiesGenerator,completionHandler: completionHandler)

			}


	}

	// http://geojson.org/geojson-spec.html

	/**
	Sets the list of the fences to be monitored

	- paremeter geojson:    A geojson list of fences
	- parameter local:      `true` if the list is defined locally, `false`if the list is defined by the backend
	*/

	public func seedGeojson(
		geojson:[String:AnyObject],
		propertiesGenerator:GeofencePropertiesGenerator? = nil,
		completionHandler:((error:ErrorType?) -> Void)? = nil)  {

			let moc = dataController.writerContext

			moc.performBlock {
				defer {
					moc.reset()
				}
				let error = self.seedGeojson(moc,
					geojson: geojson,
					propertiesGenerator: propertiesGenerator)
				self.updateMonitoredGeofencesWithMoc(moc)
				dispatch_async(dispatch_get_main_queue()) {
					completionHandler?(error:error)
				}
			}

	}

	func seedGeojson(moc:NSManagedObjectContext,geojson:[String:AnyObject],
		propertiesGenerator:GeofencePropertiesGenerator? = nil) -> ErrorType? {

			guard let type = geojson["type"] as? String else {
				return PIOutdoorError.GeoJsonMissingType
			}

			guard type == "FeatureCollection" else {
				return PIOutdoorError.GeoJsonWrongType(type)
			}


			guard let geofences = geojson["features"] as? [[String:AnyObject]] else {
				return PIOutdoorError.GeoJsonNoFeature
			}

			var nbErrors = 0
			for (i,fence) in geofences.enumerate() {
				guard let type = fence["type"] as? String else {
					DDLogError("\(i) Missing type property",asynchronous:false)
					nbErrors += 1
					continue
				}
				guard type == "Feature" else {
					DDLogError("\(i) Wrong type \(type)",asynchronous:false)
					nbErrors += 1
					continue
				}
				guard let geometry = fence["geometry"] as? [String:AnyObject] else {
					DDLogError("\(i) Missing geometry",asynchronous:false)
					nbErrors += 1
					continue
				}

				guard let geometry_type = geometry["type"] as? String else {
					DDLogError("\(i) Missing geometry type",asynchronous:false)
					nbErrors += 1
					continue
				}
				guard geometry_type == "Point" else {
					DDLogError("\(i) Does not support geometry \(geometry_type)")
					nbErrors += 1
					continue
				}

				guard let coordinates = geometry["coordinates"] as? [NSNumber] else {
					DDLogError("\(i) Missing coordinates",asynchronous:false)
					nbErrors += 1
					continue
				}

				guard coordinates.count == 2 else {
					DDLogError("\(i) Wrong number of coordinates")
					nbErrors += 1
					continue
				}

				let latitude = coordinates[1]
				let longitude = coordinates[0]

				guard let properties = fence["properties"] as? [String:AnyObject] else {
					DDLogError("\(i) Missing properties",asynchronous:false)
					nbErrors += 1
					continue
				}

				let name:String
				let radius:Int
				let geofenceCode:String

				if let propertiesGenerator = propertiesGenerator {
					let properties = propertiesGenerator(properties)
					name = properties.name
					radius = properties.radius
					geofenceCode = properties.code ??  NSUUID().UUIDString
				} else {
					name = properties["name"] as? String ?? "???!!!"
					radius = properties["radius"] as? Int ?? 100
					geofenceCode = properties["uuid"] as? String ?? NSUUID().UUIDString
				}

				let geofence:PIGeofence = moc.insertObject()

				geofence.name = name
				geofence.radius = radius
				geofence.code = geofenceCode
				geofence.latitude = latitude
				geofence.longitude = longitude
			}

			do {
				try moc.save()

				if nbErrors == 0 {
					return nil
				} else {
					return PIOutdoorError.WrongFences(nbErrors)
				}
			} catch {
				DDLogError("Core Data Error \(error)",asynchronous:false)
				assertionFailure("Core Data Error \(error)")
				return PIOutdoorError.InternalError(error)
			}
	}


}