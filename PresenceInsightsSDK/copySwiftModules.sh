#!/bin/sh

cp Output/PresenceInsightsSDK-Debug-iphonesimulator/PresenceInsightsSDK.framework/Modules/PresenceInsightsSDK.swiftmodule/* Output/PresenceInsightsSDK-Debug-iphoneuniversal/PresenceInsightsSDK.framework/Modules/PresenceInsightsSDK.swiftmodule/
mv Output/PresenceInsightsSDK-Debug-iphoneuniversal/PresenceInsightsSDK.framework Output/
rm -r Output/PresenceInsightsSDK-Debug-iphoneos
rm -r Output/PresenceInsightsSDK-Debug-iphonesimulator
rm -r Output/PresenceInsightsSDK-Debug-iphoneuniversal