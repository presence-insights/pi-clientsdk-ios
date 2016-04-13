# IBMPIGeofenceSDK

IBMPIGeofenceSDK allows to monitor an unlimited number of geofences defined on the Presence Insight platform. 
It is written in Swift but the SDK is interoperable with Objective-C.

At any time, you can add, remove or update geofences on the Presence Insight plateform and IBMPIGeofenceSDK 
will automatically synchronize against the Presence Insight backend.

The SDK does not use the GPS and is therefore energy efficient and does not drain the battery.

IBMPIGeofenceSDK has been tested with several thousands of geofences. 
The recommended minimal radius for a geofence is 100 meters. Geofences should not overlap and should be distant
at least few hundreds meters. 

Each time the user enters or exits a geofence, the Presence Insight platform is notified.


## Installation

IBMPIGeofenceSDK requires a minimum deployment target of iOS 8.

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.0.0.beta5+ is required to build IBMPIGeofenceSDK 1.0.0.

To integrate IBMPIGeofenceSDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
platform :ios, '8.0'
use_frameworks!

pod 'IBMPIGeofence',:git => 'git@github.com:presence-insights/pi-clientsdk-ios.git',  :branch => '89855_dev_outdoor'
```

Then, run the following command:

```bash
$ pod install
```

## Usage

To enable the Presence Insight geofencing  you must instantiate `PIGeofencingManager` 
and implement `handleEventsForBackgroundURLSession` in the AppDelegate

```swift
import IBMPIGeofence

var piGeofencingManager: PIGeofencingManager?

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
	
		PIGeofencingManager.enableLogging(true)

		let tenantCode = "<YOUR TENANT>"
		let orgCode = "<YOUR ORGANIZATION>"
		let baseURL = "http://pi-outdoor-proxy.mybluemix.net"
		let username = "???"
		let password = "???"

		piGeofencingManager = PIGeofencingManager(
			tenantCode: tenantCode,
			orgCode: orgCode,
			baseURL: baseURL,
			username: username,
			password: password)

	}
	
	func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {

		piGeofencingManager?.handleEventsForBackgroundURLSession(identifier, completionHandler: completionHandler)
	}

	
}
```

```objective-c
@import IBMPIGeofence;

@implementation AppDelegate

IBMPIGeofencingManager *geofencingManager;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.

	[IBMPIGeofencingManager enableLogging:true];

	NSString *tenantCode = @"<YOUR TENANT>";
	NSString *orgCode = @"<YOUR ORGANIZATION>";
	NSString *baseURL = @"http://pi-outdoor-proxy.mybluemix.net";
	NSString *username = @"???";
	NSString *password = @"???";

	geofencingManager = [[IBMPIGeofencingManager alloc]
						 initWithTenantCode:tenantCode
						 orgCode:orgCode
						 baseURL:baseURL
						 username:username
						 password:password
						 maxDistance:10000 maxRegions:15];




	return YES;
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {

	[geofencingManager handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
}

@end
```

### Synchronization

The method `handleEventsForBackgroundURLSession` is necessary because IBMPIGeofenceSDK downloads the geofences using
the iOS Background Transfert Service.

By default, IBMPIGeofenceSDK checks at most once a day, if there are new geofences on the backend. You can change
this default value with the property:

```swift
public final class PIGeofencingManager:NSObject {

	/// Number of hours between each check against PI for downloading the geofence definitions 
	public var intervalBetweenDownloads = 24

}
```

```objective-c
@interface IBMPIGeofencingManager : NSObject

/// Number of hours between each check against PI for downloading the geofence definitions
@property (nonatomic) NSInteger intervalBetweenDownloads;

@end
```

### Enter and Exit events

If you wish to be notified when the user enters or exits a geofence, you need to implement `PIGeofencingManagerDelegate`


```swift
extension AppDelegate:PIGeofencingManagerDelegate {

	// MARK: - PIGeofencingManagerDelegate

	func geofencingManager(manager: PIGeofencingManager, didEnterGeofence geofence: PIGeofence? ) {


	}

	func geofencingManager(manager: PIGeofencingManager, didExitGeofence geofence: PIGeofence? ) {

	}


}

```

```objective-c
@import IBMPIGeofence;

@interface AppDelegate () <IBMPIGeofencingManagerDelegate>

@end

@implementation AppDelegate
/// The device enters into a geofence
- (void)geofencingManager:(IBMPIGeofencingManager * _Nonnull)manager didEnterGeofence:(IBMPIGeofence * _Nullable)geofence {

}

/// The device exits a geofence
- (void)geofencingManager:(IBMPIGeofencingManager * _Nonnull)manager didExitGeofence:(IBMPIGeofence * _Nullable)geofence {

}
@end
```

### Initializing the list of geofences from a resource

You can embed a zipped geojson file as a resource to initialize the list of geofences to monitor.

```swift
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

			}
    }
    
    func fenceProperties(properties:[String:AnyObject]) -> PIGeofenceProperties {
        let name = properties["intitule_gare"] as? String ?? "???"
        let fenceProperties = PIGeofenceProperties(name:name,radius:200,code:nil,local: true)
        return fenceProperties
    }
    
```

```objective-c
	if (geofencingManager.firstTime) {
		NSURL *url = [[NSBundle mainBundle] URLForResource:@"referentiel-gares-voyageurs.geojson" withExtension:@"zip"];


		[geofencingManager seedGeojsonWithURL:url propertiesGenerator:^IBMPIGeofenceProperties * _Nonnull(NSDictionary<NSString *,id> * _Nonnull fence) {
			NSString *name = fence[@"name"];
			if (name == NULL) {
				name = @"??";
			}
			return [[IBMPIGeofenceProperties alloc] initWithName:@"xx" radius:100 code:@"dd" local:false];
		} completionHandler:^(BOOL success) {
		}];

	}
```

### Logging

IBMPIGeofenceSDK can log traces for debugging purpose, thanks to [CocoaLumberjack](https://cocoapods.org/pods/CocoaLumberjack).

To enable the logging:

```swift
	PIGeofencingManager.enableLogging(true)
```

```objective-c
	[IBMPIGeofencingManager enableLogging:true];
```

To get the paths to the log files,


```swift
	let logFiles = PIGeofencingManager.logFiles()
```

```objective-c
	NSArray *logFiles = [IBMPIGeofencingManager logFiles];
```





