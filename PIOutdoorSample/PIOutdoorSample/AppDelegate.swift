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
import MBProgressHUD

let slackToken: String? = "xoxb-16384356389-QhQvfBrIrUgne6CLza7fRkx5"

var piGeofencingManager: PIGeofencingManager!


let kOrgCodeDidChange = "com.ibm.PI.OrgCodeDidChange"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private let locationManager = CLLocationManager()

    private let slackQueue: NSOperationQueue = NSOperationQueue()

	private static let dateFormatter:NSDateFormatter = {
		let dateFormatter = NSDateFormatter()
		dateFormatter.dateStyle = .MediumStyle
		dateFormatter.timeStyle = .MediumStyle
		return dateFormatter
	}()

    func application(application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

        registerDefaultSettings()

		guard let tenantCode = NSUserDefaults.standardUserDefaults().objectForKey("PITenant") as? String else {
				assertionFailure("Programming Error")
				return true
			}
		guard let hostname = NSUserDefaults.standardUserDefaults().objectForKey("PIHostName") as? String else {
			assertionFailure("Programming Error")
			return true
			}
		guard let username = NSUserDefaults.standardUserDefaults().objectForKey("PIUsername") as? String else {
			assertionFailure("Programming Error")
			return true
			}
		guard let password = NSUserDefaults.standardUserDefaults().objectForKey("PIPassword") as? String else {
				assertionFailure("Programming Error")
			return true
		}

        PIGeofencingManager.enableLogging(true)
        
        DDLogVerbose("tenant \(tenantCode)")
        DDLogVerbose("hostname \(hostname)")
        DDLogVerbose("username \(username)")
        DDLogVerbose("password \(password)")
        
        NetworkActivityIndicatorManager.sharedInstance.enableActivityIndicator(true)
        

        piGeofencingManager = PIGeofencingManager(
            tenantCode: tenantCode,
            orgCode: nil,
            baseURL: hostname,
            username: username,
            password: password)
        
		piGeofencingManager.privacy = Settings.privacy

		SSKeychain.setAccessibilityType(kSecAttrAccessibleAlwaysThisDeviceOnly)
		DDLogInfo("Look into the keychain \(hostname) \(tenantCode)")

		let data = SSKeychain.passwordDataForService(hostname, account: tenantCode)

        if let data = data {
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                if let orgCode = json["orgCode"] as? String {
						piGeofencingManager.service.orgCode = orgCode
						DDLogVerbose("OrgCode \(orgCode)")
                } else {
                    DDLogError("orgCode missing in the JSON from the KeyChain",asynchronous:false)
                }
            } catch {
                DDLogError("Can't read JSON in the KeyChain \(error)",asynchronous:false)
            }
		} else {
			DDLogError("Empty keychain",asynchronous:false)
		}

		if piGeofencingManager.service.orgCode == nil {
			Utils.createPIOrg(hostname, tenantCode: tenantCode)
		} else {
			piGeofencingManager.synchronize()

		}


        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)

        piGeofencingManager.delegate = self

        slackQueue.qualityOfService = .Utility
        slackQueue.name = "com.ibm.PI.slackQueue"

        //self.seeding()

        self.manageAuthorizations()

		NSNotificationCenter.defaultCenter().addObserver(
			self,
			selector: "privacyDidChange:",
			name: kPrivacyDidChange,
			object: nil)

        return true
    }

    private func registerDefaultSettings() {

        let settingsURL = NSBundle.mainBundle().URLForResource("Settings", withExtension: "bundle")!
        let settingsBundle = NSBundle(URL: settingsURL)!
        let settingsFile = settingsBundle.URLForResource("Root", withExtension:"plist")!
        let settingsDefault = NSDictionary(contentsOfURL:settingsFile) as? [String:AnyObject]
        var defaultsToRegister = [String:AnyObject]()
		guard let preferences = settingsDefault?["PreferenceSpecifiers"] as? [[String:AnyObject]] else {
			fatalError("Programming Error")
		}

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
        DDLogVerbose("AppDelegate.didBecomeActive")
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        let state = UIApplication .sharedApplication().applicationState
        if state == .Active {

			let title = NSLocalizedString("Alert.LocalNotification.Title",comment:"")
			let message = notification.alertBody ?? NSLocalizedString("Alert.LocalNotification.MissingBody",comment:"")
			self.showAlert(title, message: message)

        }
        
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, withResponseInfo responseInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        
    }
    
    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {

		piGeofencingManager.handleEventsForBackgroundURLSession(identifier, completionHandler: completionHandler)
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
					DDLogError("(error)",asynchronous:false)
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
            dispatch_async(dispatch_get_main_queue()) {
				let title = NSLocalizedString("Alert.NoMonitoring.Title",comment:"")
				let message = NSLocalizedString("Alert.NoMonitoring.Message",comment:"")
				self.showAlert(title, message: message)

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

    private func sendSlackMessage(event:String,geofence: PIGeofence?) {
        
        guard Settings.privacy == false else {
			DDLogVerbose("sendSlackMessage, privacyOn !!!")
            return
        }
        
        guard let slackToken = slackToken else {
			DDLogVerbose("sendSlackMessage, No slack token !!!")
            return
        }
        
        let session = NSURLSession.sharedSession()
        
        let geofenceName = geofence?.name ?? "unknown fence"
        var params:[String:String] = [:]
        params["channel"] = "#geo-spam"
        params["text"] = ":iphone: \(event) : /\(piGeofencingManager.service.orgCode ?? "?")/\(geofence?.code ?? "?")/\(geofenceName)"
        
        let chatPostMessage = SlackOperation(session:session,slackAPI:"chat.postMessage",params:params,token:slackToken)
        // https://developer.apple.com/library/ios/technotes/tn2277/_index.html
        let application = UIApplication.sharedApplication()
        var bkgTaskId = UIBackgroundTaskInvalid
        bkgTaskId = application.beginBackgroundTaskWithExpirationHandler {
            if bkgTaskId != UIBackgroundTaskInvalid {
				DDLogError("****** SlackOperation ExpirationHandler \(bkgTaskId)")
                self.slackQueue.cancelAllOperations()
                let id = bkgTaskId
                bkgTaskId = UIBackgroundTaskInvalid
                application.endBackgroundTask(id)
            }
        }
		if bkgTaskId == UIBackgroundTaskInvalid {
			DDLogError("****** No background time for SlackOperation!!!")
		}

		DDLogVerbose("SlackOperation beginBackgroundTaskWithExpirationHandler \(bkgTaskId)")

        chatPostMessage.completionBlock = {
            chatPostMessage.completionBlock = nil
            
            switch chatPostMessage.result {
            case let .HTTPStatus(status, _)?:
                DDLogError("****** SlackOperation HTTPStatus \(status)")
            case let .Error(error)?:
                DDLogError("****** SlackOperation Error \(error)")
            case let .Exception(exception)?:
				DDLogError("****** SlackOperation Exception \(exception)")
            case .Cancelled?:
				DDLogError("****** SlackOperation cancelled")
            case .OK?:
                DDLogVerbose("SlackOperation OK")
			case nil:
				DDLogError("****** SlackOperation cancelled nil")
            }
			dispatch_async(dispatch_get_main_queue()) {
				if bkgTaskId != UIBackgroundTaskInvalid {
					DDLogVerbose("****** SlackOperation endBackgroundTask \(bkgTaskId)")
					let id = bkgTaskId
					bkgTaskId = UIBackgroundTaskInvalid
					application.endBackgroundTask(id)
				}
			}

        }

        slackQueue.addOperation(chatPostMessage)
        
    }

}

extension AppDelegate {

	// MARK: - PIGeofencingManagerDelegate

	func geofencingManager(manager: PIGeofencingManager, didEnterGeofence geofence: PIGeofence? ) {

		let geofenceName = geofence?.name ?? "Error,unknown fence"
		DDLogVerbose("Did Enter \(geofenceName)")
		sendSlackMessage("enter", geofence: geofence)

		let notification = UILocalNotification()
		notification.alertBody = String(format:NSLocalizedString("Region.Notification.Enter %@", comment: ""),geofenceName)

		notification.soundName = UILocalNotificationDefaultSoundName
		if let geofence = geofence {
			notification.userInfo = ["geofence.code":geofence.code]
		}

		UIApplication.sharedApplication().presentLocalNotificationNow(notification)

	}

	func geofencingManager(manager: PIGeofencingManager, didExitGeofence geofence: PIGeofence? ) {

		let geofenceName = geofence?.name ?? "Error,unknown fence"
		DDLogVerbose("Did Exit \(geofenceName)")
		sendSlackMessage("exit", geofence: geofence)

		let notification = UILocalNotification()
		notification.alertBody = String(format:NSLocalizedString("Region.Notification.Exit %@", comment: ""),geofenceName)

		notification.soundName = UILocalNotificationDefaultSoundName
		if let geofence = geofence {
			notification.userInfo = ["geofence.code":geofence.code]
		}

		UIApplication.sharedApplication().presentLocalNotificationNow(notification)
	}

	func geofencingManager(manager: PIGeofencingManager, didStartDownload download: PIDownload) {
		let notification = UILocalNotification()
		let startDate = self.dynamicType.dateFormatter.stringFromDate(download.startDate)
		notification.alertBody = String(format:NSLocalizedString("Download.Notification.Start %@", comment: ""),startDate)

		notification.soundName = UILocalNotificationDefaultSoundName
		notification.userInfo = ["download.startDate":download.startDate]

		UIApplication.sharedApplication().presentLocalNotificationNow(notification)

	}

	func geofencingManager(manager: PIGeofencingManager, didReceiveDownload download: PIDownload) {
		let notification = UILocalNotification()
		let startDate = self.dynamicType.dateFormatter.stringFromDate(download.startDate)
		if let endDate = download.endDate {
			let endDate = self.dynamicType.dateFormatter.stringFromDate(endDate)
			notification.alertBody = String(format:NSLocalizedString("Download.Notification.End %@ %@ %@", comment: ""),startDate,endDate,"\(download.progressStatus)")
		} else {
			notification.alertBody = String(format:NSLocalizedString("Download.Notification.End %@ %@", comment: ""),startDate, "\(download.progressStatus)")
		}

		notification.soundName = UILocalNotificationDefaultSoundName
		if let endDate = download.endDate {
			notification.userInfo = ["download.endDate":endDate]
		} else {

		}

		UIApplication.sharedApplication().presentLocalNotificationNow(notification)

	}

	

}

extension AppDelegate {

	func privacyDidChange(notification:NSNotification) {
		piGeofencingManager.privacy = Settings.privacy
	}
}

extension AppDelegate {

	func showAlert(title:String,message:String) {

		if let _ = self.window?.rootViewController?.presentedViewController {
			self.window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
		}

		let alertController = UIAlertController(
			title: NSLocalizedString(title,comment:""),
			message: NSLocalizedString(message,comment:""),
			preferredStyle: .Alert)

		let okAction = UIAlertAction(title: NSLocalizedString("OK",comment:""), style: .Default){ (action) in
		}
		alertController.addAction(okAction)


		self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
	}
}

