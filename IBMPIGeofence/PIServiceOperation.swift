/**
 *  IBMPIGeofence
 *  PIServiceOperation.swift
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

@objc(IBMPIServiceOperation)
class PIServiceOperation: AsynchronousOperation {
    
    private var didStart = false
    
    var task:NSURLSessionTask?
    
    unowned let service:PIService
    
    var result:HTTPOperationResult?
    
    var request:NSURLRequest?
    
    var response:NSHTTPURLResponse?
    
    init(service:PIService){
        self.service = service
    }
    
    
    override var executing: Bool {
        didSet {
            if executing {
                self.didStart = true
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotificationName(
                        kIBMPINetworkDidStartRequest,
                        object: self)
                }
            }
        }
    }
    
    override var finished: Bool {
        didSet {
            if finished && self.didStart {
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotificationName(
                        kIBMPINetworkDidEndRequest,
                        object: self)
                }
            }
            
        }
    }
    
    override func cancel() {
        synchronized {
            super.cancel()
            self.task?.cancel()
        }
    }
    
    /// Returns true if the error is a time out
    
    func isTimeout(error:NSError) -> Bool {
        
        return error.domain == NSURLErrorDomain && error.code == NSURLErrorTimedOut
        
    }
    
    /// Returns true if the error indicates the HTTP request has been cancelled
    
    func isTaskCancelled(error:NSError) -> Bool {
        
        return error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled
        
    }
    
    
    func setBasicAuthHeader(request:NSMutableURLRequest) {

		guard PIGeofenceUtils.setBasicAuthHeader(request, username: service.username, password: service.password) == true else {
			DDLogError("Couldn't set the basic authentication header",asynchronous:false)
			return
		}
    }
    
}


extension PIServiceOperation {
    func performRequest(request:NSURLRequest,retryCount:Int = 0,completionHandler: () -> ())  {
        
        self.request = request
        synchronized {
            if self.cancelled {
                self.result = .Cancelled
                completionHandler()
                return
            }
            
            self.task = self.service.serviceSession.dataTaskWithRequest(request)  {
                [unowned self] (data, response, error) -> Void in
                self.response = response as? NSHTTPURLResponse
                if let error = error {
                    if self.isTaskCancelled(error) {
                        self.result = .Cancelled
                    } else if retryCount < REQUEST_MAX_RETRY {
                        self.performRequest(request,retryCount:retryCount + 1,completionHandler: completionHandler)
                        return
                    } else {
                        self.result = .Error(error)
                    }
                    
                } else {
                    let httpResponse = response as! NSHTTPURLResponse
                    if !(200..<300 ~= httpResponse.statusCode)  {
                        if (retryCount < REQUEST_MAX_RETRY){
                            self.performRequest(request,retryCount:retryCount + 1,completionHandler: completionHandler)
                            return
                        } else {
                            self.result = .HTTPStatus(httpResponse.statusCode,data)
                        }
                    } else {
                        self.result = .OK(data)
                    }
                    
                }
                completionHandler()
                
            }
            
            self.task?.resume()
        }
        
    }

	func performDownloadRequest(request:NSURLRequest,retryCount:Int = 0,completionHandler: () -> ())  {

		self.request = request
		synchronized {
			if self.cancelled {
				self.result = .Cancelled
				completionHandler()
				return
			}

			self.task = self.service.serviceSession.downloadTaskWithRequest(request)
			self.task?.resume()
		}
	}


}