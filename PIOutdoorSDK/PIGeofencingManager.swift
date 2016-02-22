/**
 *  PIOutdoorSDK
 *  PIGeofencingManager.swift
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
import CoreLocation
import CoreData
import MapKit
import ZipArchive
import CocoaLumberjack

public enum PIOutdoorError:ErrorType {
    case UnzipOpenFile(String)
    case UnzipFileTo(String)
    case EmptyZipFile(NSURL)
    case UnzipCloseFile
    
    case GeoJsonMissingType
    case GeoJsonWrongType(String)
    case GeoJsonNoFeature
    
    case WrongFences(Int)
    case HTTPStatus(Int,AnyObject?)

	case DownloadError
    case InternalError(ErrorType)
}


public struct PIGeofenceProperties {
    public let name:String
    public let radius:Int
    public let code:String?
    
    public init(name:String,radius:Int,code:String?) {
        self.name = name
        self.radius = radius
        self.code = code
    }
}

public typealias GeofencePropertiesGenerator = ([String:AnyObject]) -> PIGeofenceProperties

public protocol PIGeofencingManagerDelegate:class {
    /// The device enters into a geofence
    func geofencingManager(manager: PIGeofencingManager, didEnterGeofence geofence: PIGeofence? )
    /// The device exits a geofence
    func geofencingManager(manager: PIGeofencingManager, didExitGeofence geofence: PIGeofence? )
}

/// `PIGeofencingManager` is your entry point to the PI Geofences.
/// Its responsability is to monitor the PI geofences. 
/// When the user enters or exits a geofence, `PIGeofencingManager` notifies
/// the Presence Insights backend
public final class PIGeofencingManager:NSObject {

	/// When `true`, the `PIGeofencingManager`does not post event against PIT backend
	public var privacy = false

    /// By default, `PIGeofencingManager` can monitore up to 15 regions simultaneously.
    public static let DefaultMaxRegions = 15
    
    let locationManager = CLLocationManager()
    
    private var regions:[String:CLCircularRegion]?
    
    /// The length of the sides of the bounding box used to find out
    /// which fences should be monitored.
    public let maxDistance:Int
    
    /// Maximum number of regions which can be monitored simultaneously.
    public let maxRegions:Int
    
    public lazy var dataController = PIOutdoor.dataController

	/// PI Service
    public let service:PIService
    
    public weak var delegate:PIGeofencingManagerDelegate?
    /// Create a `PIGeofencingManager` with the given PI connection parameters
	/// This initializer must be called in the main thread
    /// - parameter tenantCode: PI tenant
    /// - parameter orgCode: PI organisation
    /// - parameter baseURL: PI end point
    /// - parameter username: PI username
    /// - parameter password: PI password
    /// - parameter maxDistance: When a significant change location is triggered,
    /// `PIGeofencingManager` search for geofences within a square of side length 
    /// of maxDistance meters.
    /// - parameter maxRegions: The maximum number of regions being monitored at any time. The system
    /// limit is 20 regions per app. Default is 15
    public init(tenantCode:String, orgCode:String?, baseURL:String, username:String, password:String,maxDistance:Int = 10_000, maxRegions:Int = DefaultMaxRegions ) {
        
        self.maxDistance = maxDistance
        if (1...20).contains(maxRegions) {
            self.maxRegions = maxRegions
        } else {
            DDLogError("maxRegions \(maxRegions) is out of range")
            self.maxRegions = self.dynamicType.DefaultMaxRegions
        }
        self.service = PIService(tenantCode:tenantCode,orgCode:orgCode,baseURL:baseURL,username:username,password:password)
        super.init()
        self.locationManager.delegate = self

		self.service.delegate = self
		
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didBecomeActive:", name: UIApplicationWillEnterForegroundNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willResignActive:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
    }
    /// Enables or disables the logging
    /// - parameter enable: `true` to enable the logging
    public static func enableLogging(enable:Bool) {
        
        if enable {
            DDLog.addLogger(DDTTYLogger.sharedInstance()) // TTY = Xcode console
            DDLog.addLogger(DDASLLogger.sharedInstance()) // ASL = Apple System Logs
            
            let documentsFileManager = DDLogFileManagerDefault(logsDirectory:PIOutdoorUtils.documentsDirectory.path)
            
            let fileLogger: DDFileLogger = DDFileLogger(logFileManager: documentsFileManager) // File Logger
            fileLogger.rollingFrequency = 60*60*24  // 24 hours
            fileLogger.logFileManager.maximumNumberOfLogFiles = 7
            DDLog.addLogger(fileLogger)
        } else {
            DDLog.removeAllLoggers()
        }
    }

	public static func logFiles() -> [String] {
		let documentsFileManager = DDLogFileManagerDefault(logsDirectory:PIOutdoorUtils.documentsDirectory.path)

		return documentsFileManager.sortedLogFilePaths().map { String($0) }

	}

    /**
     Ask the back end for the latest geofences to monitor
     - parameter completionHandler:  The closure called when the synchronisation is completed
     */
	public func synchronize(completionHandler: ((Bool)-> Void)? = nil) {
        let request = PIGeofenceFencesDownloadRequest()
		guard let response = service.executeDownload(request) else {
			completionHandler?(false)
			return
		}

		let moc = dataController.writerContext
		moc.performBlock {
			let download:PIDownload = moc.insertObject()

			download.sessionIdentifier = response.backgroundSessionIdentifier
			download.taskIdentifier = response.taskIdentifier
			download.progressStatus = .InProgress
			download.startDate = NSDate()
			do {
				try moc.save()
				dispatch_async(dispatch_get_main_queue()) {
					completionHandler?(true)
				}
			} catch {
				DDLogError("Core Data Error \(error)",asynchronous:false)
				completionHandler?(false)
			}
		}

    }

	public func handleEventsForBackgroundURLSession(identifier: String, completionHandler: () -> Void) -> Bool {

		DDLogInfo("PIGeofencingManager.handleEventsForBackgroundURLSession",asynchronous:false)
		guard identifier.hasPrefix("com.ibm.PI") else {
			DDLogInfo("Not a  PIbackgroundURLSession",asynchronous:false)
			return false
		}

		self.service.backgroundURLSessionCompletionHandler = completionHandler
		let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(identifier)

		let session = NSURLSession(configuration: config, delegate: self.service, delegateQueue: nil)
		self.service.backgroundPendingSessions.insert(session)


		return true
	}

    func didBecomeActive(notification:NSNotification) {
    }
    
    /**
     Cancel all pending request when the app is going to background
     */
    func willResignActive(notification:NSNotification) {
        self.service.cancelAll()
    }
    
    /**
     This function should be called when a significant location changed is detected
     It updates the list of the monitored region, the limit being 20 regions per app
     */
	func updateGeofenceMonitoring(completionHandler: (()-> Void)? = nil) {
        
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
        
        let moc = self.dataController.writerContext
        
        moc.performBlock {
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
						dispatch_async(dispatch_get_main_queue()) {
							completionHandler?()
						}
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
					dispatch_async(dispatch_get_main_queue()) {
						completionHandler?()
					}
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
                
				dispatch_async(dispatch_get_main_queue()) {
					for region in regionsToStop {
						self.locationManager.stopMonitoringForRegion(region)
						DDLogVerbose("did stopMonitoringForRegion \(region.identifier)")
					}
					for region in regionsToStart {
						self.locationManager.startMonitoringForRegion(region)
						DDLogVerbose("did startMonitoringForRegion \(region.identifier)")
					}
					completionHandler?()
				}

            } catch {
                DDLogError("Core Data Error \(error)")
                assertionFailure("Core Data Error \(error)")
				dispatch_async(dispatch_get_main_queue()) {
					completionHandler?()
				}
            }
            
        }
        
    }
    
    private func compareGeofence(currentPosition:CLLocation)(a:PIGeofence,b:PIGeofence) -> Bool {
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

	public func startMonitoringRegions() {
		self.locationManager.startMonitoringSignificantLocationChanges()

	}
	

	public func stopMonitoringAllRegions(completionHandler: (()-> Void)? = nil) {

		locationManager.stopMonitoringSignificantLocationChanges()

		let moc = self.dataController.writerContext

		moc.performBlock {
			do {
				// find the regions currently being monitored
				DDLogVerbose("Stop monitoring all the regions")
				let fetchMonitoredRegionsRequest = PIGeofence.fetchRequest

				fetchMonitoredRegionsRequest.predicate = NSPredicate(format: "monitored == true")
				guard let monitoredGeofences = try moc.executeFetchRequest(fetchMonitoredRegionsRequest) as? [PIGeofence] else {
					DDLogError("Programming error",asynchronous:false)
					assertionFailure("Programming error")
					dispatch_async(dispatch_get_main_queue()) {
						completionHandler?()
					}
					return
				}

				if monitoredGeofences.count == 0 {
					DDLogVerbose("No region to stop!")
					dispatch_async(dispatch_get_main_queue()) {
						completionHandler?()
					}
					return
				}

				var regionsToStop: [CLRegion] = []
				for geofence in monitoredGeofences {
					geofence.monitored = false
					if let region = self.regions?[geofence.code] {
						regionsToStop.append(region)
					}
				}

				try moc.save()

				self.regions = nil

				dispatch_async(dispatch_get_main_queue()) {
					for region in regionsToStop {
						self.locationManager.stopMonitoringForRegion(region)
						DDLogVerbose("Stop monitoring \(region.identifier)")
					}
					completionHandler?()
				}

			} catch {
				DDLogError("Core Data Error \(error)")
				dispatch_async(dispatch_get_main_queue()) {
					completionHandler?()
				}
			}
		}

	}

	public func reset(completionHandler: ((Void) -> Void)? = nil) {
		self.stopMonitoringAllRegions {
			do {
				try self.dataController.removeStore()
				completionHandler?()
			} catch {
				DDLogError("Core Data Error \(error)")
				assertionFailure()
				completionHandler?()
			}

		}
	}
    ///
    /// - parameter code:   The code of the geofence to remove
	/// - parameter completionHandler: closure invoked on completion
	///
    public func removeGeofence(code:String,completionHandler: ((Bool) -> Void)? = nil) {
        let geofenceDeleteRequest = PIGeofenceDeleteRequest(geofenceCode: code) {
            response in
            switch response.result {
            case .OK?:
                DDLogInfo("PIGeofenceDeleteRequest OK")
                let moc = self.dataController.writerContext
                moc.performBlock {
                    do {
                        let fetchRequest =  PIGeofence.fetchRequest
                        fetchRequest.predicate = NSPredicate(format: "code == %@",code)
                        guard let geofences = try moc.executeFetchRequest(fetchRequest) as? [PIGeofence] else {
                            DDLogError("Programming error",asynchronous:false)
                            fatalError("Programming error")
                        }
                        
                        guard let geofence = geofences.first else {
                            DDLogError("Programming error",asynchronous:false)
                            fatalError("Programming error")
                        }
                        DDLogInfo("delete fence \(geofence.name)")
                        moc.deleteObject(geofence)
                        
                        try moc.save()
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            if let region = self.regions?[code] {
                                self.regions?.removeValueForKey(code)
                                self.locationManager.stopMonitoringForRegion(region)
                                DDLogVerbose("Stop monitoring \(region.identifier)")
                            }
                            
                            self.updateGeofenceMonitoring()
                            completionHandler?(true)
                        }
                        
                    } catch {
                        DDLogError("Core Data Error \(error)")
                        assertionFailure("Core Data Error \(error)")
                    }
                }
                
            case .Cancelled?:
                DDLogVerbose("PIGeofenceDeleteRequest cancelled")
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler?(false)
                }
            case let .Error(error)?:
                DDLogError("PIGeofenceDeleteRequest error \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler?(false)
                }
            case let .Exception(error)?:
                DDLogError("PIGeofenceDeleteRequest exception \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler?(false)
                }
            case let .HTTPStatus(status,_)?:
                DDLogError("PIGeofenceDeleteRequest status \(status)")
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler?(false)
                }
            case nil:
                assertionFailure("Programming Error")
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler?(false)
                }
            }
        }
        
        self.service.executeRequest(geofenceDeleteRequest)
        
    }
    
    /**
     Add a `local` geofence, that is a geofence that is not defined by the backend
     - parameter name:   Name of the geofence
     - parameter center: The position of the center of the fence
     - parameter radius: The radius of the fence, should be larger than 200 m
     - parameter completionHandler:  Closure to be called when the fence has been added
     */
    public func addGeofence(name:String,center:CLLocationCoordinate2D,radius:Int,completionHandler: ((PIGeofence?) -> Void)? = nil) {
        
        guard let _ = service.orgCode else {
            DDLogError("No Organization Code")
            completionHandler?(nil)
            return
        }
        

        let geofenceCreateRequest = PIGeofenceCreateRequest(geofenceName: name, geofenceDescription: nil, geofenceRadius: radius, geofenceCoordinate: center) {
            response in
            switch response.result {
            case .OK?:
                DDLogVerbose("PIGeofenceCreateRequest OK \(response.geofenceCode)")
                guard let geofenceCode = response.geofenceCode else {
                    DDLogError("PIGeofenceCreateRequest Missing fence Id")
                    completionHandler?(nil)
                    return
                }
                
                let moc = self.dataController.writerContext
                
                moc.performBlock {
                    
                    let geofence:PIGeofence = moc.insertObject()
                    geofence.name = name
                    geofence.radius = radius
                    geofence.code = geofenceCode
                    geofence.latitude = center.latitude
                    geofence.longitude = center.longitude
                    
                    do {
                        try moc.save()
                        let geofenceURI = geofence.objectID.URIRepresentation()
                        dispatch_async(dispatch_get_main_queue()) {
                            self.updateGeofenceMonitoring()
                            let geofence = self.dataController.managedObjectWithURI(geofenceURI) as! PIGeofence
                            completionHandler?(geofence)
                        }
                    } catch {
                        DDLogError("Core Data Error \(error)",asynchronous:false)
                        assertionFailure("Core Data Error \(error)")
                        dispatch_async(dispatch_get_main_queue()) {
                            completionHandler?(nil)
                        }
                    }
                    
                }
                
                
            case .Cancelled?:
                DDLogVerbose("PIGeofenceCreateRequest Cancelled")
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler?(nil)
                }
            case let .Error(error)?:
                DDLogError("PIGeofenceCreateRequest Error \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler?(nil)
                }
            case let .Exception(error)?:
                DDLogError("PIGeofenceCreateRequest Exception \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler?(nil)
                }
            case let .HTTPStatus(status,_)?:
                DDLogError("PIGeofenceCreateRequest Status \(status)")
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler?(nil)
                }
            case nil:
                assertionFailure("Programming Error")
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler?(nil)
                }
            }
        }
        
        service.executeRequest(geofenceCreateRequest)
        
    }
    
    /// - returns: The list of all the fences
    public func queryAllGeofences() -> [PIGeofence] {
        let moc = self.dataController.mainContext
        let fetchRequest = PIGeofence.fetchRequest
        do {
            guard let geofences = try moc.executeFetchRequest(fetchRequest) as? [PIGeofence] else {
                DDLogError("Programming Error",asynchronous:false)
                assertionFailure("Programming error")
                return []
            }
            return geofences
        } catch {
            DDLogError("Core Data Error \(error)",asynchronous:false)
            assertionFailure("Core Data Error \(error)")
            return []
        }
        
    }
    
	/// - parameter code:   the code of the fence we are asking for
	///
	/// - returns: the geofence with the given code or nil if not found
    public func queryGeofence(code:String) -> PIGeofence? {
        let moc = self.dataController.mainContext
        let fetchRequest = PIGeofence.fetchRequest
        fetchRequest.predicate = NSPredicate(format: "code = %@", code)
        do {
            guard let geofences = try moc.executeFetchRequest(fetchRequest) as? [PIGeofence] else {
                DDLogError("Programming Error",asynchronous:false)
                assertionFailure("Programming error")
                return nil
            }
            guard let geofence = geofences.first else {
                return nil
            }
            return geofence
        } catch {
            DDLogError("Core Data Error \(error)",asynchronous:false)
            assertionFailure("Core Data Error \(error)")
            return nil
        }
    }
    
    
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
            
            
            guard let type = geojson["type"] as? String else {
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler?(error:PIOutdoorError.GeoJsonMissingType)
                }
                return
            }
            
            guard type == "FeatureCollection" else {
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler?(error:PIOutdoorError.GeoJsonWrongType(type))
                }
                return
            }
            
            
            guard let geofences = geojson["features"] as? [[String:AnyObject]] else {
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler?(error:PIOutdoorError.GeoJsonNoFeature)
                }
                return
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
                
                moc.reset()
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.updateGeofenceMonitoring()
                    if nbErrors == 0 {
                        completionHandler?(error:nil)
                    } else {
                        completionHandler?(error:PIOutdoorError.WrongFences(nbErrors))
                    }
                }
            } catch {
                DDLogError("Core Data Error \(error)",asynchronous:false)
                assertionFailure("Core Data Error \(error)")
                completionHandler?(error:PIOutdoorError.InternalError(error))
            }
        }
        
    }
    
    /**
     - returns: `true` indicates that this is the first time this `GeofencingManager`is used
     */
    public var firstTime:Bool {
        
        return !dataController.isStorePresent
        
    }
    
    public func currentGeofence(completionHandler:(geofence:PIGeofence?) -> Void) {
        
        guard let currentPosition = locationManager.location else {
            completionHandler(geofence: nil)
            return
        }
        
        // Compute North East and South West coordinates of the bbox of the regions
        // which could be monitored
        let region = MKCoordinateRegionMakeWithDistance(currentPosition.coordinate, Double(maxDistance), Double(maxDistance))
        
        let nw_lat_ = region.center.latitude + 0.5 * region.span.latitudeDelta
        let nw_lon_ = region.center.longitude - 0.5 * region.span.longitudeDelta
        let se_lat_ = region.center.latitude - 0.5 * region.span.latitudeDelta
        let se_lon_ = region.center.longitude + 0.5 * region.span.longitudeDelta
        
        let nw = CLLocationCoordinate2D(latitude: nw_lat_, longitude: nw_lon_)
        let se = CLLocationCoordinate2D(latitude: se_lat_, longitude: se_lon_)
        
        let moc = self.dataController.writerContext
        
        moc.performBlock {
            do {
                // find the geofences in the bbox of the current position
                let fetchRequest = PIGeofence.fetchRequest
                // We will need to access properties of all returned objects
                fetchRequest.returnsObjectsAsFaults = false
                // Filter out regions which are too far
                fetchRequest.predicate = NSPredicate(format: "latitude < \(nw.latitude) and latitude > \(se.latitude) and longitude > \(nw.longitude) and longitude < \(se.longitude)")
                guard let nearFences = try moc.executeFetchRequest(fetchRequest) as? [PIGeofence] else {
                    fatalError("Programming error, shouldn't be there")
                }
                
                // Sort fences in ascending order starting from the nearest fence
                let sortedFences = nearFences.sort(self.compareGeofence(currentPosition))
                
                for geofence in sortedFences {
                    let geofenceLocation = CLLocation(latitude: geofence.latitude.doubleValue, longitude: geofence.longitude.doubleValue)
                    let distance = currentPosition.distanceFromLocation(geofenceLocation)
                    if distance < geofence.radius.doubleValue {
                        let geofenceURI = geofence.objectID.URIRepresentation()
                        dispatch_async(dispatch_get_main_queue()){
                            let geofenceUI = self.dataController.managedObjectWithURI(geofenceURI) as! PIGeofence
                            completionHandler(geofence: geofenceUI)
                        }
                        return
                    }
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler(geofence: nil)
                }
                
                
            } catch {
                DDLogError("Core Data Error \(error)",asynchronous:false)
                assertionFailure("Core Data Error \(error)")
                completionHandler(geofence: nil)
            }
        }
    }
    
}

