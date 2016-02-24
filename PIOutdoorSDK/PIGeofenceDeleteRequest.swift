/**
 *  PIOutdoorSDK
 *  PIGeofenceDeleteRequest.swift
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
import CocoaLumberjack

/// Delete a geofence in the Presence Insight platform
public final class PIGeofenceDeleteRequest:Request {
    
    public let completionBlock: Response -> Void
    
    /// The code of the fence to be deleted
    public let geofenceCode:String
    
    
    public init(geofenceCode:String, completionBlock:Response -> Void) {
        self.geofenceCode = geofenceCode
        self.completionBlock = completionBlock
    }
    
    public func execute(service:PIService) -> Response {
        
        let operation = PIGeofenceDeleteOperation(
            service:service,
            geofenceCode: self.geofenceCode)
        
        let response = Response(piRequest: self,operation:operation)
        
        operation.completionBlock = {[unowned self] in
            operation.completionBlock = nil
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                switch operation.result {
                case let .OK(data)?:
					guard let data = data else {
						response.result = .OK(nil)
						break
					}
					do {
						let json = try NSJSONSerialization.JSONObjectWithData(data,options:[])
						response.result = .OK(json)
						print(json)
					} catch {
						DDLogError("PIGeofenceCreateRequest,Json parsing error \(error)")
						response.result = .OK(nil)
					}
                case .Cancelled?:
                    response.result = .Cancelled
                case let .HTTPStatus(status, data)?:
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