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

let slackToken:String? = "xoxb-16384356389-QhQvfBrIrUgne6CLza7fRkx5"

let piGeofencingManager = PIGeofencingManager(tenant: "tenant", org: "org", baseURL: "host", username: "username", password: "password")

let SeedDidComplete = "com.ibm.PI.SeedDidComplete"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private let locationManager = CLLocationManager()

    private let slackQueue:NSOperationQueue = NSOperationQueue()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        
        
        piGeofencingManager.delegate = self
        
        slackQueue.qualityOfService = .Utility
        slackQueue.name = "com.ibm.PI.slackQueue"
        
        
        //self.seeding()
        
        self.manageAuthorizations()
        
        return true
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

    func fenceProperties(properties:[String:AnyObject]) -> PIFenceProperties {
        let name = properties["intitule_gare"] as? String ?? "???!!!"
        let fenceProperties = PIFenceProperties(name:name,radius:100,identifier:nil)
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
            notification.userInfo = ["uuid":geofence.uuid]
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
            notification.userInfo = ["uuid":geofence.uuid]
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

