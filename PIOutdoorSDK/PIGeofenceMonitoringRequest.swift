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
    case Exit = "leave"
}

public class PIGeofenceMonitoringRequest:Request {
    
    public let completionBlock: Response -> Void
    
    public let fenceId:String
    
    public let eventTime:NSDate
    
    public let event:PIGeofenceEvent
    
    public init(fenceId:String,eventTime:NSDate,event:PIGeofenceEvent,completionBlock:Response -> Void) {
        self.fenceId = fenceId
        self.eventTime = eventTime
        self.event = event
        self.completionBlock = completionBlock
    }
    
    public func execute(service:PIService) -> Response {
        
        let operation = PIGeofenceMonitoringOperation(service:service,fenceId: self.fenceId,eventTime: self.eventTime,event: self.event)
        let response = Response(aeRequest: self,operation:operation)
        
        operation.completionBlock = {[unowned self] in
            operation.completionBlock = nil
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                switch operation.result! {
                case .OK(let data):
                    guard let data = data else {
                        response.result = .OK(nil)
                        break
                    }
                    let json = try? NSJSONSerialization.JSONObjectWithData(data,options:[])
                    response.result = .OK(json)
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