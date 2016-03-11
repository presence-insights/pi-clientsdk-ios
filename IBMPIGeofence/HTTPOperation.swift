/**
 *  PIOutdoorSDK
 *  HTTPOperation.swift
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


let REQUEST_MAX_RETRY = 3

public class HTTPOperation: AsynchronousOperation {
    
    private var didStart = false
    
    private var task:NSURLSessionTask?
    
    public let session:NSURLSession
    
    public let url:NSURL
    
    public let timeout:NSTimeInterval
    
    public var result:HTTPOperationResult?
    
    public let maxRetry:Int
    
    public init(session:NSURLSession,url:NSURL,timeout:NSTimeInterval = 60,maxRetry:Int = REQUEST_MAX_RETRY){
        self.session = session
        self.url = url
        self.timeout = timeout
        self.maxRetry = maxRetry
    }
    
    
    override public var executing: Bool {
        
        didSet {
            if executing {
                self.didStart = true
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotificationName(kIBMPINetworkDidStartRequest, object: self)
                }
            }
        }
    }
    
    override public var finished: Bool {
        willSet {
            if newValue && self.didStart {
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotificationName(kIBMPINetworkDidEndRequest, object: self)
                }
            }
            
        }
    }
    
    public override func cancel() {
        synchronized {
            self.task?.cancel()
            super.cancel()
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
    
    override public func main() {
        let urlRequest = NSURLRequest(URL:self.url,cachePolicy:.UseProtocolCachePolicy,timeoutInterval:self.timeout)
        
        self.performRequest(urlRequest) {
            [unowned self] result in
            self.result = result
            self.executing = false
            self.finished = true
        }
        
        
    }
    
    
}

extension HTTPOperation {
    public func performRequest(request:NSURLRequest,retryCount:Int = 0,completionHandler: (result:HTTPOperationResult) -> Void)  {
        
        synchronized {
            if self.cancelled {
                completionHandler(result:.Cancelled)
				return
            }
            
            self.task = self.session.dataTaskWithRequest(request)  {
                [unowned self] (data, response, error) -> Void in
                if let error = error {
                    if self.isTaskCancelled(error) {
                        completionHandler(result:.Cancelled)
                    } else if retryCount < self.maxRetry {
                        self.performRequest(request,retryCount:retryCount + 1,completionHandler: completionHandler)
                    } else {
                        completionHandler(result: .Error(error))
                    }
                    
                } else {
                    let httpResponse = response as! NSHTTPURLResponse
                    if !(200..<300 ~= httpResponse.statusCode)  {
                        if (retryCount < self.maxRetry){
                            self.performRequest(request,retryCount:retryCount + 1,completionHandler: completionHandler)
                            return
                        } else {
                            completionHandler(result: .HTTPStatus(httpResponse.statusCode,data))
                        }
                    } else {
                        completionHandler(result: .OK(data))
                    }
                    
                }
                
            }
            
            self.task?.resume()
        }
        
    }
    
}