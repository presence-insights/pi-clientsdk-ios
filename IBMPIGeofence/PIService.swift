/**
 *  IBMPIGeofence
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

public let PIServiceError = "com.ibm.pi.Error"

public typealias PIResult = HTTPOperationResult

public protocol PIServiceDelegate:class {
	func didProgress(session: NSURLSession, downloadTask: NSURLSessionDownloadTask,progress:Float)
	func didReceiveFile(session: NSURLSession, downloadTask: NSURLSessionDownloadTask,geofencesURL:NSURL)
	func didCompleteWithError(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?)
}

@objc(IBMPIService)
public final class PIService: NSObject {
    
    private let httpQueue:NSOperationQueue = NSOperationQueue()
    
    let timeout:NSTimeInterval = 60
    
    public let baseURL:NSURL
    public var orgCode:String?
    public let username:String
    public let password:String
    public let tenantCode:String

	public weak var delegate:PIServiceDelegate?

    public var allowUntrustedCertificates = false

	var backgroundURLSessionCompletionHandler:(() -> ())?

	var backgroundPendingSessions:Set<NSURLSession> = []
	
    public init(tenantCode:String, orgCode:String?, baseURL:String, username:String, password:String){
        self.baseURL = NSURL(string: baseURL)!
        self.username = username
        self.password = password
        self.orgCode = orgCode
        self.tenantCode = tenantCode
        httpQueue.qualityOfService = .Utility
        httpQueue.name = "com.ibm.PI.service-queue"
        httpQueue.maxConcurrentOperationCount = 1
        super.init()
        
    }
    
    
    public func executeRequest(request:PIRequest) -> PIResponse {
        let response = request.execute(self)
        self.httpQueue.addOperation(response.operation)
        return response
    }


	public func executeDownload(request:PIDownloadRequest) -> PIDownloadResponse? {
		let response = request.executeDownload(self)
		return response
	}



    public func cancelAll() {
        self.httpQueue.cancelAllOperations()
    }
    
    /// Foreground session
    lazy var serviceSession:NSURLSession = {
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        configuration.discretionary = false
        configuration.requestCachePolicy = .ReloadIgnoringLocalCacheData
        configuration.HTTPCookieAcceptPolicy = .Always
        configuration.HTTPShouldSetCookies = true
        configuration.HTTPAdditionalHeaders = self.defaultHTTPHeaders()
        configuration.URLCache = nil
        configuration.timeoutIntervalForResource = self.timeout
        configuration.allowsCellularAccess = true
        
        return NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
    }()
    
	lazy var backgroundServiceSession:NSURLSession = {

		let identifier = "com.ibm.PI." + NSUUID().UUIDString
		let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(identifier)

		configuration.discretionary = false
		configuration.requestCachePolicy = .ReloadIgnoringLocalCacheData
		configuration.HTTPCookieAcceptPolicy = .Always
		configuration.HTTPShouldSetCookies = true
		configuration.HTTPAdditionalHeaders = self.defaultHTTPHeaders()
		configuration.URLCache = nil
		configuration.allowsCellularAccess = true
		// 1 day max
		configuration.timeoutIntervalForResource = 60 * 60 * 24

		let session =  NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)

		session.sessionDescription = "com.ibm.PI \(NSDate().description)"

		return session

	}()

    private func defaultHTTPHeaders() -> [String:String] {

        let headers = [
            "Accept" : "application/json",
            "Content-Type" : "application/json",
            "Accept-Charset" : "ISO-8859-1,utf-8;q=0.7,*;q=0.3",
            "Accept-Language": "en-US,en;q=0.8",
        ]
        
        return headers
    }
    
    
}

extension PIService : NSURLSessionDelegate {
    
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {

		DDLogVerbose("PIService.didReceiveChallenge for task \(task.taskIdentifier) \(task.taskDescription ?? "")",asynchronous:false)

        // If previous challenge failed, reject the handshake
        if challenge.previousFailureCount > 0 {
            DDLogError("Wrong credentials",asynchronous:false)
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
            DDLogInfo("Challenge Basic Authentication",asynchronous:false)
            return
        }
        
        DDLogError("Cancel Authentication Method \(challenge.protectionSpace.authenticationMethod)",asynchronous:false)
        completionHandler(.CancelAuthenticationChallenge,nil)
        
    }
    
    
    // https://developer.apple.com/library/mac/documentation/NetworkingInternet/Conceptual/NetworkingTopics/Articles/OverridingSSLChainValidationCorrectly.html
    
    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
		DDLogVerbose("PIService.didReceiveChallenge for session description \(session.sessionDescription ?? "No Desc")",asynchronous:false)

        if challenge.previousFailureCount > 0 {
            completionHandler(.CancelAuthenticationChallenge,nil)
			DDLogError("Wrong SSL certificate",asynchronous:false)
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
				DDLogError("Self Signed SSL certificate rejected",asynchronous:false)
                challenge.sender?.cancelAuthenticationChallenge(challenge)
            }
            completionHandler(.RejectProtectionSpace,nil)
            return
        }
        
        completionHandler(.PerformDefaultHandling,nil)
    }
    
	public func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
		DDLogInfo("PIService.URLSessionDidFinishEventsForBackgroundURLSession",asynchronous:false)
		self.backgroundPendingSessions.remove(session)
		dispatch_async(dispatch_get_main_queue()) {
			let completionHandler = self.backgroundURLSessionCompletionHandler
			self.backgroundURLSessionCompletionHandler = nil
			completionHandler?()
		}
	}

	public func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
		DDLogError("PIService.didBecomeInvalidWithError session description \(session.sessionDescription ?? "No session description") , error \(error)",asynchronous:false)
	}
}

extension PIService : NSURLSessionDownloadDelegate {

	public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {

		guard totalBytesExpectedToWrite > 0 else {
			DDLogWarn("NSURLSessionDownloadDelegate.didWriteData totalBytesExpectedToWrite == 0!",asynchronous:false)
			return
		}

		let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
		dispatch_async(dispatch_get_main_queue()) {
			self.delegate?.didProgress(session, downloadTask: downloadTask, progress: progress)
		}

	}

	public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
		DDLogError("PIService.didFinishDownloadingToURL session description \(session.sessionDescription ?? "No session description") , task identifier \(downloadTask.taskIdentifier) , task description \(downloadTask.taskDescription ?? "No task description")",asynchronous:false)
		let libraryURL = PIGeofenceUtils.libraryDirectory
		let geojsonURL = libraryURL.URLByAppendingPathComponent(NSUUID().UUIDString+".json")
		do {
			let _ = try? NSFileManager.defaultManager().removeItemAtURL(geojsonURL)
			try NSFileManager.defaultManager().moveItemAtURL(location, toURL: geojsonURL)
			DDLogInfo("Did Received file \(geojsonURL)",asynchronous:false)

			dispatch_async(dispatch_get_main_queue()) {
				self.delegate?.didReceiveFile(session, downloadTask: downloadTask, geofencesURL: geojsonURL)
			}
		} catch {
			DDLogError("Can't move the background download \(error)",asynchronous:false)
		}

	}

	public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		if let error = error {
			DDLogError("PIService.didCompleteWithError session description \(session.sessionDescription ?? "No session description") , task identifier \(task.taskIdentifier) , task description \(task.taskDescription ?? "No task description") , error \(error)",asynchronous:false)
		}

		dispatch_async(dispatch_get_main_queue()) {
			self.delegate?.didCompleteWithError(session, task: task, didCompleteWithError: error)
		}
	}


}

