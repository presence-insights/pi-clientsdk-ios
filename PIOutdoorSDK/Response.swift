/**
 *  PIOutdoorSDK
 *  Response.swift
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

public class Response {
    
    public let aeRequest: Request
    
    public internal(set) var httpRequest:NSURLRequest?
    public internal(set) var httpResponse:NSHTTPURLResponse?
    
    var operation: ServiceOperation
    
    public enum Result {
        case Cancelled
        case Error(NSError)
        case Exception(ErrorType)
        case HTTPStatus(Int,AnyObject?)
        // Json object
        case OK(AnyObject?)
        
    }
    
    public internal(set) var result:Result?
    
    public func cancel() {
        operation.cancel()
    }
    
    init(aeRequest:Request,operation:ServiceOperation){
        self.aeRequest = aeRequest
        self.operation = operation
    }
    
}
