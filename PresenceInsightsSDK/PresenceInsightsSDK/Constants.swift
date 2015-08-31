//
//  Constants.swift
//  PresenceInsightsSDK
//
//  Created by Ciaran Hannigan on 8/31/15.
//  Copyright (c) 2015 IBM MIL. All rights reserved.
//

import Foundation

struct Device {
    static let JSON_NAME_KEY = "name"
    static let JSON_TYPE_KEY = "registrationType"
    static let JSON_DESCRIPTOR_KEY = "descriptor"
    static let JSON_REGISTERED_KEY = "registered"
    static let JSON_CODE_KEY = "@code"
    static let JSON_DATA_KEY = "data"
    static let JSON_UNENCRYPTED_DATA_KEY = "unencryptedData"
}

struct Org {
    static let JSON_NAME_KEY = "name"
    static let JSON_DESCRIPTION_KEY = "description"
    static let JSON_REGISTRATION_TYPES_KEY = "registrationTypes"
    static let JSON_PUBLIC_KEY_KEY = "publicKey"
}

struct Zone {
    static let JSON_NAME_KEY = "name"
    static let JSON_X_KEY = "x"
    static let JSON_Y_KEY = "y"
    static let JSON_WIDTH_KEY = "width"
    static let JSON_HEIGHT_KEY = "height"
    static let JSON_TAGS_KEY = "tags"
}

struct Beacon {
    static let JSON_NAME_KEY = "name"
    static let JSON_DESCRIPTION_KEY = "description"
    static let JSON_UUID_KEY = "proximityUUID"
    static let JSON_MAJOR_KEY = "major"
    static let JSON_MINOR_KEY = "minor"
    static let JSON_X_KEY = "x"
    static let JSON_Y_KEY = "y"
    static let JSON_SITE_KEY = "@site"
    static let JSON_FLOOR_KEY = "@floor"
}