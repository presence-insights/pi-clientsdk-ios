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
import IBMPIGeofence
import CoreLocation
import SSKeychain
import CocoaLumberjack
import MBProgressHUD

let slackToken: String? = "xoxb-16384356389-QhQvfBrIrUgne6CLza7fRkx5"

var piGeofencingManager: PIGeofencingManager?


let kOrgCodeDidChange = "com.ibm.PI.OrgCodeDidChange"
let kProtectedDataDidBecomeAvailable = "com.ibm.PI.ProtectedDataDidBecomeAvailable"

let kPIService = "com.ibm.PI"
let kPIGeofenceAccount = "PIGeofence"

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

	var firstTime = false

    func application(application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

		PIGeofencingManager.enableLogging(true)

		self.postSlack("\(UIDevice.currentDevice().name) : didFinishLaunching")

        registerDefaultSettings()

		var tenantCode:String?
		var hostname:String?
		var username:String?
		var password:String?
		var orgCode:String?

		if let location = launchOptions?[UIApplicationLaunchOptionsLocationKey] {
			DDLogInfo("didFinishLaunchingWithOptions locationOptions \(location)",asynchronous:false)
		} else {
			DDLogInfo("didFinishLaunchingWithOptions empty",asynchronous:false)
		}

		DDLogInfo(
			"applicationState: \(UIApplication.sharedApplication().applicationState.rawValue)",
			asynchronous:false)

		if UIApplication.sharedApplication().applicationState != .Background {
			tenantCode = NSUserDefaults.standardUserDefaults().objectForKey("PITenant") as? String
			hostname = NSUserDefaults.standardUserDefaults().objectForKey("PIHostName") as? String
			username = NSUserDefaults.standardUserDefaults().objectForKey("PIUsername") as? String
			password = NSUserDefaults.standardUserDefaults().objectForKey("PIPassword") as? String
		}


		DDLogVerbose("tenant \(tenantCode ?? "?")",asynchronous:false)
        DDLogVerbose("hostname \(hostname ?? "?")",asynchronous:false)
        DDLogVerbose("username \(username ?? "?")",asynchronous:false)
        DDLogVerbose("password \(password ?? "?")",asynchronous:false)

		SSKeychain.setAccessibilityType(kSecAttrAccessibleAlwaysThisDeviceOnly)

		let data = SSKeychain.passwordDataForService(kPIService, account: kPIGeofenceAccount)

		var json: [String:AnyObject]?
		if let data = data {
			do {
				json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]

				orgCode = json?["orgCode"] as? String
				if let orgCode = orgCode {
					DDLogVerbose("OrgCode \(orgCode)",asynchronous:false)
				} else {
					DDLogError("orgCode missing in the JSON from the KeyChain",asynchronous:false)
				}
				if let tenantCode = tenantCode {
					json?["tenantCode"] = tenantCode
				} else {
					tenantCode = json?["tenantCode"] as? String
					DDLogVerbose("Keychain tenantCode \(tenantCode)",asynchronous:false)
				}
				if let username = username {
					json?["username"] = username
				} else {
					username = json?["username"] as? String
					DDLogVerbose("Keychain username \(username)",asynchronous:false)
				}
				if let password = password {
					json?["password"] = password
				} else {
					password = json?["password"] as? String
					DDLogVerbose("Keychain password \(password)",asynchronous:false)
				}
				if let hostname = hostname {
					json?["hostname"] = hostname
				} else {
					hostname = json?["hostname"] as? String
					DDLogVerbose("Keychain hostname \(hostname)",asynchronous:false)
				}

			} catch {
				DDLogError("Can't read JSON in the KeyChain \(error)",asynchronous:false)
			}
		} else {
			DDLogInfo("Empty keychain",asynchronous:false)
			json = [:]
			json?["tenantCode"] = tenantCode
			json?["username"] = username
			json?["password"] = password
			json?["hostname"] = hostname

		}

        NetworkActivityIndicatorManager.sharedInstance.enableActivityIndicator(true)

		if
			let tenantCode = tenantCode,
			let hostname = hostname,
			let username = username,
			let password = password {

			piGeofencingManager = PIGeofencingManager(
				tenantCode: tenantCode,
				orgCode: nil,
				baseURL: hostname,
				username: username,
				password: password)
			
		} else {
			DDLogError("Fail to create PIGeofencingManager",asynchronous:false)
			return true
		}

		piGeofencingManager?.privacy = Settings.privacy

		self.firstTime = piGeofencingManager?.firstTime ?? true

		if let orgCode = orgCode {
			if
				let json = json,
				let data = try? NSJSONSerialization.dataWithJSONObject(json, options: [])  {
				SSKeychain.setPasswordData(
					data,
					forService: kPIService,
					account: kPIGeofenceAccount)
			} else {
				DDLogError("didFinishLaunchingWithOptions Programming Error",asynchronous:false)
			}
			piGeofencingManager?.service.orgCode = orgCode
		} else {
			let vc = self.window!.rootViewController!
			MBProgressHUD.showHUDAddedTo(vc.view, animated: true)
			Utils.createPIOrg(hostname!, tenantCode: tenantCode!,vc:vc) {
				orgCode in
				json?["orgCode"] = orgCode
				if
					let json = json,
					let data = try? NSJSONSerialization.dataWithJSONObject(json, options: [])  {
					SSKeychain.setPasswordData(
						data,
						forService: kPIService,
						account: kPIGeofenceAccount)
				} else {
					DDLogError("didFinishLaunchingWithOptions Programming Error",asynchronous:false)
				}
				piGeofencingManager?.service.orgCode = orgCode
				MBProgressHUD.hideHUDForView(vc.view, animated: true)
			}
		}
		// Local seed
		if self.firstTime {
			self.seeding {
			}
		}

        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)

        piGeofencingManager?.delegate = self

        slackQueue.qualityOfService = .Utility
        slackQueue.name = "com.ibm.PI.slackQueue"

        //self.seeding()

        self.manageAuthorizations()

		NSNotificationCenter.defaultCenter().addObserver(
			self,
			selector: #selector(AppDelegate.privacyDidChange(_:)),
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

	func applicationProtectedDataDidBecomeAvailable(application: UIApplication) {

		// http://stackoverflow.com/questions/20269116/nsuserdefaults-loosing-its-keys-values-when-phone-is-rebooted-but-not-unlocked
		
		DDLogInfo("applicationProtectedDataDidBecomeAvailable",asynchronous:false)

		NSUserDefaults.resetStandardUserDefaults()
		registerDefaultSettings()

		piGeofencingManager?.privacy = Settings.privacy
		
		NSNotificationCenter.defaultCenter().postNotificationName(
			kProtectedDataDidBecomeAvailable,
			object: nil)

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

		DDLogVerbose("AppDelegate.didBecomeActive",asynchronous:false)

		NetworkActivityIndicatorManager.sharedInstance.refreshNetworkActivityIndicator()
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

		piGeofencingManager?.handleEventsForBackgroundURLSession(identifier, completionHandler: completionHandler)
    }

}


extension AppDelegate {
    
	private func seeding(completionHandler:() -> Void){
        
		if piGeofencingManager?.firstTime == true {
            guard let url = NSBundle.mainBundle().URLForResource(
				"referentiel-gares-voyageurs.geojson",
				withExtension: "zip") else {
                fatalError("file not found")
            }
			piGeofencingManager?.seedGeojsonWithURL(
				url,
				propertiesGenerator:fenceProperties) { success in
				if success == false {
					DDLogError("seedGeojsonWithURL error")
				}
				completionHandler()

			}
        }
        
    }

    func fenceProperties(properties:[String:AnyObject]) -> PIGeofenceProperties {
        let name = properties["intitule_gare"] as? String ?? "???!!!"
        let fenceProperties = PIGeofenceProperties(name:name,radius:100,code:nil,local: true)
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
                self.checkNoMonitoringRegions()
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

	private func checkNoMonitoringRegions() {
		if self.firstTime && locationManager.monitoredRegions.isEmpty == false {
			DDLogError("After installation, already monitoring \(locationManager.monitoredRegions.count)",asynchronous:false)
			postSlack("After installation, already monitoring \(locationManager.monitoredRegions.count)")
			for region in locationManager.monitoredRegions {
				DDLogError("Monitoring unknow region \(region.identifier)",asynchronous:false)
				locationManager.stopMonitoringForRegion(region)
			}

		}

	}
}

extension AppDelegate:PIGeofencingManagerDelegate {

	func postSlackCreateOrg(orgCode:String?) {
		let message = ":iphone: New Org Code : \(orgCode ?? "No Org Code!")"

		postSlack(message)

	}

    func postSlackGeofenceEvent(event:String,geofence: PIGeofence?) {
        

        let geofenceName = geofence?.name ?? "unknown fence"
        let message = ":iphone: \(event) : /\(piGeofencingManager?.service.orgCode ?? "?")/\(geofence?.code ?? "?")/\(geofenceName)"

		postSlack(message)

    }

	func postSlack(text:String) {

		guard Settings.privacy == false else {
			DDLogVerbose("sendSlackMessage, privacyOn !!!",asynchronous:false)
			return
		}

		guard let slackToken = slackToken else {
			DDLogVerbose("sendSlackMessage, No slack token !!!",asynchronous:false)
			return
		}

		let session = NSURLSession.sharedSession()

		var params:[String:String] = [:]
		params["channel"] = "#geo-spam"
		params["text"] = text

		let chatPostMessage = SlackOperation(session:session,slackAPI:"chat.postMessage",params:params,token:slackToken)
		// https://developer.apple.com/library/ios/technotes/tn2277/_index.html
		let application = UIApplication.sharedApplication()
		var bkgTaskId = UIBackgroundTaskInvalid
		bkgTaskId = application.beginBackgroundTaskWithExpirationHandler {
			if bkgTaskId != UIBackgroundTaskInvalid {
				DDLogError("****** SlackOperation ExpirationHandler \(bkgTaskId)",asynchronous:false)
				self.slackQueue.cancelAllOperations()
				let id = bkgTaskId
				bkgTaskId = UIBackgroundTaskInvalid
				application.endBackgroundTask(id)
			}
		}
		if bkgTaskId == UIBackgroundTaskInvalid {
			DDLogError("****** No background time for SlackOperation!!!",asynchronous:false)
		}

		DDLogVerbose("SlackOperation beginBackgroundTaskWithExpirationHandler \(bkgTaskId)",asynchronous:false)

		chatPostMessage.completionBlock = {
			chatPostMessage.completionBlock = nil

			switch chatPostMessage.result {
			case let .HTTPStatus(status, _)?:
				DDLogError("****** SlackOperation HTTPStatus \(status)",asynchronous:false)
			case let .Error(error)?:
				DDLogError("****** SlackOperation Error \(error)",asynchronous:false)
			case let .Exception(exception)?:
				DDLogError("****** SlackOperation Exception \(exception)",asynchronous:false)
			case .Cancelled?:
				DDLogError("****** SlackOperation cancelled",asynchronous:false)
			case .OK?:
				DDLogVerbose("SlackOperation OK",asynchronous:false)
			case nil:
				DDLogError("****** SlackOperation cancelled nil",asynchronous:false)
			}
			dispatch_async(dispatch_get_main_queue()) {
				if bkgTaskId != UIBackgroundTaskInvalid {
					DDLogVerbose("****** SlackOperation endBackgroundTask \(bkgTaskId)",asynchronous:false)
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
		DDLogVerbose("Did Enter \(geofenceName)",asynchronous:false)
		postSlackGeofenceEvent("enter", geofence: geofence)

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
		DDLogVerbose("Did Exit \(geofenceName)",asynchronous:false)
		postSlackGeofenceEvent("exit", geofence: geofence)

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
		piGeofencingManager?.privacy = Settings.privacy
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

