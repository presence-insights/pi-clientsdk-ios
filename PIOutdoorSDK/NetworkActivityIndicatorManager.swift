/**
 *  PIOutdoorSDK
 *  NetworkActivityIndicator.swift
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

public let NetworkDidStartRequest = "com.ibm.PI.NetworkDidStartRequest"
public let NetworkDidEndRequest = "com.ibm.PI.NetworkDidEndRequest"

public class NetworkActivityIndicatorManager: NSObject {
    
    public static let sharedInstance:NetworkActivityIndicatorManager = NetworkActivityIndicatorManager()
    
    private var requestCount:Int = 0
    
    private let lock = NSRecursiveLock()
    
    /// Use an NSLocking object as a mutex for a critical section of code
    private func synchronized(lockable: NSLocking, criticalSection: () -> ()) {
        lockable.lock()
        criticalSection()
        lockable.unlock()
    }
    
    func synchronized(criticalSection: () -> ()){
        self.synchronized(self.lock, criticalSection: criticalSection)
    }
    
    public var enabled:Bool = false
    
    public func enableActivityIndicator(enable:Bool) {
        if enable {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "didStartRequest:", name: NetworkDidStartRequest, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "didEndRequest:", name: NetworkDidEndRequest, object: nil)
        } else {
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }
        enabled = enable
    }
    
    func didStartRequest(notification:NSNotification) {
        synchronized {
            self.requestCount += 1
            print("didStartRequest",self.requestCount)
            self.refreshNetworkActivityIndicator()
        }
        
    }
    
    func didEndRequest(notification:NSNotification) {
        synchronized {
            self.requestCount -= 1
            print("didEndRequest",self.requestCount)
            self.refreshNetworkActivityIndicator()
        }
        
    }
    
    private func refreshNetworkActivityIndicator() {
        
        if !NSThread.isMainThread() {
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                if UIApplication.sharedApplication().applicationState == .Active {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = (self.requestCount > 0)
                }
            }
        } else {
            if UIApplication.sharedApplication().applicationState == .Active {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = (self.requestCount > 0)
            }
        }
        
        
    }
    
}
