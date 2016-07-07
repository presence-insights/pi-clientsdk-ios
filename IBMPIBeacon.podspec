license = <<EOT
Licensed under the Presence Insights Client iOS Framework License (the "License");
you may not use this file except in compliance with the License. You may find
a copy of the license in the license.txt file in this package.
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
EOT

Pod::Spec.new do |s|
  s.name         = "IBMPIBeacon"
  s.version      = "2.0.2"
  s.summary      = "This framework provides a Beacon Sensor for Presence Insights."
  s.description  = "IBM Presence Insights Beacon framework enables users to communicate to Presence Insights information about the BLE beacons placed in a venue."
  s.homepage     = "http://presenceinsights.ibmcloud.com"
  s.license      = {:type => 'Presence Insights Client iOS Framework License', :text => license}
  s.author       = { "IBM Corp." => "support@ibm.com" }
  s.source       = { :git => "https://github.com/presence-insights/pi-clientsdk-ios.git", :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.requires_arc = true

  s.source_files = 'IBMPIBeacon/*.{swift}'
  s.exclude_files = 'IBMPIBeaconTests/*.{swift}'

  s.dependency 'IBMPICore', '2.0.2'
  s.frameworks = 'CoreLocation'

end
