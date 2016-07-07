/**
 *  IBMPIGeofence
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
import CocoaLumberjack


public let kGeofencingManagerDidSynchronize = "com.ibm.pi.GeofencingManagerDidSynchronize"

@objc(IBMPIGeofencingManagerDelegate)
public protocol PIGeofencingManagerDelegate:class {
    /// The device enters into a geofence
    func geofencingManager(manager: PIGeofencingManager, didEnterGeofence geofence: PIGeofence? )
    /// The device exits a geofence
    func geofencingManager(manager: PIGeofencingManager, didExitGeofence geofence: PIGeofence? )

	optional func geofencingManager(manager: PIGeofencingManager, didStartDownload download: PIDownload)
	optional func geofencingManager(manager: PIGeofencingManager, didReceiveDownload download: PIDownload)


}

/// `PIGeofencingManager` is your entry point to the PI Geofences.
/// Its responsability is to monitor the PI geofences. 
/// When the user enters or exits a geofence, `PIGeofencingManager` notifies
/// the Presence Insights backend
@objc(IBMPIGeofencingManager)
public final class PIGeofencingManager:NSObject {

	/// When `true`, the `PIGeofencingManager`does not post event against PIT backend
	public var privacy = false

    /// By default, `PIGeofencingManager` can monitore up to 15 regions simultaneously.
    public static let DefaultMaxRegions = 15
    
    let locationManager = CLLocationManager()

	/// Maximum of consecutive retry for downloading geofence definitions from PI
	/// We wait for one hour between each retry
	public var maxDownloadRetry:Int {
		set {
			PIGeofencePreferences.maxDownloadRetry = newValue
		}
		get {
			return PIGeofencePreferences.maxDownloadRetry
		}
	}

	/// Number of days between each check against PI for downloading the geofence definitions
	public var intervalBetweenDownloads = 1

    var regions:[String:CLCircularRegion]?
    
    /// The length of the sides of the bounding box used to find out
    /// which fences should be monitored.
    public let maxDistance:Int
    
    /// Maximum number of regions which can be monitored simultaneously.
    public let maxRegions:Int
    
    lazy var dataController = PIGeofenceData.dataController

	/// PI Service
    let service:PIService
    
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
            DDLogError("maxRegions \(maxRegions) is out of range",asynchronous:false)
            self.maxRegions = self.dynamicType.DefaultMaxRegions
        }
        self.service = PIService(tenantCode:tenantCode,orgCode:orgCode,baseURL:baseURL,username:username,password:password)
        super.init()
		
        self.locationManager.delegate = self

		self.service.delegate = self
		
        NSNotificationCenter.defaultCenter().addObserver(
			self,
			selector: #selector(PIGeofencingManager.didBecomeActive(_:)),
			name: UIApplicationWillEnterForegroundNotification,
			object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
			self,
			selector: #selector(PIGeofencingManager.willResignActive(_:)),
			name: UIApplicationDidEnterBackgroundNotification,
			object: nil)
        
    }


    /// Enables or disables the logging
    /// - parameter enable: `true` to enable the logging
    public static func enableLogging(enable:Bool) {
        
        if enable {
            DDLog.addLogger(DDTTYLogger.sharedInstance()) // TTY = Xcode console
            DDLog.addLogger(DDASLLogger.sharedInstance()) // ASL = Apple System Logs
            
			let documentsFileManager = DDLogFileManagerDefault(logsDirectory:PIGeofenceUtils.documentsDirectory.path,defaultFileProtectionLevel:NSFileProtectionNone)

            let fileLogger: DDFileLogger = DDFileLogger(logFileManager: documentsFileManager) // File Logger
            fileLogger.rollingFrequency = 60*60*24  // 24 hours
            fileLogger.logFileManager.maximumNumberOfLogFiles = 7
            DDLog.addLogger(fileLogger)
        } else {
            DDLog.removeAllLoggers()
        }
    }

	/// Returns the pathes of the log files
	public static func logFiles() -> [String] {
		let documentsFileManager = DDLogFileManagerDefault(logsDirectory:PIGeofenceUtils.documentsDirectory.path)

		return documentsFileManager.sortedLogFilePaths().map { String($0) }

	}

    /**
     Ask the back end for the latest geofences to monitor
     - parameter completionHandler:  The closure called when the synchronisation is completed
     */
	public func synchronize(completionHandler: ((Bool)-> Void)? = nil) {
		let request = PIGeofenceFencesDownloadRequest(lastSyncDate:PIGeofencePreferences.lastSyncDate)
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
				let downloadURI = download.objectID.URIRepresentation()
				dispatch_async(dispatch_get_main_queue()) {
					let download = self.dataController.managedObjectWithURI(downloadURI) as! PIDownload
					self.delegate?.geofencingManager?(self, didStartDownload: download)
					completionHandler?(true)
				}
			} catch {
				DDLogError("Core Data Error \(error)",asynchronous:false)
				completionHandler?(false)
			}
		}

    }

	/// Method to be called by the AppDelegate to handle the download of the geofence definitions
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
    
    ///
    /// - parameter code:   The code of the geofence to remove
	/// - parameter completionHandler: closure invoked on completion
	///
    func removeGeofence(code:String,completionHandler: ((Bool) -> Void)? = nil) {
        let geofenceDeleteRequest = PIGeofenceDeleteRequest(geofenceCode: code) {
            response in
            switch response.result {
            case .OK?:
                DDLogInfo("PIGeofenceDeleteRequest OK",asynchronous:false)
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
                        DDLogInfo("Delete fence \(geofence.name) \(geofence.code)",asynchronous:false)
                        moc.deleteObject(geofence)
                        
                        try moc.save()
                        

						if let region = self.regions?[code] {
							self.regions?.removeValueForKey(code)
							self.locationManager.stopMonitoringForRegion(region)
							DDLogVerbose("Stop monitoring \(region.identifier)",asynchronous:false)
						}
						
						self.updateMonitoredGeofencesWithMoc(moc)
						dispatch_async(dispatch_get_main_queue()) {
                            completionHandler?(true)
                        }
                        
                    } catch {
                        DDLogError("Core Data Error \(error)",asynchronous:false)
                        assertionFailure("Core Data Error \(error)")
                    }
                }
                
            case .Cancelled?:
                DDLogVerbose("PIGeofenceDeleteRequest cancelled",asynchronous:false)
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler?(false)
                }
            case let .Error(error)?:
                DDLogError("PIGeofenceDeleteRequest error \(error)",asynchronous:false)
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler?(false)
                }
            case let .Exception(error)?:
                DDLogError("PIGeofenceDeleteRequest exception \(error)",asynchronous:false)
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler?(false)
                }
            case let .HTTPStatus(status,_)?:
                DDLogError("PIGeofenceDeleteRequest status \(status)",asynchronous:false)
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
    func addGeofence(name:String,center:CLLocationCoordinate2D,radius:Int,completionHandler: ((PIGeofence?) -> Void)? = nil) {
        
        guard let _ = service.orgCode else {
            DDLogError("No Organization Code",asynchronous:false)
            completionHandler?(nil)
            return
        }
        

        let geofenceCreateRequest = PIGeofenceCreateRequest(geofenceName: name, geofenceDescription: nil, geofenceRadius: radius, geofenceCoordinate: center) {
            response in
            switch response.result {
            case .OK?:
                DDLogVerbose("PIGeofenceCreateRequest OK \(response.geofenceCode)",asynchronous:false)
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
						self.updateMonitoredGeofencesWithMoc(moc)
                        let geofenceURI = geofence.objectID.URIRepresentation()
                        dispatch_async(dispatch_get_main_queue()) {
                            let geofence = self.dataController.managedObjectWithURI(geofenceURI) as! PIGeofence
                            completionHandler?(geofence)
                        }
                    } catch {
                        DDLogError("Core Data Error \(error)")
                        assertionFailure("Core Data Error \(error)")
                        dispatch_async(dispatch_get_main_queue()) {
                            completionHandler?(nil)
                        }
                    }
                    
                }
                
                
            case .Cancelled?:
                DDLogVerbose("PIGeofenceCreateRequest Cancelled",asynchronous:false)
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
                DDLogError("Programming Error")
                assertionFailure("Programming error")
                return []
            }
            return geofences
        } catch {
            DDLogError("Core Data Error \(error)")
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
            DDLogError("Core Data Error \(error)")
            assertionFailure("Core Data Error \(error)")
            return nil
        }
    }
    
    
    /**
     - returns: `true` indicates that this is the first time this `GeofencingManager`is used
     */
    public var firstTime:Bool {

        return !dataController.isStorePresent

    }

    
}

