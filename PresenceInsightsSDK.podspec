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
  s.name         = "PresenceInsightsSDK"
  s.version      = "1.2.0"
  s.summary      = "IBM Presence Insights SDK for iOS."
  s.description  = <<-DESC
                    Presence Insights SDK enables users to communicate with
                    the Presence Insights services either sending events or
                    obtaining configuration data.
                   DESC
  s.homepage     = "http://presenceinsights.ibmcloud.com"
  s.license      = {:type => 'Presence Insights Client iOS Framework License', :text => license}
  s.author       = { "IBM Corp." => "support@ibm.com" }
  s.source       = { :git => "https://github.com/presence-insights/pi-clientsdk-ios.git", :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.requires_arc = true

  s.default_subspec = 'standard'

  s.subspec 'standard' do |sp|
    sp.source_files = 'PresenceInsightsSDK/**/*.{swift}'
    sp.exclude_files = 'PresenceInsightsSDKTests/*.{swift}'

    sp.frameworks = 'CoreLocation'
  end

end
