/**
*   PresenceInsightsSDK
*   PIZone.swift
*
*   Object to contain all zone information.
*
*   Created by Kyle Craig on 7/27/15.
*   Copyright (c) 2015 IBM Corporation. All rights reserved.
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
    
    public convenience init(dictionary: NSDictionary) {
        
        self.init(name: "", x: 0.0, y: 0.0, width: 0.0, height: 0.0, tags: [])
        
        self.name = dictionary[JSON_NAME_KEY] as! String
        self.x = dictionary[JSON_X_KEY] as! CGFloat
        self.y = dictionary[JSON_Y_KEY] as! CGFloat
        self.width = dictionary[JSON_WIDTH_KEY] as! CGFloat
        self.height = dictionary[JSON_HEIGHT_KEY] as! CGFloat
        self.tags = dictionary[JSON_TAGS_KEY] as! [String]
        
    }
    
    public func toDictionary() -> NSDictionary {
        
        let dictionary = NSMutableDictionary()
        
        dictionary.setObject(name, forKey: JSON_NAME_KEY)
        dictionary.setObject(x, forKey: JSON_X_KEY)
        dictionary.setObject(y, forKey: JSON_Y_KEY)
        dictionary.setObject(width, forKey: JSON_WIDTH_KEY)
        dictionary.setObject(height, forKey: JSON_HEIGHT_KEY)
        dictionary.setObject(tags, forKey: JSON_TAGS_KEY)
        
        return dictionary
        
    }
    
}
