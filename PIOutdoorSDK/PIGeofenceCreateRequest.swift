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

final class PIGeofenceCreateRequest:Request {
    
    let completionBlock: PIGeofenceCreateResponse -> Void
    
    let fenceName:String
    
    let fenceDescription:String?
    
    let fenceRadius:Int
    
    let fenceCoordinate:CLLocationCoordinate2D
    
    init(fenceName:String,fenceDescription:String?,fenceRadius:Int,fenceCoordinate:CLLocationCoordinate2D,completionBlock:PIGeofenceCreateResponse -> Void) {
        self.fenceName = fenceName
        self.fenceDescription = fenceDescription
        self.fenceRadius = fenceRadius
        self.fenceCoordinate = fenceCoordinate
        self.completionBlock = completionBlock
    }
    
    func execute(service:PIService) -> Response {
        
        let operation = PIGeofenceCreateOperation(
            service:service,
            fenceName: self.fenceName,
            fenceDescription: self.fenceDescription,
            fenceRadius: self.fenceRadius,
            fenceCoordinate: self.fenceCoordinate)
        
        let response = PIGeofenceCreateResponse(piRequest: self,operation:operation)
        
        operation.completionBlock = {[unowned self] in
            operation.completionBlock = nil
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                switch operation.result! {
                case .OK(let data):
                    guard let data = data else {
                        response.result = .OK(nil)
                        break
                    }
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data,options:[])
                        response.result = .OK(json)
                        guard let properties = json["properties"] as? [String:AnyObject] else {
                            DDLogError("PIGeofenceCreateRequest,Missing properties")
                            break
                        }
                        
                        guard let fenceId = properties["@code"] as? String else {
                            DDLogError("PIGeofenceCreateRequest,Missing Fence ID")
                            break
                        }
                        
                        response.fenceId = fenceId
                    } catch {
                        DDLogError("PIGeofenceCreateRequest,Json parsing error \(error)")
                        response.result = .OK(nil)
                    }
                case .Cancelled:
                    response.result = .Cancelled
                case let .HTTPStatus(status,data):
                    if let data = data {
                        let json = try? NSJSONSerialization.JSONObjectWithData(data,options:[])
                        response.result = .HTTPStatus(status,json)
                    } else {
                        response.result = .HTTPStatus(status,nil)
                    }
                case .Error(let error):
                    response.result = .Error(error)
                    
                case .Exception(let exception):
                    response.result = .Exception(exception)
                    
                }
                self.completionBlock(response)
            })
        }
        
        return response
    }
    
}