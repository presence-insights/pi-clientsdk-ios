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

public enum PIOutdoorError:ErrorType {
    case UnzipOpenFile(String)
    case UnzipFileTo(String)
    case EmptyZipFile(NSURL)
    case UnzipCloseFile
    
    case GeoJsonMissingType
    case GeoJsonWrongType(String)
    case GeoJsonNoFeature
    
    case WrongFences(Int)
}


let kAnchorKey = "com.ibm.PI.geofencing.anchor"

public struct PIFenceProperties {
    public let name:String
    public let radius:Int
    public let identifier:String?
    
    public init(name:String,radius:Int,identifier:String?) {
        self.name = name
        self.radius = radius
        self.identifier = identifier
    }
}

public typealias FencePropertiesGenerator = ([String:AnyObject]) -> PIFenceProperties

public protocol PIGeofencingManagerDelegate:class {
    func geofencingManager(manager: PIGeofencingManager, didEnterGeofence geofence: PIGeofence? )
    func geofencingManager(manager: PIGeofencingManager, didExitGeofence geofence: PIGeofence? )
}

public class PIGeofencingManager:NSObject {
    
    private let locationManager = CLLocationManager()
    
    private var regions:[String:CLCircularRegion]?
    
    public let maxDistance:Int
    
    private lazy var dataController = PIOutdoor.dataController
    
    public let service:PIService
    
    public var delegate:PIGeofencingManagerDelegate?
    
    public init(tenant:String, org:String, baseURL:String, username:String, password:String,maxDistance:Int = 10_000) {
        self.maxDistance = maxDistance
        self.service = PIService(tenant:tenant,org:org,baseURL:baseURL,username:username,password:password)
        super.init()
        self.locationManager.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willResignActive:", name: UIApplicationWillResignActiveNotification, object: nil)
        
    }
    
    /**
     Ask the back end for the latest geofences to monitor
     - parameter completionHandler:  The closure called when the synchronisation is completed
     */
    public func synchronize(completionHandler:((error:ErrorType?) -> Void)? = nil)  {
        let request = PIGeofencesRequest() { response in
            switch response.result {
            case .Cancelled?:
                break
            case let .Error(error)?:
                print(error)
                
            case .Exception(let exception)?:
                print(exception)
                
            case let .HTTPStatus(status)?:
                print("HTTP Status \(status)")
            case let .OK(json)?:
                if let json = json as? [String:AnyObject] {
                    if let geojson = json["geojson"] as? [String:AnyObject] {
                        self.seedGeojson(geojson,completionHandler:completionHandler)
                    }
                }
                print(json)
            case nil:
                fatalError("Shouldn't be there")
            }
        }
        
        service.executeRequest(request)
        
        
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
    public func updateGeofenceMonitoring(completionHandler: (()-> Void)? = nil) {
        
        // https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/RegionMonitoring/RegionMonitoring.html
        /*
        
        Be judicious when specifying the set of regions to monitor. Regions are a shared system resource, and the total number of regions available systemwide is limited. For this reason, Core Location limits to 20 the number of regions that may be simultaneously monitored by a single app. To work around this limit, consider registering only those regions in the user’s immediate vicinity. As the user’s location changes, you can remove regions that are now farther way and add regions coming up on the user’s path. If you attempt to register a region and space is unavailable, the location manager calls the locationManager:monitoringDidFailForRegion:withError: method of its delegate with the kCLErrorRegionMonitoringFailure error code.
        */
        
        /*
        When testing your region monitoring code in iOS Simulator or on a device, realize that region events may not happen immediately after a region boundary is crossed. To prevent spurious notifications, iOS doesn’t deliver region notifications until certain threshold conditions are met. Specifically, the user’s location must cross the region boundary, move away from the boundary by a minimum distance, and remain at that minimum distance for at least 20 seconds before the notifications are reported.
        
        The specific threshold distances are determined by the hardware and the location technologies that are currently available. For example, if Wi-Fi is disabled, region monitoring is significantly less accurate. However, for testing purposes, you can assume that the minimum distance is approximately 200 meters.
        */
        
        
        guard let currentPosition = locationManager.location else {
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
                if self.regions == nil {
                    // either the first time we monitor or the app has been unloaded
                    // find the regions currently being monitored
                    let fetchMonitoredRegionsRequest = NSFetchRequest(entityName:StringFromClass(PIGeofence))
                    fetchMonitoredRegionsRequest.predicate = NSPredicate(format: "monitored == 1")
                    guard let monitoredGeofences = try moc.executeFetchRequest(fetchMonitoredRegionsRequest) as? [PIGeofence] else {
                        fatalError("Programming error")
                    }
                    
                    self.regions = [:]
                    for geofence in monitoredGeofences {
                        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: geofence.latitude.doubleValue, longitude: geofence.longitude.doubleValue), radius: geofence.radius.doubleValue, identifier: geofence.uuid)
                        print("already monitoring \(geofence.name)")
                        self.regions?[geofence.uuid] = region
                        
                    }
                }
                
                // find the geofences in the bbox of the current position
                let fetchRequest = NSFetchRequest(entityName:StringFromClass(PIGeofence))
                // We will need to access properties of all returned objects
                fetchRequest.returnsObjectsAsFaults = false
                // Filter out regions which are too far
                fetchRequest.predicate = NSPredicate(format: "latitude < \(nw.latitude) and latitude > \(se.latitude) and longitude > \(nw.longitude) and longitude < \(se.longitude)")
                guard let nearFences = try moc.executeFetchRequest(fetchRequest) as? [PIGeofence] else {
                    fatalError("Programming error")
                }
                
                // Sort fences in ascending order starting from the nearest fence
                let sortedFences = nearFences.sort(self.compareGeofence(currentPosition))
                
                // Keep the first 20 regions to stay under the system wide limit
                let max = sortedFences.count < 20 ? sortedFences.count : 20
                let fencesToMonitor = sortedFences[0..<max]
                
                let uuids = Set(fencesToMonitor.map { $0.uuid })
                
                var keepRegions = [String:CLCircularRegion]()
                
                // Stop monitoring regions that are too far
                for (uuid,region) in self.regions! {
                    if uuids.contains(uuid) == false {
                        self.locationManager.stopMonitoringForRegion(region)
                        let fetchRequest =  NSFetchRequest(entityName:StringFromClass(PIGeofence))
                        fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid)
                        let geofences = try moc.executeFetchRequest(fetchRequest) as? [PIGeofence]
                        let geofence = geofences!.first!
                        geofence.monitored = false
                        print("stopMonitoringForRegion",geofence.name,uuid)
                    } else {
                        // keep the region
                        keepRegions[uuid] = region
                    }
                }
                
                self.regions = keepRegions
                
                // Start monitoring new regions near our current position
                for geofence in fencesToMonitor {
                    if self.regions?[geofence.uuid] != nil {
                        // We are already monitoring this fence
                        continue
                    }
                    geofence.monitored = true
                    let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: geofence.latitude.doubleValue, longitude: geofence.longitude.doubleValue), radius: geofence.radius.doubleValue, identifier: geofence.uuid)
                    self.regions?[geofence.uuid] = region
                    self.locationManager.startMonitoringForRegion(region)
                    print("startMonitoringForRegion",geofence.name,region.identifier)
                }
                
                try moc.save()
                
            } catch {
                fatalError("Core Data Error \(error)")
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                completionHandler?()
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
    
    /**
     Remove a geofence
     - parameter uuid:   The uuid of the fence to remove
     */
    public func removeGeofence(uuid:String) {
        if let region = self.regions?[uuid] {
            self.regions?.removeValueForKey(uuid)
            self.locationManager.stopMonitoringForRegion(region)
            print("Stop monitoring",region.identifier)
        }
        
        let moc = self.dataController.writerContext
        moc.performBlock {
            do {
                let fetchRequest =  NSFetchRequest(entityName:StringFromClass(PIGeofence))
                fetchRequest.predicate = NSPredicate(format: "uuid == %@",uuid)
                guard let geofences = try moc.executeFetchRequest(fetchRequest) as? [PIGeofence] else {
                    fatalError("Programming error")
                }
                
                guard let geofence = geofences.first else {
                    fatalError("Programming error")
                }
                print("delete fence",geofence.name)
                moc.deleteObject(geofence)
                
                try moc.save()
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.updateGeofenceMonitoring()
                }
                
            } catch {
                fatalError("Core Data Error \(error)")
            }
        }
    }
    
    /**
     Add a `local` geofence, that is a geofence that is not defined by the backend
     - parameter name:   Name of the geofence
     - parameter center: The position of the center of the fence
     - parameter radius: The radius of the fence, should be larger than 200 m
     - parameter completionHandler:  Closure to be called when the fence has been added
     */
    public func addGeofence(name:String,center:CLLocationCoordinate2D,radius:Int,completionHandler: ((PIGeofence) -> Void)? = nil) {
        let moc = self.dataController.writerContext
        
        moc.performBlock {
            
            let geofence = NSEntityDescription.insertNewObjectForEntityForName(StringFromClass(PIGeofence),
                inManagedObjectContext:moc) as! PIGeofence
            geofence.name = name
            geofence.radius = radius
            geofence.uuid = NSUUID().UUIDString
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
                fatalError("\(error)")
            }
            
        }
    }
    
    /**
     Returns all the fences
     
     - returns: the list of all the fences
     */
    public func queryAllGeofences() -> [PIGeofence] {
        let moc = self.dataController.mainContext
        let fetchRequest = NSFetchRequest(entityName:StringFromClass(PIGeofence))
        do {
            guard let geofences = try moc.executeFetchRequest(fetchRequest) as? [PIGeofence] else {
                fatalError("Programming error")
            }
            return geofences
        } catch {
            fatalError("Core Data Error \(error)")
        }
        
    }
    
    /**
     Returns a fence
     - parameter uuid:   the uuid of the fence we are asking for
     
     - returns: the geofence with the given uuid or nil if not found
     */
    public func queryGeofence(uuid:String) -> PIGeofence? {
        let moc = self.dataController.mainContext
        let fetchRequest = NSFetchRequest(entityName:StringFromClass(PIGeofence))
        fetchRequest.predicate = NSPredicate(format: "uuid = %@", uuid)
        do {
            guard let geofences = try moc.executeFetchRequest(fetchRequest) as? [PIGeofence] else {
                fatalError("Programming error")
            }
            guard let geofence = geofences.first else {
                return nil
            }
            return geofence
        } catch {
            fatalError("Core Data Error \(error)")
        }
    }
    
    
    public func seedGeojson(
        url:NSURL,propertiesGenerator:
        FencePropertiesGenerator? = nil,
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
            print("geojson",file)
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
        propertiesGenerator:FencePropertiesGenerator? = nil,
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
                    print(i,"Missing type property")
                    nbErrors += 1
                    continue
                }
                guard type == "Feature" else {
                    print(i,"Wrong type \(type)")
                    nbErrors += 1
                    continue
                }
                guard let geometry = fence["geometry"] as? [String:AnyObject] else {
                    print(i,"Missing geometry")
                    nbErrors += 1
                    continue
                }
                
                guard let geometry_type = geometry["type"] as? String else {
                    print(i,"Missing geometry type")
                    nbErrors += 1
                    continue
                }
                guard geometry_type == "Point" else {
                    print(i,"Does not support geometry \(geometry_type)")
                    nbErrors += 1
                    continue
                }
                
                guard let coordinates = geometry["coordinates"] as? [NSNumber] else {
                    print(i,"Missing coordinates")
                    nbErrors += 1
                    continue
                }
                
                guard coordinates.count == 2 else {
                    print(i,"Wrong number of coordinates")
                    nbErrors += 1
                    continue
                }
                
                let latitude = coordinates[1]
                let longitude = coordinates[0]
                
                guard let properties = fence["properties"] as? [String:AnyObject] else {
                    print(i,"Missing properties")
                    nbErrors += 1
                    continue
                }
                
                let name:String
                let radius:Int
                let uuid:String
                
                if let propertiesGenerator = propertiesGenerator {
                    let properties = propertiesGenerator(properties)
                    name = properties.name
                    radius = properties.radius
                    uuid = properties.identifier ??  NSUUID().UUIDString
                } else {
                    name = properties["name"] as? String ?? "???!!!"
                    radius = properties["radius"] as? Int ?? 100
                    uuid = properties["uuid"] as? String ?? NSUUID().UUIDString
                }
                
                let geofence = NSEntityDescription.insertNewObjectForEntityForName(StringFromClass(PIGeofence),
                    inManagedObjectContext:moc) as! PIGeofence
                
                geofence.name = name
                geofence.radius = radius
                geofence.uuid = uuid
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
                fatalError("\(error)")
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
                let fetchRequest = NSFetchRequest(entityName:StringFromClass(PIGeofence))
                // We will need to access properties of all returned objects
                fetchRequest.returnsObjectsAsFaults = false
                // Filter out regions which are too far
                fetchRequest.predicate = NSPredicate(format: "latitude < \(nw.latitude) and latitude > \(se.latitude) and longitude > \(nw.longitude) and longitude < \(se.longitude)")
                guard let nearFences = try moc.executeFetchRequest(fetchRequest) as? [PIGeofence] else {
                    fatalError("Programming error")
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
                fatalError("Core Data Error")
            }
        }
    }
    
}

extension PIGeofencingManager: CLLocationManagerDelegate {
    
    public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus){
        switch status {
        case .AuthorizedAlways:
            fallthrough
        case .AuthorizedWhenInUse:
            locationManager.startMonitoringSignificantLocationChanges()
        case .Denied:
            break
        case .NotDetermined:
            break
        case .Restricted:
            break
            
        }
        
    }
    
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.updateGeofenceMonitoring()
    }
    
    public func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion){
        guard let geofence = self.queryGeofence(region.identifier) else {
            print("Region not found")
            self.delegate?.geofencingManager(self, didEnterGeofence: nil)
            return
        }
        
        
        self.delegate?.geofencingManager(self, didEnterGeofence: geofence)
        
    }
    
    public func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion){
        
        guard let geofence = self.queryGeofence(region.identifier) else {
            print("Region not found")
            self.delegate?.geofencingManager(self, didExitGeofence: nil)
            return
        }
        
        
        self.delegate?.geofencingManager(self, didExitGeofence: geofence)
        
    }
    
    
    
}