# Uncomment this line to define a global platform for your project
platform :ios, '8.0'
# Uncomment this line if you're using Swift

workspace 'PresenceInsightsSDK'
project 'IBMPICore.xcodeproj'
project 'IBMPIBeacon.xcodeproj'
project 'IBMPIGeofence.xcodeproj'
project 'IBMPIGeofenceSample/IBMPIGeofenceSample.xcodeproj'


use_frameworks!

target 'IBMPICore' do
project 'IBMPICore.xcodeproj'
end

target 'IBMPIBeacon' do
project 'IBMPIBeacon.xcodeproj'
end

target 'IBMPIGeofence' do
pod 'ZipArchive'
pod 'CocoaLumberjack/Swift'
project 'IBMPIGeofence.xcodeproj'
end

target 'IBMPIGeofenceSample' do
pod 'ZipArchive'
pod 'CocoaLumberjack/Swift'
project 'IBMPIGeofenceSample/IBMPIGeofenceSample.xcodeproj'
end

