/**
*  PresenceInsightsSDK
*  PIZone.swift
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

// MARK: - PIZone object
public class PIZone:NSObject {
    
    // Zone properties
    public let name: String?
    public let polygon: [[CGPoint]]?
    public let tags: [String]?
    
    /**
    Default object initializer.

    - parameter name:    Zone name
    - parameter polygon: a collection of points that encapsulates the zone
    - parameter tags:    useful identifying keywords for the zone
    */
    public init(name: String, polygon: [[CGPoint]], tags: [String]) {
        self.name = name
        self.polygon = polygon
        self.tags = tags
    }
    
    /**
    Convenience initializer to init an empty Object.
    
    - returns: An initialized PIOrg.
    */
    public override init() {
        self.name = nil
        self.polygon = nil
        self.tags = nil
    }
    
    /**
    Convenience initializer which sets the zone name, and sets defaults for the remaining properties.

    - parameter name: Zone name

    - returns: An initialized PIZone.
    */
    public init(name: String) {
        self.name = name
        self.polygon = nil
        self.tags = nil
    }
    
    /**
    Convenience initializer that uses a dictionary to populate the objects properties.

    - parameter dictionary: PIZone represented as a dictionary

    - returns: An initialized PIZone.
    */
    public init(dictionary: [String: AnyObject]) {
        
        // retrieve dictionaries from feature object
        let geometry = dictionary[GeoJSON.GEOMETRY_KEY] as? [String: AnyObject]
        let properties = dictionary[GeoJSON.PROPERTIES_KEY] as? [String: AnyObject]
        
        self.name = properties?[Zone.JSON_NAME_KEY] as? String
        self.tags = properties?[Zone.JSON_TAGS_KEY] as? [String]
        if let coordinates = geometry?[GeoJSON.COORDINATES_KEY] as? [[[CGFloat]]] {
            self.polygon = convertGeoJsonPayload(coordinates)
        } else {
            self.polygon = nil
        }
    }
    
    /**
    Helper function that provides the PIZone object as a dictionary

    - returns: dictionary representation of PIZone
    */
    public func toDictionary() -> [String: Any] {
        
        var dictionary: [String: Any] = [:]
        if let name = name {
            dictionary[Zone.JSON_NAME_KEY] = name
        }
        if let polygon = polygon {
            dictionary[Zone.JSON_POLYGON_KEY] = polygon
        }
        if let tags = tags {
            dictionary[Zone.JSON_TAGS_KEY] = tags
        }
        
        return dictionary

    }
    
}

private func convertGeoJsonPayload(payload: [[[CGFloat]]]) -> [[CGPoint]]{
    var returnPayload = [[CGPoint]]()
    for polygonObj in payload {
        var pointArray = [CGPoint]()
        for points in polygonObj {
            pointArray.append(CGPoint(x: points.first!, y: points.last!))
        }
        returnPayload.append(pointArray)
    }
    return returnPayload
}

