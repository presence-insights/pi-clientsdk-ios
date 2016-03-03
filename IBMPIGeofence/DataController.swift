/**
 *  PIOutdoorSDK
 *  DataController.swift
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
import CoreData



public class DataController:NSObject {
    
    private let lock = NSRecursiveLock()
    
    public let groupIdentifier:String?
    
    private var _mainContext:NSManagedObjectContext!
    
    public let fileName:String
    
    public init(groupIdentifier:String? = nil, fileName:String = "Data"){
        self.groupIdentifier = groupIdentifier
        self.fileName = fileName
    }
    
    /// Use an NSLocking object as a mutex for a critical section of code
    private func synchronized(lockable: NSLocking, criticalSection: () -> ()) {
        lockable.lock()
        criticalSection()
        lockable.unlock()
    }
    
    func synchronized(criticalSection: () -> ()){
        self.synchronized(self.lock, criticalSection: criticalSection)
    }
    
    // Main context for the UI
    public var mainContext:NSManagedObjectContext  {
        
        synchronized {
            if self._mainContext == nil {
                let coordinator = self.mainUIPersistentStoreCoordinator
                
                self._mainContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
                self._mainContext.persistentStoreCoordinator = coordinator
                self._mainContext.undoManager = nil
            }
        }
        return self._mainContext
    }
    
    private var _writerContext:NSManagedObjectContext!
    // Writer context
    public var writerContext:NSManagedObjectContext  {
        
        synchronized {
            if self._writerContext == nil {
                let coordinator = self.writerPersistentStoreCoordinator
                
                self._writerContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
                self._writerContext.persistentStoreCoordinator = coordinator
                self._writerContext.undoManager = nil
                
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DataController.contextChanged(_:)), name: NSManagedObjectContextDidSaveNotification, object: self._writerContext)
            }
        }
        
        return self._writerContext
    }
    
    
    private lazy var mom:NSManagedObjectModel = {
        
        let bundle = NSBundle(forClass: self.dynamicType)
        
        return NSManagedObjectModel.mergedModelFromBundles([bundle])!
        
    } ()
    
    private var _mainUIPersistentStoreCoordinator:NSPersistentStoreCoordinator!
    
    public var mainUIPersistentStoreCoordinator:NSPersistentStoreCoordinator {
        
        synchronized {
            if self._mainUIPersistentStoreCoordinator == nil {
                self._mainUIPersistentStoreCoordinator = self.createPersistentStoreCoordinator()
            }
        }
        
        return self._mainUIPersistentStoreCoordinator
        
    }
    
    private var _writerPersistentStoreCoordinator:NSPersistentStoreCoordinator!
    
    public var writerPersistentStoreCoordinator:NSPersistentStoreCoordinator {
        
        synchronized {
            if self._writerPersistentStoreCoordinator == nil {
                self._writerPersistentStoreCoordinator = self.createPersistentStoreCoordinator()
            }
        }
        
        return self._writerPersistentStoreCoordinator
        
    }
    
    private func createPersistentStoreCoordinator() -> NSPersistentStoreCoordinator {
        
        let dir = NSString(string:applicationLibraryDirectory.path!).stringByAppendingPathComponent("sql")
        
        let fileManager = NSFileManager.defaultManager()
        
        let exists = fileManager.fileExistsAtPath(dir)
        
        if !exists {
            do {
                try fileManager.createDirectoryAtPath(dir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fatalError("Can't create directory \(error)")
            }
            self.dynamicType.addSkipBackupAttributeToItemAtPath(dir)
        }
        
        let storePath = NSString(string:applicationLibraryDirectory.path!).stringByAppendingPathComponent("sql/\(self.fileName).sqlite")
        
        let storeUrl = NSURL(fileURLWithPath: storePath)
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: self.mom)
        
        do {
			try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeUrl, options: [NSPersistentStoreFileProtectionKey:NSFileProtectionNone])
        } catch {
            fatalError("Can't create Persistent Store Coordinator \(error)")
        }
        
        
        return psc
        
    }
    
    public func removeStore() throws {
        let dir = NSString(string:applicationLibraryDirectory.path!).stringByAppendingPathComponent("sql")
        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(dir) {
            try fileManager.removeItemAtPath(dir)
        }
        
        synchronized {
            self._mainContext = nil
            self._mainUIPersistentStoreCoordinator = nil
            self._writerContext = nil
            self._writerPersistentStoreCoordinator = nil
        }
        
    }
    
    public var isStorePresent:Bool {
        let dir = NSString(string:applicationLibraryDirectory.path!).stringByAppendingPathComponent("sql/\(self.fileName).sqlite")
        let fileManager = NSFileManager.defaultManager()
        return fileManager.fileExistsAtPath(dir)
    }
    
    
    func contextChanged(notification:NSNotification) {
        // If we get change from an other thread, we merge the changes
        dispatch_async(dispatch_get_main_queue()){
            if notification.object as! NSManagedObjectContext != self.mainContext {
                self.mainContext.mergeChangesFromContextDidSaveNotification(notification)
                
            }
        }
    }
    
    
}

extension DataController {
    // Returns the URL to the application's Library directory.
    private var applicationLibraryDirectory: NSURL {
        
        if let groupIdentifier = self.groupIdentifier {
            return NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(groupIdentifier)!
            
        } else {
            return NSFileManager.defaultManager().URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask).first! as NSURL
        }
        
    }
    
    private static func addSkipBackupAttributeToItemAtPath(path:String) {
        
        
        let url = NSURL.fileURLWithPath(path)
        do {
            try url.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
        } catch {
            fatalError("Can't set resource value \(error)")
        }
        
    }
    
}

extension DataController {
    
    public func managedObjectWithURI(uri:NSURL) -> NSManagedObject {
        
        guard let objectID = self.mainUIPersistentStoreCoordinator.managedObjectIDForURIRepresentation(uri) else {
            fatalError("objectID is nil")
        }
        
        do {
            let managedObject = try self.mainContext.existingObjectWithID(objectID)
            return managedObject
        } catch  {
            fatalError("objectID not found \(error)")
        }
        
    }
    
    public func managedObjectWithURIOrNil(uri:NSURL) -> NSManagedObject? {
        
        guard let objectID = self.mainUIPersistentStoreCoordinator.managedObjectIDForURIRepresentation(uri) else {
            fatalError("objectID is nil")
        }
        
        do {
            let managedObject = try self.mainContext.existingObjectWithID(objectID)
            return managedObject
        } catch  {
            return nil
        }
        
    }
    
    
    public func managedObjectWritersWithURI(uri:NSURL) -> NSManagedObject {
        
        guard let objectID = self.writerPersistentStoreCoordinator.managedObjectIDForURIRepresentation(uri) else {
            fatalError("objectID is nil")
        }
        
        do {
            let managedObject = try self.writerContext.existingObjectWithID(objectID)
            return managedObject
        } catch  {
            fatalError("objectID not found \(error)")
        }
    }
    
    
}

