/**
*  PresenceInsightsSDK
*  PIFloor.swift
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

import UIKit

// MARK: - PIFloor object
public class PIFloor: NSObject {

    // Floor properties
    public var name: String!
    public var barriers: CGPoint!
    public var z: Int!

    /**
    Default object initializer.

    - parameter name:       Floor name
    - parameter barriers:   Physical barriers, such as walls. Not Implemented, currently stored as a point
    - parameter z:          Floor level
    */
    public init(name: String, barriers: CGPoint, z: Int) {
        self.name = name
        self.barriers = barriers
        self.z = z
    }

    /**
    Convenience initializer to init an empty Object.

    - returns: An initialized PIFloor.
    */
    public convenience override init() {
        self.init(name: "", barriers: CGPoint() , z: 0)
    }

    /**
    Convenience initializer that uses a dictionary to populate the objects properties.

    - parameter dictionary: PIFloor represented as a dictionary

    - returns: An initialized PIFloor.
    */
    public convenience init(dictionary: [String: AnyObject]) {

        self.init(name: "", barriers: CGPoint(), z: 0)

        // retrieve dictionaries from feature object
        let geometry = dictionary[GeoJSON.GEOMETRY_KEY] as! [String: AnyObject]
        let properties = dictionary[GeoJSON.PROPERTIES_KEY] as! [String: AnyObject]

        self.name = properties[Floor.JSON_NAME_KEY] as! String
        self.z = properties[Floor.JSON_Z_KEY] as! Int
        self.barriers = self.convertGeoJsonPayload(geometry[GeoJSON.COORDINATES_KEY] as! [CGFloat])

    }

    /**
    Helper function that provides the PIFloor object as a dictionary

    - returns: a dictionary representation of PIFloor
    */
    public func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [:]

        dictionary[Floor.JSON_NAME_KEY] = name
        dictionary[Floor.JSON_BARRIERS_KEY] = barriers
        dictionary[Floor.JSON_Z_KEY] = z

        return dictionary

    }

    func convertGeoJsonPayload(payload: [CGFloat]) -> CGPoint{
        return CGPoint(x: payload.first!, y: payload.last!)
    }

}
