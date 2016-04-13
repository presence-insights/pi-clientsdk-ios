license = <<EOT
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
EOT

Pod::Spec.new do |s|
  s.name     = 'IBMPIGeofence'
  s.version  = '2.0.1'
  s.license      = {:type => 'Apache', :text => license}
  s.summary  = 'IBM Presence Insight Outdoor SDK for iOS.'
  s.description  = <<-DESC
                Presence Insights Outdoor SDK enables users to communicate with
                the Presence Insights services either sending events or
                obtaining configuration data.
                DESC
  s.homepage = 'https://github.com/presence-insights/pi-clientsdk-ios'
  s.social_media_url = 'https://twitter.com/ibmmobile'
  s.authors  = { "IBM Corp." => "support@ibm.com" }
  s.source   = { :git => 'https://github.com/presence-insights/pi-clientsdk-ios', :tag => s.version }
  s.requires_arc = true

  s.ios.deployment_target = '8.0'
  s.source_files = 'IBMPIGeofence'
  s.resources = ["IBMPIGeofence/*.xcdatamodel"]

  s.dependency 'ZipArchive'
  s.dependency 'CocoaLumberjack/Swift'

end
