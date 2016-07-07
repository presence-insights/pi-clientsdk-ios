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


@objc(IBMPIGeofencingError)
public enum PIGeofencingError:Int,ErrorType {
	case UnzipOpenFile
	case UnzipFileTo
	case EmptyZipFile
	case UnzipCloseFile

	case GeoJsonMissingType
	case GeoJsonWrongType
	case GeoJsonNoFeature

	case GeoJsonPIError

	case GeoJsonMissingFeatureCollectionProperties

	case WrongFences
	case HTTPStatus

	case DownloadError
	case InternalError
}



extension PIGeofencingError:CustomStringConvertible {
	public var description:String {
		switch self {
		case .UnzipOpenFile:
			return "UnzipOpenFile"
		case .UnzipFileTo:
			return "UnzipFileTo"
		case .EmptyZipFile:
			return "EmptyZipFile"
		case .UnzipCloseFile:
			return "UnzipCloseFile"
		case .GeoJsonMissingType:
			return "GeoJsonMissingType"
		case .GeoJsonWrongType:
			return "GeoJsonWrongType"
		case .GeoJsonPIError:
			return "GeoJsonPIError"
		case .GeoJsonNoFeature:
			return "GeoJsonNoFeature"
		case .GeoJsonMissingFeatureCollectionProperties:
			return "GeoJsonMissingFeatureCollectionProperties"
		case .WrongFences:
			return "WrongFences"
		case .HTTPStatus:
			return "HTTPStatus"
		case .DownloadError:
			return "DownloadError"
		case .InternalError:
			return "InternalError"

		}
	}

}