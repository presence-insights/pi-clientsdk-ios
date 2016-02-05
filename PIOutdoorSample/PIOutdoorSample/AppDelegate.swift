/**
 *  PIOutdoorSample
 *  AppDelegate.swift
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
import PIOutdoorSDK
import CoreLocation
import SSKeychain
import CocoaLumberjack

let slackToken:String? = nil

var piGeofencingManager:PIGeofencingManager!

let SeedDidComplete = "com.ibm.PI.SeedDidComplete"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private let locationManager = CLLocationManager()

    private let slackQueue:NSOperationQueue = NSOperationQueue()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        registerDefaultSettings()
        
        let tenantCode = NSUserDefaults.standardUserDefaults().objectForKey("PITenant") as! String
        let hostname = NSUserDefaults.standardUserDefaults().objectForKey("PIHostName") as! String
        let username = NSUserDefaults.standardUserDefaults().objectForKey("PIUsername") as! String
        let password = NSUserDefaults.standardUserDefaults().objectForKey("PIPassword") as! String
        
        PIGeofencingManager.enableLogging(true)
        
        DDLogVerbose("tenant \(tenantCode)")
        DDLogVerbose("hostname \(hostname)")
        DDLogVerbose("username \(username)")
        DDLogVerbose("password \(password)")
        
        NetworkActivityIndicatorManager.sharedInstance.enableActivityIndicator(true)
        
        let data:NSData? = SSKeychain.passwordDataForService("PIIndoor", account: tenantCode)
        
        piGeofencingManager = PIGeofencingManager(
            tenantCode: tenantCode,
            orgCode: nil,
            baseURL: hostname,
            username: username,
            password: password)
        

        
        if let data = data {
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                if let orgCode = json["orgCode"] as? String {
                    piGeofencingManager.service.orgCode = orgCode
                    DDLogVerbose("OrgCode \(orgCode)")
                } else {
                    DDLogError("orgCode missing in the JSON from the KeyChain")
                }
            } catch {
                DDLogError("Can't read JSON in the KeyChain")
            }
        } else {
            let service = piGeofencingManager.service
            let orgName = UIDevice.currentDevice().name + "-" + NSUUID().UUIDString
            DDLogVerbose("Start PIServiceCreateOrgRequest: \(orgName)")
            let request = PIServiceCreateOrgRequest(orgName:orgName) { response in
                switch response.result {
                case .OK?:
                    DDLogVerbose("PIServiceCreateOrgRequest OK \(response.orgCode)")
                    guard let orgCode = response.orgCode else {
                        DDLogError("PIServiceCreateOrgRequest Missing org code")
                        assertionFailure("Programming error")
                        return
                    }
                    var json =  [String:AnyObject]()
                    json["orgCode"] = orgCode
                    let data = try! NSJSONSerialization.dataWithJSONObject(json, options: [])
                    SSKeychain.setPasswordData(data, forService: "PIIndoor", account: tenantCode)
                    dispatch_async(dispatch_get_main_queue()) {
                        piGeofencingManager.service.orgCode = orgCode
                        
                    }
                case .Cancelled?:
                    DDLogVerbose("PIServiceCreateOrgRequest cancelled")
                case let .Error(error)?:
                    DDLogError("PIServiceCreateOrgRequest error \(error)")
                case let .Exception(error)?:
                    DDLogError("PIServiceCreateOrgRequest exception \(error)")
                case let .HTTPStatus(status,_)?:
                    DDLogError("PIServiceCreateOrgRequest status \(status)")
                case nil:
                    assertionFailure("Programming Error")
                    break
                }
            }
            service.executeRequest(request)
        }
        print("data",data)
        

        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        
        piGeofencingManager.delegate = self
        
        slackQueue.qualityOfService = .Utility
        slackQueue.name = "com.ibm.PI.slackQueue"
        
        
        //self.seeding()
        
        self.manageAuthorizations()
        
        return true
    }

    private func registerDefaultSettings() {
        
        let settingsURL = NSBundle.mainBundle().URLForResource("Settings", withExtension: "bundle")!
        let settingsBundle = NSBundle(URL: settingsURL)!
        let settingsFile = settingsBundle.URLForResource("Root", withExtension:"plist")!
        let settingsDefault = NSDictionary(contentsOfURL:settingsFile) as! [String:AnyObject]
        var defaultsToRegister = [String:AnyObject]()
        let preferences = settingsDefault["PreferenceSpecifiers"] as! [[String:AnyObject]]
        
        for preference in preferences {
            if
                let key = preference["Key"] as? String,
                let defaultValue = preference["DefaultValue"] {
                    defaultsToRegister[key] = defaultValue
            }
        }
        NSUserDefaults.standardUserDefaults().registerDefaults(defaultsToRegister)
        
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("didBecomeActive")
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        let state = UIApplication .sharedApplication().applicationState
        if state == .Active {
            let alertController = UIAlertController(
                title: NSLocalizedString("Alert.LocalNotification.Title",comment:""),
                message: notification.alertBody!,
                preferredStyle: .Alert)
            
            let okAction = UIAlertAction(title: NSLocalizedString("OK",comment:""), style: .Default){ (action) in
            }
            alertController.addAction(okAction)
            
            
            self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
            
        }
        
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, withResponseInfo responseInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        
    }
    
    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        
    }

}


extension AppDelegate {
    
    private func seeding(){
        
        if piGeofencingManager.firstTime {
            guard let url = NSBundle.mainBundle().URLForResource("referentiel-gares-voyageurs.geojson", withExtension: "zip") else {
                fatalError("file not found")
            }
            do {
                try piGeofencingManager.seedGeojson(url,propertiesGenerator:fenceProperties) { error in
                    print(error)
                    NSNotificationCenter.defaultCenter().postNotificationName(SeedDidComplete, object: nil)
                }
            } catch {
                print(error)
            }
        }
        
    }

    func fenceProperties(properties:[String:AnyObject]) -> PIGeofenceProperties {
        let name = properties["intitule_gare"] as? String ?? "???!!!"
        let fenceProperties = PIGeofenceProperties(name:name,radius:100,code:nil)
        return fenceProperties
    }
    
    private func manageAuthorizations() {
        
        if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
            let alertController = UIAlertController(
                title: NSLocalizedString("Alert.NoMonitoring.Title",comment:""),
                message: NSLocalizedString("Alert.NoMonitoring.Message",comment:""),
                preferredStyle: .Alert)
            
            let okAction = UIAlertAction(title: NSLocalizedString("OK",comment:""), style: .Default){ (action) in
            }
            alertController.addAction(okAction)
            
            
            dispatch_async(dispatch_get_main_queue()) {
                self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
                
            }
            
        } else {
            switch CLLocationManager.authorizationStatus() {
            case .NotDetermined:
                locationManager.requestAlwaysAuthorization()
                
            case .AuthorizedAlways:
                fallthrough
            case .AuthorizedWhenInUse:
                break
            case .Restricted, .Denied:
                let alertController = UIAlertController(
                    title: NSLocalizedString("Alert.Monitoring.Title",comment:""),
                    message: NSLocalizedString("Alert.Monitoring.Message",comment:""),
                    preferredStyle: .Alert)
                
                let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel",comment:""), style: .Cancel){ (action) in
                }
                alertController.addAction(cancelAction)
                
                let openAction = UIAlertAction(title: NSLocalizedString("Alert.Monitoring.OpenAction",comment:""), style: .Default) { (action) in
                    if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                        UIApplication.sharedApplication().openURL(url)
                    }
                }
                alertController.addAction(openAction)
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
                    
                }
            }
        }
        
        let refreshStatus = UIApplication.sharedApplication().backgroundRefreshStatus
        switch refreshStatus {
        case .Restricted:
            fallthrough
        case .Denied:
            let alertController = UIAlertController(
                title: NSLocalizedString("Alert.BackgroundRefresh.Title",comment:""),
                message: NSLocalizedString("Alert.BackgroundRefresh.Message",comment:""),
                preferredStyle: .Alert)
            
            let okAction = UIAlertAction(title: NSLocalizedString("OK",comment:""), style: .Default){ (action) in
            }
            alertController.addAction(okAction)
            
            
            dispatch_async(dispatch_get_main_queue()) {
                self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
                
            }
            
        case .Available:
            break
            
        }

    }
}

extension AppDelegate:PIGeofencingManagerDelegate {
    func geofencingManager(manager: PIGeofencingManager, didEnterGeofence geofence: PIGeofence? ) {
        
        let geofenceName = geofence?.name ?? "Error,unknown fence"
        print("Did Enter",geofenceName)
        sendSlackMessage("enter", geofence: geofence)
        
        let notification = UILocalNotification()
        notification.alertBody = String(format:NSLocalizedString("Region.Notification.Enter %@", comment: ""),geofenceName)
        
        notification.soundName = UILocalNotificationDefaultSoundName
        if let geofence = geofence {
            notification.userInfo = ["uuid":geofence.code]
        }
        
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
        
    }
    
    func geofencingManager(manager: PIGeofencingManager, didExitGeofence geofence: PIGeofence? ) {
        
        let geofenceName = geofence?.name ?? "Error,unknown fence"
        print("Did Exit",geofenceName)
        sendSlackMessage("exit", geofence: geofence)
        
        let notification = UILocalNotification()
        notification.alertBody = String(format:NSLocalizedString("Region.Notification.Exit %@", comment: ""),geofenceName)
        
        notification.soundName = UILocalNotificationDefaultSoundName
        if let geofence = geofence {
            notification.userInfo = ["uuid":geofence.code]
        }
        
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }
    
    
    private func sendSlackMessage(event:String,geofence: PIGeofence?) {
        
        guard Settings.privacy == false else {
            return
        }
        
        guard let slackToken = slackToken else {
            return
        }
        
        let session = NSURLSession.sharedSession()
        
        let geofenceName = geofence?.name ?? "unknown fence"
        var params:[String:String] = [:]
        params["channel"] = "#geo-spam"
        params["text"] = ":iphone: \(event) : \(geofenceName)"
        
        let chatPostMessage = SlackOperation(session:session,slackAPI:"chat.postMessage",params:params,token:slackToken)
        
        // https://developer.apple.com/library/ios/technotes/tn2277/_index.html
        let application = UIApplication.sharedApplication()
        var bkgTaskId = UIBackgroundTaskInvalid
        bkgTaskId = application.beginBackgroundTaskWithExpirationHandler {
            if bkgTaskId != UIBackgroundTaskInvalid {
                print("expirationHandler",bkgTaskId)
                self.slackQueue.cancelAllOperations()
                let id = bkgTaskId
                bkgTaskId = UIBackgroundTaskInvalid
                application.endBackgroundTask(id)
            }
        }
        
        chatPostMessage.completionBlock = {
            chatPostMessage.completionBlock = nil
            guard let result = chatPostMessage.result else {
                NSLog("should'nt be there, no result for Slack API")
                fatalError("should'nt be there, no result")
            }
            
            switch result {
            case let .HTTPStatus(status,_):
                print("Status",status)
            case let .Error(error):
                print(error)
            case let .Exception(exception):
                print(exception)
            case .Cancelled:
                print("cancelled")
            case .OK:
                print("ok")
            }
            if bkgTaskId != UIBackgroundTaskInvalid {
                print("end background",bkgTaskId)
                let id = bkgTaskId
                bkgTaskId = UIBackgroundTaskInvalid
                application.endBackgroundTask(id)
            }
        }
        
        slackQueue.addOperation(chatPostMessage)
        
    }

}

