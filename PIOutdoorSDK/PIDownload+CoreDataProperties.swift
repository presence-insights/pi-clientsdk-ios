//
//  PIDownload+CoreDataProperties.swift
//  
//
//  Created by slizeray on 16/02/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension PIDownload {

    @NSManaged var taskId: NSNumber
    @NSManaged var sessionId: String
    @NSManaged var completed: NSNumber

}
