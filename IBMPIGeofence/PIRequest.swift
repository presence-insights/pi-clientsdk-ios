/**
 *  IBMPIGeofence
 *  PIRequest.swift
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


/**
 Protocol that should be adopted by all PI request
 */

@objc(IBMPIRequest)
public protocol PIRequest {
    
    
    /**
     - parameter service: the PI instance
     - returns: a Response instance
     */
    
    func execute(service:PIService) -> PIResponse
    
    
}