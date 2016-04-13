Presence Insights SDK for iOS
========================

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

This repository contains the source for the PresenceInsightsSDK, an iOS SDK that allows for easy integration of the IBM [Presence Insights](https://console.ng.bluemix.net/catalog/presence-insights/) service available on [Bluemix](https://console.ng.bluemix.net/).

This SDK supports iOS 8+.

Features
--------

* **BLE beacon sensor** - monitor regions, range for beacons, and send beacon notification messages to PI

* **Management Config REST** - make calls to the management config server to retrieve information about your organization

* **Device Registration** - easily registers a smartphone or tablet with your organization.

------

Getting Started
---------------

####Building

If you're using [Carthage](https://github.com/Carthage/Carthage), add the following to your `Cartfile`:

```
github "presence-insights/pi-clientsdk-ios"
```

Then get the `PresenceInsightsSDK.framework`  from your `Carthage/Build/iOS` directory.

If you're using [CocoaPods](https://cocoapods.org/), add the following to your `Podfile`:

```
use_frameworks!

pod 'PresenceInsightsSDK'
```

Or, to build the framework in xcode:

1. Open the `PresenceInsightsSDK.xcodeproj`.
2. Run the `PresenceInsightsSDK-Universal` target.
3. Pull the built framework from the `Output` Folder.

*Note:* You need to build this framework before being able to use it.

####Linking

To use the framework simply drag the PresenceInsightsSDK.framework file into your projects *Embedded Binaries* section of the *General* tab on your project target. Select "Copy items if needed". This should automatically add the framework to all other necessary locations. Then, to use it in your code add:

In swift:

```
import PresenceInsightsSDK
```

or in Objective-C:

```
#import <PresenceInsightsSDk/PresenceInsightsSDK.h>
#import <PresenceInsightsSDk/PresenceInsightsSDK-Swift.h>
```

*Note:* In Objective-C you'll also need to set "Embedded Content Contains Swift Code" to "Yes" in your target's build settings.

--------

Using the SDK
-------------

There are two classes that do most of the heavy lifting: PIAdapter and PIBeaconSensor.

*Note:* All examples will be in Swift as that is the preferred language.

####The PI Adapter

The first thing you need to do is initialize an adapter:

```
var piAdapter = PIAdapter(tenant: <tenant>,
                             org: <org>,
                         baseURL: "https://presenceinsights.ibmcloud.com"
                        username: <username>,
                        password: <password>)
```

You can obtain your tenant, org, username, and password from the Presence Insights dashboard on Bluemix.
(We prefer to place them in a .plist for easy use and modification.)

You are now able to query all sorts of useful information from Presence Insights! 

* How about presenting a floor map to your customers?

```
piAdapter.getMap(<site code>, floor: <floor code>, callback: {floorMap, error in
    // floorMap is of type UIImage
    // display it!
})
```

* You want to get a list of all the beacons on that floor and display their location on the map you just retrieved?

```
piAdapter.getAllBeacons(<site code>, floor: <floor code>, callback: {beacons, error in
    // beacons is of type [PIBeacon]
    // use the x and y coords from each beacon obj to place them on the map.
})
```

####The PI Beacon Sensor

After you initialize the adapter, you can initialize a Beacon Sensor and start sensing for beacons:

```
var piBeaconSensor = PIBeaconSensor(adapter: piAdapter)
piBeaconSensor.start()
```

*Note:* To use PI Beacon Sensing, you need to modify the Info.plist. Add the following key and set the value to the message you want displayed:

* NSLocationAlwaysUsageDescription

And that's really all there is to getting the app to start sending the device location back to your Presence Insights instance.

The SDK by default sends information about the beacons around you every 5 seconds. If you want to adjust that send interval (in ms), its really simple.

```
piBeaconSensor.setReportInterval(10000)
```

To stop beacon sensing:

```
piBeaconSensor.stop()
```

--------

But wait there's more!
----------------------

That isn't all this SDK can do though. Here are some more features you can use to give your user's the benefits of Presence Insights.

####Device Handling

To create a PIDevice:

```
var device = PIDevice(name: <your device name>)
device.type = "External" // these values can be found under Settings of your org in the UI
```

To add encrypted data to a PIDevice:

```
device.addToDataObject(<Custom Data Object>, key: <Custom Key>)
```

To add unencrypted data to a PIDevice:

```
device.addToUnencryptedDataObject(<Custom Data Object>, key: <Custom Key>)
```

To blacklist a Device:

```
device.blacklist = true
```

To register the PIDevice in PI:

```		
piAdapter.registerDevice(device, callback: {newDevice, error in
    // newDevice is of type PIDevice.
    // Do whatever you want with your newDevice here.    
})
```

To update the PIDevice on PI:

```		
piAdapter.updateDevice(device, callback: {newDevice, error in
    // newDevice is of type PIDevice.
    // Do whatever you want with your newDevice here.    
})
```

To unregister the PIDevice from PI:

```
piAdapter.unregisterDevice(device, callback: {newDevice, error in
    // newDevice is of type PIDevice.
    // Do whatever you want with your newDevice here.    
})
```

To get a list of all devices registered in PI:

```
piAdapter.getRegisteredDevices({devices, error in
    // devices is of type [PIDevice]
    // Do whatever you want with the devices array here.
})
```

To get a specific device from PI:

```
piAdapter.getDeviceByCode(<device code>, callback: {device, error in
    // device is of type PIDevice.
    // Do whatever you want with your device here.    
})
```
or
```
piAdapter.getDeviceByDescriptor(<device UUID>, callback: {device, error in
    // device is of type PIDevice.
    // Do whatever you want with your device here.    
})
```

####Beacon Sensor Delegate

We expose several callbacks to offer you the ability to handle beacon events how you would like, in addition to how we are using them.

```
extension <Your class name>: PIBeaconSensorDelegate {
    func didRangeBeacons(beacons: [CLBeacon]) {
        // Do whatever you want with the ranged beacons here.
    }
    func didEnterRegion(region: CLRegion) {
        // Do something with the region you just entered.
    }
    func didExitRegion(region: CLRegion) {
        // Do something with the region you just exited.
    }
}
```

####Other

There are some other little things you can do with this SDK (mostly different ways to initialize or modify objects), but these basics should be enough to get you started. Have fun!

------

Troubleshooting
--------------------

*   First things first, if things are not working, enable debugging to see all the inner workings in the console.

        adapter.enableLogging() // adapter is an instance of PIAdapter

*   I started the beacon sensor, but it is not picking up any beacons. There are a couple reasons why this may be happening.
    1.  The beacons are not configured correctly in the PI UI. Ensure that the Proximity UUID is set correctly. We retrieve that to create a region to range for beacons.
    2.  The codes (username, password, tenant, org) used in creating the PIAdapter may have been entered incorrectly.

*    How can I send location events when the application is in the background or not open?
