/**
*   PresenceInsightsSDK
*   Constants.swift
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

import Foundation

struct Device {
    static let JSON_NAME_KEY = "name"
    static let JSON_TYPE_KEY = "registrationType"
    static let JSON_DESCRIPTOR_KEY = "descriptor"
    static let JSON_REGISTERED_KEY = "registered"
    static let JSON_BLACKLIST_KEY = "blacklist"
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
    static let JSON_POLYGON_KEY = "polygon"
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

struct GeoJSON {
    static let FEATURES_KEY = "features"
    static let GEOMETRY_KEY = "geometry"
    static let PROPERTIES_KEY = "properties"
    static let TYPE_KEY = "type"
    static let COORDINATES_KEY = "coordinates"
}