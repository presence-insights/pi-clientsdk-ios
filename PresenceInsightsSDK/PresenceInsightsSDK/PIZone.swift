/**
*   PresenceInsightsSDK
*   PIZone.swift
*
*   Object to contain all zone information.
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

// MARK: - PIZone object
public class PIZone: NSObject {
    
    // Zone properties
    public var name: String!
    public var polygon: [[CGPoint]]!
    public var tags: [String]!
    
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
    public convenience override init() {
        self.init(name: "", polygon: [[CGPoint]](), tags: [])
    }
    
    /**
    Convenience initializer which sets the zone name, and sets defaults for the remaining properties.

    - parameter name: Zone name

    - returns: An initialized PIZone.
    */
    public convenience init(name: String) {
        self.init(name: name, polygon: [[CGPoint]](), tags: [])
    }
    
    /**
    Convenience initializer that uses a dictionary to populate the objects properties.

    - parameter dictionary: PIZone represented as a dictionary

    - returns: An initialized PIZone.
    */
    public convenience init(dictionary: [String: AnyObject]) {
        self.init(name: "", polygon: [[CGPoint]](), tags: [])
        
        // retrieve dictionaries from feature object
        let geometry = dictionary[GeoJSON.GEOMETRY_KEY] as! [String: AnyObject]
        let properties = dictionary[GeoJSON.PROPERTIES_KEY] as! [String: AnyObject]
        
        self.name = properties[Zone.JSON_NAME_KEY] as! String
        self.tags = properties[Zone.JSON_TAGS_KEY] as! [String]
        self.polygon = self.convertGeoJsonPayload(geometry[GeoJSON.COORDINATES_KEY] as! [[[CGFloat]]])
    }
    
    /**
    Helper function that provides the PIZone object as a dictionary

    - returns: dictionary representation of PIZone
    */
    public func toDictionary() -> [String: Any] {
        
        var dictionary: [String: Any] = [:]
        
        dictionary[Zone.JSON_NAME_KEY] = name
        dictionary[Zone.JSON_POLYGON_KEY] = polygon
        dictionary[Zone.JSON_TAGS_KEY] = tags
        
        return dictionary

    }
    
    func convertGeoJsonPayload(payload: [[[CGFloat]]]) -> [[CGPoint]]{
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

}
