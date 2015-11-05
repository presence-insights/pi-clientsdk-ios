/**
*   PresenceInsightsSDK
*   PISensor.swift
*
*   Object to contain all beacon information.
*
*   Copyright (c) 2015 IBM Corporation. All rights reserved.
*
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*
*   http://www.apache.org/licenses/LICENSE-2.0
*
*   Unless required by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
**/

import UIKit
import CoreLocation

// MARK: - PISensor object
public class PISensor: NSObject {

    // Sensor properties
    public var name: String!
    public var sensorDescription: String!
    public var threshold: CGFloat!
    public var x: CGFloat!
    public var y: CGFloat!
    public var site: String!
    public var floor: String!

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
        self.x = 0.0
        self.y = 0.0
        self.site = ""
        self.floor = ""
    }

    /**
    Convenience initializer to init an empty Object.

    - returns: An initialized PISensor.
    */
    public convenience override init() {
        self.init(name: "", description: "", threshold: 0.0)
    }

    /**
    Convenience initializer that uses a dictionary to populate the objects properties.

    - parameter dictionary: PISensor represented as a dictionary

    - returns: An initialized PISensor.
    */
    public convenience init(dictionary: [String: AnyObject]) {

        // I prefer this method because if the dictionary isn't built correctly it will at least throw a nil error at runtime.
        self.init(name: "", description: "", threshold: 0.0)

        // retrieve dictionaries from feature object
        let geometry = dictionary[GeoJSON.GEOMETRY_KEY] as! [String: AnyObject]
        let properties = dictionary[GeoJSON.PROPERTIES_KEY] as! [String: AnyObject]

        self.name = properties[Sensor.JSON_NAME_KEY] as! String

        if let piDescription = dictionary[Sensor.JSON_DESCRIPTION_KEY] as? String {
            self.sensorDescription = piDescription;
        }

        self.threshold = properties[Sensor.JSON_THRESHOLD_KEY] as! CGFloat
        self.site = properties[Sensor.JSON_SITE_KEY] as! String
        self.floor = properties[Sensor.JSON_FLOOR_KEY] as! String

        let coords = geometry[GeoJSON.COORDINATES_KEY] as! [CGFloat]

        self.x = coords[0]
        self.y = coords[1]
    }

    /**
    Helper function that provides the PISensor object as a dictionary

    - returns: a dictionary representation of PISensor
    */
    public func toDictionary() -> [String: AnyObject] {

        var dictionary: [String: AnyObject] = [:]

        dictionary[Sensor.JSON_NAME_KEY] = name
        dictionary[Sensor.JSON_DESCRIPTION_KEY] = sensorDescription
        dictionary[Sensor.JSON_THRESHOLD_KEY] = threshold
        dictionary[Sensor.JSON_X_KEY] = x
        dictionary[Sensor.JSON_Y_KEY] = y
        dictionary[Sensor.JSON_SITE_KEY] = site
        dictionary[Sensor.JSON_FLOOR_KEY] = floor

        return dictionary

    }

}
