/**
*  IBMPIGeofence
*  PIGeofencingError.swift
*
*  Performs all communication to the PI Rest API.
*
*  © Copyright 2016 IBM Corp.
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