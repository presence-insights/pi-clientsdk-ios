/**
 *  PresenceInsightsSDK
 *  CLProximity+CustomStringConvertible
 *
 *  Object to contain all zone information.
 *
 *  © Copyright 2015 IBM Corp.
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

import CoreLocation



extension CLProximity:CustomStringConvertible {
    public var description:String {
        switch self {
        case .Unknown:
            return "Unknown"
        case .Immediate:
            return "Immediate"
        case .Near:
            return "Near"
        case .Far:
            return "Far"
            
        }
    }
}

