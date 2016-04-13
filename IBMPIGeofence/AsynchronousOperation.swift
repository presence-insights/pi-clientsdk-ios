/**
 *  PIOutdoorSDK
 *  AsynchronousOperation.swift
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


public class AsynchronousOperation:NSOperation {
    
    private let lock = NSRecursiveLock()
    
    private var isExecuting:Bool = false
    
    private var isFinished:Bool = false
    
    
    override public func start() {
        if !self.cancelled {
            self.executing = true
            self.finished = false
            self.main()
        } else {
            self.executing = false
            self.finished = true
        }
    }
    
    
    
    /// Use an NSLocking object as a mutex for a critical section of code
    private func synchronized(lockable: NSLocking, criticalSection: () -> ()) {
        lockable.lock()
        criticalSection()
        lockable.unlock()
    }
    
    public func synchronized(criticalSection: () -> ()){
        self.synchronized(self.lock, criticalSection: criticalSection)
    }
    
    override public var asynchronous: Bool {
        return true
    }
    
    override public var executing: Bool {
        get {
            return self.isExecuting
            
        }
        
        set {
            synchronized {
                self.willChangeValueForKey("isExecuting")
                self.isExecuting = newValue
                self.didChangeValueForKey("isExecuting")
            }
        }
    }
    
    override public var finished: Bool {
        get {
            return self.isFinished
        }
        
        set {
            synchronized {
                self.willChangeValueForKey("isFinished")
                self.isFinished = newValue
                self.didChangeValueForKey("isFinished")
            }
            
        }
    }
    
    
}