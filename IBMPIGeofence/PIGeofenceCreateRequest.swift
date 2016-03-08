/**
 *  PIOutdoorSDK
 *  PIGeofenceCreateRequest.swift
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
import CoreLocation
import CocoaLumberjack

/// Creates a geofence in the Presence Insight platform.
public final class PIGeofenceCreateRequest:PIRequest {
    
    public let completionBlock: PIGeofenceCreateResponse -> Void
    
    /// The name of the geofence.
    public let geofenceName:String
    
    /// The description of the geofence
    public let geofenceDescription:String?
    
    /// The radius of the geofence
    public let geofenceRadius:Int
    
    /// The coordinates of the center of the geofence
    public let geofenceCoordinate:CLLocationCoordinate2D
    
    /// - returns: The request to execute for creating a geofence
    public init(geofenceName:String,geofenceDescription:String?,geofenceRadius:Int,geofenceCoordinate:CLLocationCoordinate2D,completionBlock:PIGeofenceCreateResponse -> Void) {
        self.geofenceName = geofenceName
        self.geofenceDescription = geofenceDescription
        self.geofenceRadius = geofenceRadius
        self.geofenceCoordinate = geofenceCoordinate
        self.completionBlock = completionBlock
    }
    
    /// - param service: The PI service
    /// Execute this request against the PI service
    public func execute(service:PIService) -> PIResponse {
        
        let operation = PIGeofenceCreateOperation(
            service:service,
            geofenceName: self.geofenceName,
            geofenceDescription: self.geofenceDescription,
            geofenceRadius: self.geofenceRadius,
            geofenceCoordinate: self.geofenceCoordinate)
        
        let response = PIGeofenceCreateResponse(piRequest: self,operation:operation)
        
        operation.completionBlock = {[unowned self] in
            operation.completionBlock = nil
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                switch operation.result {
                case .OK(let data)?:
                    guard let data = data else {
                        response.result = .OK(nil)
                        break
                    }
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data,options:[])
                        response.result = .OK(json)
                        guard let properties = json["properties"] as? [String:AnyObject] else {
                            DDLogError("PIGeofenceCreateRequest,Missing properties",asynchronous:false)
                            break
                        }
                        
                        guard let geofenceCode = properties["@code"] as? String else {
                            DDLogError("PIGeofenceCreateRequest,Missing Fence ID",asynchronous:false)
                            break
                        }
                        
                        response.geofenceCode = geofenceCode
                    } catch {
                        DDLogError("PIGeofenceCreateRequest,Json parsing error \(error)",asynchronous:false)
                        response.result = .OK(nil)
                    }
                case .Cancelled?:
                    response.result = .Cancelled
                case let .HTTPStatus(status,data)?:
                    if let data = data {
                        let json = try? NSJSONSerialization.JSONObjectWithData(data,options:[])
                        response.result = .HTTPStatus(status,json)
                    } else {
                        response.result = .HTTPStatus(status,nil)
                    }
                case .Error(let error)?:
                    response.result = .Error(error)
                    
                case .Exception(let exception)?:
                    response.result = .Exception(exception)

				case nil:
					response.result = .Cancelled

                }
                self.completionBlock(response)
            })
        }
        
        return response
    }
    
}