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

public class PIZone: NSObject {
    
    // Defined Values
    let JSON_NAME_KEY = "name"
    let JSON_X_KEY = "x"
    let JSON_Y_KEY = "y"
    let JSON_WIDTH_KEY = "width"
    let JSON_HEIGHT_KEY = "height"
    let JSON_TAGS_KEY = "tags"
    
    // Zone properties
    public var name: String!
    public var x: CGFloat!
    public var y: CGFloat!
    public var width: CGFloat!
    public var height: CGFloat!
    public var tags: [String]!
    
    public init(name: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, tags: [String]) {
        self.name = name
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.tags = tags
    }
    
    public convenience init(name: String) {
        self.init(name: name, x: 0.0, y: 0.0, width: 0.0, height: 0.0, tags: [])
    }
    
    public convenience init(dictionary: [String: AnyObject]) {
        
        self.init(name: "", x: 0.0, y: 0.0, width: 0.0, height: 0.0, tags: [])
        
        self.name = dictionary[JSON_NAME_KEY] as! String
        self.x = dictionary[JSON_X_KEY] as! CGFloat
        self.y = dictionary[JSON_Y_KEY] as! CGFloat
        self.width = dictionary[JSON_WIDTH_KEY] as! CGFloat
        self.height = dictionary[JSON_HEIGHT_KEY] as! CGFloat
        self.tags = dictionary[JSON_TAGS_KEY] as! [String]
        
    }
    
    public func toDictionary() -> [String: AnyObject] {
        
        var dictionary: [String: AnyObject] = [:]
        
        dictionary[JSON_NAME_KEY] = name
        dictionary[JSON_X_KEY] = x
        dictionary[JSON_Y_KEY] = y
        dictionary[JSON_WIDTH_KEY] = width
        dictionary[JSON_HEIGHT_KEY] = height
        dictionary[JSON_TAGS_KEY] = tags
        
        return dictionary

    }
    
}
