/**
*  PresenceInsightsSDK
*  PISensor.swift
*
*  Object to contain all beacon information.
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

import UIKit
import CoreLocation

// MARK: - PISensor object
public class PISensor:NSObject {

    // Sensor properties
    public let name: String?
    public let sensorDescription: String?
    public let threshold: CGFloat?
    public let x: CGFloat?
    public let y: CGFloat?
    public let site: String?
    public let floor: String?

    /**
    Default object initializer.

    - parameter name:           Sensor name
    - parameter description:    Sensor description
    - parameter threshold:      Sensor threshold

    */
    public init(name: String, description: String, threshold: CGFloat) {
        self.name = name
        self.sensorDescription = description
        self.threshold = threshold
        self.x = nil
        self.y = nil
        self.site = nil
        self.floor = nil
    }

    /**
    Convenience initializer to init an empty Object.

    - returns: An initialized PISensor.
    */
    public override init() {
        self.name = nil
        self.sensorDescription = nil
        self.threshold = nil
        self.x = nil
        self.y = nil
        self.site = nil
        self.floor = nil
    }

    /**
    Convenience initializer that uses a dictionary to populate the objects properties.

    - parameter dictionary: PISensor represented as a dictionary

    - returns: An initialized PISensor.
    */
    public init(dictionary: [String: AnyObject]) {

        // I prefer this method because if the dictionary isn't built correctly it will at least throw a nil error at runtime.

        // retrieve dictionaries from feature object
        let geometry = dictionary[GeoJSON.GEOMETRY_KEY] as? [String: AnyObject]
        let properties = dictionary[GeoJSON.PROPERTIES_KEY] as? [String: AnyObject]

        self.name = properties?[Sensor.JSON_NAME_KEY] as? String

        self.sensorDescription = dictionary[Sensor.JSON_DESCRIPTION_KEY] as? String
        

        self.threshold = properties?[Sensor.JSON_THRESHOLD_KEY] as? CGFloat
        self.site = properties?[Sensor.JSON_SITE_KEY] as? String
        self.floor = properties?[Sensor.JSON_FLOOR_KEY] as? String

        if let coords = geometry?[GeoJSON.COORDINATES_KEY] as? [CGFloat] where coords.count == 2 {
            self.x = coords[0]
            self.y = coords[1]
        } else {
            self.x = nil
            self.y = nil
        }
    }

    /**
    Helper function that provides the PISensor object as a dictionary

    - returns: a dictionary representation of PISensor
    */
    public func toDictionary() -> [String: AnyObject] {

        var dictionary: [String: AnyObject] = [:]

        if let name = name {
            dictionary[Sensor.JSON_NAME_KEY] = name
        }
        if let sensorDescription = sensorDescription {
            dictionary[Sensor.JSON_DESCRIPTION_KEY] = sensorDescription
        }
        if let threshold = threshold {
            dictionary[Sensor.JSON_THRESHOLD_KEY] = threshold
        }
        if let x = x, y = y {
            dictionary[Sensor.JSON_X_KEY] = x
            dictionary[Sensor.JSON_Y_KEY] = y
        }
        if let site = site {
            dictionary[Sensor.JSON_SITE_KEY] = site
        }
        if let floor = floor {
            dictionary[Sensor.JSON_FLOOR_KEY] = floor
        }

        return dictionary

    }

}
