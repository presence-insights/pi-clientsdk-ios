/**
 *  PIOutdoorSDK
 *  PIService.swift
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

public let PIServiceDidStartRequest = "com.ibm.PIService.DidStartRequest"
public let PIServiceDidEndRequest = "com.ibm.PIService.DidEndRequest"

public let PIServiceError = "com.ibm.PI.Error"

public typealias PIResult = HTTPOperationResult

public class PIService: NSObject {
    
    private let httpQueue:NSOperationQueue = NSOperationQueue()
    
    let timeout:NSTimeInterval = 30
    
    public let baseURL:NSURL
    public let org:String
    public let username:String
    public let password:String
    public let tenant:String
    
    public var allowUntrustedCertificates = false
    
    public init(tenant:String, org:String, baseURL:String, username:String, password:String){
        self.baseURL = NSURL(string: baseURL)!
        self.username = username
        self.password = password
        self.org = org
        self.tenant = tenant
        httpQueue.qualityOfService = .Utility
        httpQueue.name = "com.ibm.PI.service-queue"
        httpQueue.maxConcurrentOperationCount = 1
        super.init()
        
    }
    
    
    public func executeRequest(request:Request) -> Response {
        let response = request.execute(self)
        self.httpQueue.addOperation(response.operation)
        return response
    }
    
    public func cancelAll() {
        self.httpQueue.cancelAllOperations()
    }
    
    /// This foreground session shares its cookies with the background session
    lazy var serviceSession:NSURLSession = {
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        configuration.discretionary = false
        configuration.requestCachePolicy = .ReloadIgnoringLocalCacheData
        configuration.HTTPCookieAcceptPolicy = .Always
        configuration.HTTPShouldSetCookies = true
        configuration.HTTPAdditionalHeaders = self.defaultHTTPHeaders()
        configuration.URLCache = nil
        configuration.timeoutIntervalForRequest = self.timeout
        configuration.allowsCellularAccess = true
        
        return NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
    }()
    
    private func defaultHTTPHeaders() -> [String:String] {
        
        let headers = [
            "Accept" : "application/json",
            "Accept-Charset" : "ISO-8859-1,utf-8;q=0.7,*;q=0.3",
            "Accept-Language": "en-US,en;q=0.8",
        ]
        
        return headers
    }
    
    
}

extension PIService : NSURLSessionDelegate {
    
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        // If previous challenge failed, reject the handshake
        if challenge.previousFailureCount > 0 {
            DDLogError("Wrong credentials")
            completionHandler(.RejectProtectionSpace,nil)
            return
        }
        
        if
        challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic ||
        challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodDefault {
        // For Basic Authentication
            
            let credential = NSURLCredential(
                user:self.username,
                password:self.password,
                persistence:.None)
            completionHandler(.UseCredential,credential)
            DDLogInfo("Challenge Basic Authentication")
            return
        }
        
        DDLogError("Cancel Authentication Method \(challenge.protectionSpace.authenticationMethod)")
        completionHandler(.CancelAuthenticationChallenge,nil)
        
    }
    
    
    // https://developer.apple.com/library/mac/documentation/NetworkingInternet/Conceptual/NetworkingTopics/Articles/OverridingSSLChainValidationCorrectly.html
    
    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        if challenge.previousFailureCount > 0 {
            completionHandler(.CancelAuthenticationChallenge,nil)
            DDLogError("Wrong SSL certificate")
            return
        }
        
        // SSL handshake
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            
            guard let trustRef = challenge.protectionSpace.serverTrust else {
                completionHandler(.CancelAuthenticationChallenge,nil)
                return
            }
            
            var result:SecTrustResultType = UInt32(kSecTrustResultInvalid)
            let status = SecTrustEvaluate(trustRef,&result)
            if status == errSecSuccess {
                if Int(result) == kSecTrustResultUnspecified || Int(result) == kSecTrustResultProceed {
                    let newCredential = NSURLCredential(trust: trustRef)
                    completionHandler(.UseCredential,newCredential)
                    return
                }
                #if DEBUG
                    if self.allowUntrustedCertificates &&
                        result == kSecTrustResultRecoverableTrustFailure {
                            let newCredential = NSURLCredential(trust:trustRef)
                            completionHandler(.UseCredential,newCredential)
                            return
                    }
                #endif
                DDLogError("Self Signed SSL certificate rejected")
                challenge.sender?.cancelAuthenticationChallenge(challenge)
            }
            completionHandler(.RejectProtectionSpace,nil)
            return
        }
        
        completionHandler(.PerformDefaultHandling,nil)
    }
    
    
}

