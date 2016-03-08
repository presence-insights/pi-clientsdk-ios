/**
*  IBMPIGeofence
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
				throw PIGeofencingError.UnzipOpenFile(url.path!)
			}
			guard zip.UnzipFileTo(tmpDirectoryURL.path!, overWrite: true) else {
				throw PIGeofencingError.UnzipFileTo(tmpDirectoryURL.path!)

			}

			let unzippedFiles = zip.unzippedFiles as! [String]

			guard zip.UnzipCloseFile() else {
				throw PIGeofencingError.UnzipCloseFile
			}

			for file in unzippedFiles {
				DDLogVerbose("geojson \(file)",asynchronous:false)
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
					NSNotificationCenter.defaultCenter().postNotificationName(kGeofenceManagerDidSynchronize, object: nil)
					completionHandler?(error:error)
				}
			}

	}

	func seedGeojson(moc:NSManagedObjectContext,geojson:[String:AnyObject],
		propertiesGenerator:GeofencePropertiesGenerator? = nil) -> ErrorType? {

			guard let type = geojson["type"] as? String else {
				return PIGeofencingError.GeoJsonMissingType
			}

			guard type == "FeatureCollection" else {
				return PIGeofencingError.GeoJsonWrongType(type)
			}

			guard let properties = geojson["properties"] as? [String:AnyObject] else {
				return PIGeofencingError.GeoJsonMissingFeatureCollectionProperties
			}

			let totalFeatures = properties["totalFeatures"] as? Int
			DDLogVerbose("TotalFeatures downloaded \(totalFeatures)")

			let pageSize = properties["pageSize"] as? Int
			DDLogVerbose("PageSize \(pageSize)")

			guard var geofences = geojson["features"] as? [[String:AnyObject]] else {
				return PIGeofencingError.GeoJsonNoFeature
			}

			DDLogVerbose("--- \(geofences.count)",asynchronous:false)

			geofences.sortInPlace { (fencea, fenceb) -> Bool in
				guard let propertiesa = fencea["properties"] as? [String:AnyObject] else {
					return true
				}
				guard let propertiesb = fenceb["properties"] as? [String:AnyObject] else {
					return true
				}
				guard let geofenceCodea = propertiesa["@code"] as? String else {
					return true
				}
				guard let geofenceCodeb = propertiesb["@code"] as? String else {
					return true
				}

				return geofenceCodea < geofenceCodeb
			}

			for fence in geofences {
				guard let properties = fence["properties"] as? [String:AnyObject] else {
					continue
				}
				guard let code = properties["@code"] as? String else {
					continue
				}

				DDLogVerbose(code,asynchronous:false)
			}

			do {
				let request = PIGeofence.fetchRequest
				request.sortDescriptors = [NSSortDescriptor(key: "code", ascending: true)]
				
				let existingFences = try moc.executeFetchRequest(request) as! [PIGeofence]
				for fence in existingFences {
					DDLogVerbose(fence.code,asynchronous:false)
				}

				var nbErrors = 0
				var iCurrentFence = 0
				var nbDeleted = 0
				var nbInserted = 0
				var nbUpdated = 0

				for (i,fence) in geofences.enumerate() {
					guard let properties = fence["properties"] as? [String:AnyObject] else {
						DDLogError("\(i) Missing properties",asynchronous:false)
						nbErrors += 1
						continue
					}

					// LEGACY
					if let deleted = properties["@deleted"] as? Bool where deleted {
						if let geofenceCode = properties["@code"] as? String {
							DDLogInfo("Deleted Geofence \(geofenceCode)",asynchronous:false)
						} else {
							DDLogError("Deleted Geofence Unknown",asynchronous:false)
						}
						continue
					}

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
						DDLogError("\(i) Does not support geometry \(geometry_type)",asynchronous:false)
						nbErrors += 1
						continue
					}

					guard let coordinates = geometry["coordinates"] as? [NSNumber] else {
						DDLogError("\(i) Missing coordinates",asynchronous:false)
						nbErrors += 1
						continue
					}

					guard coordinates.count == 2 else {
						DDLogError("\(i) Wrong number of coordinates",asynchronous:false)
						nbErrors += 1
						continue
					}

					let latitude = coordinates[1]
					let longitude = coordinates[0]

					let name:String
					let radius:Int
					let geofenceCode:String

					if let propertiesGenerator = propertiesGenerator {
						let properties = propertiesGenerator(properties)
						name = properties.name
						radius = properties.radius
						guard let code = properties.code else {
							DDLogError("\(i) Missing geofence code",asynchronous:false)
							nbErrors += 1
							continue
						}
						geofenceCode = code
					} else {
						name = properties["name"] as? String ?? "???!!!"
						radius = properties["radius"] as? Int ?? 100
						guard let code = properties["@code"] as? String else {
							DDLogError("\(i) Missing geofence code",asynchronous:false)
							nbErrors += 1
							continue
						}
						geofenceCode = code
					}

					guard let orgCode = properties["@org"] as? String else {
						DDLogError("\(i) Missing org code",asynchronous:false)
						nbErrors += 1
						continue
					}
					if orgCode != self.service.orgCode {
						DDLogError("\(i) Wrong org code \(geofenceCode), current org code is \(self.service.orgCode)",asynchronous:false)
						nbErrors += 1
						continue
					}

					var newFence = true

					while iCurrentFence < existingFences.count {
						let currentFence = existingFences[iCurrentFence]
						if currentFence.code == geofenceCode {
							// Fence already here
							var updated = false
							if name != currentFence.name {
								DDLogVerbose("old name \(currentFence.name), new Name \(name)",asynchronous:false)
								currentFence.name = name
								updated = true
							}
							if latitude != currentFence.latitude {
								DDLogVerbose("old latitude \(currentFence.latitude), new latitude \(latitude)",asynchronous:false)
								currentFence.latitude = latitude
								updated = true
							}
							if longitude != currentFence.longitude {
								DDLogVerbose("old longitude \(currentFence.longitude), new longitude \(longitude)",asynchronous:false)
								currentFence.longitude = longitude
								updated = true
							}
							if radius != currentFence.radius {
								DDLogVerbose("old radius \(currentFence.radius), new radius \(radius)",asynchronous:false)
								currentFence.radius = radius
								updated = true
							}
							if updated {
								DDLogVerbose("Update Geofence \(name) \(geofenceCode)",asynchronous:false)
								nbUpdated += 1
							}
							iCurrentFence += 1
							newFence = false
							break
						}
						if currentFence.code < geofenceCode {

							DDLogVerbose("Delete Geofence \(currentFence.name) \(currentFence.code)",asynchronous:false)
							moc.deleteObject(currentFence)
							nbDeleted += 1
							iCurrentFence += 1
							continue
						}

						// new geofence
						break

					}

					if newFence {

						let geofence:PIGeofence = moc.insertObject()

						geofence.name = name
						geofence.radius = radius
						geofence.code = geofenceCode
						geofence.latitude = latitude
						geofence.longitude = longitude
						nbInserted += 1
						DDLogVerbose("Insert Geofence \(name) \(geofenceCode)",asynchronous:false)
					}

				}

				// Remaining local hazard events we didn't iterate over
				while iCurrentFence < existingFences.count {
					let currentFence = existingFences[iCurrentFence]
					iCurrentFence += 1

					moc.deleteObject(currentFence)
					nbDeleted += 1
				}

				try moc.save()

				DDLogVerbose("Inserted \(nbInserted)",asynchronous:false)
				DDLogVerbose("Deleted \(nbDeleted)",asynchronous:false)
				DDLogVerbose("Updated \(nbUpdated)",asynchronous:false)

				if nbErrors == 0 {
					return nil
				} else {
					return PIGeofencingError.WrongFences(nbErrors)
				}
			} catch {
				DDLogError("Core Data Error \(error)")
				assertionFailure("Core Data Error \(error)")
				return PIGeofencingError.InternalError(error)
			}
	}


}