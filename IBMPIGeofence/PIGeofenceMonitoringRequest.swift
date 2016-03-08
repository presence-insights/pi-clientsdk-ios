/**
 *  PIOutdoorSDK
 *  PIGeofenceMonitoringRequest.swift
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

public enum PIGeofenceEvent:String {
    case Enter = "enter"
    case Exit = "exit"
}

/// Post a geofence event to the Presence Insight platform.
public final class PIGeofenceMonitoringRequest:PIRequest {
    
    public let completionBlock: PIResponse -> Void

	/// PI Geofence code
    public let geofenceCode:String

	/// Time of the event
    public let eventTime:NSDate

	/// Type of the event, entering or exiting a geofence
    public let event:PIGeofenceEvent

	/// For debugging only
	public let geofenceName:String?

	public init(geofenceCode:String,eventTime:NSDate,event:PIGeofenceEvent,geofenceName:String? = nil,completionBlock:PIResponse -> Void) {
        self.geofenceCode = geofenceCode
        self.eventTime = eventTime
        self.event = event
		self.geofenceName = geofenceName
        self.completionBlock = completionBlock
    }
    
    public func execute(service:PIService) -> PIResponse {
        
        let operation = PIGeofenceMonitoringOperation(service:service,geofenceCode: self.geofenceCode,eventTime: self.eventTime,event: self.event,geofenceName: self.geofenceName)
        let response = PIResponse(piRequest: self,operation:operation)
        
        operation.completionBlock = {[unowned self] in
            operation.completionBlock = nil
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                switch operation.result {
                case .OK(let data)?:
                    guard let data = data else {
                        response.result = .OK(nil)
                        break
                    }
                    let json = try? NSJSONSerialization.JSONObjectWithData(data,options:[])
                    response.result = .OK(json)
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