//
//  PIGeofencingError.swift
//  PIOutdoorSDK
//
//  Created by slizeray on 29/02/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation


public enum PIGeofencingError:ErrorType {
	case UnzipOpenFile(String)
	case UnzipFileTo(String)
	case EmptyZipFile(NSURL)
	case UnzipCloseFile

	case GeoJsonMissingType
	case GeoJsonWrongType(String)
	case GeoJsonNoFeature

	case GeoJsonMissingFeatureCollectionProperties

	case WrongFences(Int)
	case HTTPStatus(Int,AnyObject?)

	case DownloadError
	case InternalError(ErrorType)
}



extension PIGeofencingError:CustomStringConvertible {
	public var description:String {
		switch self {
		case let .UnzipOpenFile(file):
			return "UnzipOpenFile(\(file))"
		case let .UnzipFileTo(file):
			return "UnzipFileTo(\(file))"
		case let .EmptyZipFile(url):
			return "EmptyZipFile(\(url))"
		case .UnzipCloseFile:
			return "UnzipCloseFile"
		case .GeoJsonMissingType:
			return "GeoJsonMissingType"
		case let .GeoJsonWrongType(type):
			return "GeoJsonWrongType(\(type))"
		case .GeoJsonNoFeature:
			return "GeoJsonNoFeature"
		case .GeoJsonMissingFeatureCollectionProperties:
			return "GeoJsonMissingFeatureCollectionProperties"
		case let .WrongFences(nbErrors):
			return "WrongFences(\(nbErrors))"
		case let .HTTPStatus(status,_):
			return "HTTPStatus(\(status))"
		case .DownloadError:
			return "DownloadError"
		case let .InternalError(error):
			return "InternalError(\(error))"

		}
	}

}