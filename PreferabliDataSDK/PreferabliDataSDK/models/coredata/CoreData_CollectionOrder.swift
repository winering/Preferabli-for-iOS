//
//  CoreData_CollectionOrder.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/9/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

@objc(CoreData_CollectionOrder)
internal class CoreData_CollectionOrder: NSManagedObject {
    
    internal func setTag(in context : NSManagedObjectContext) throws {
        let tagFromDB = CoreData_Tag.mr_findFirst(byAttribute: "id", withValue: tag_id, in: context)
        if (tagFromDB == nil) {
            throw PreferabliException.init(type: .DatabaseError)
        }
        tag = tagFromDB!
    }
}

extension CoreData_CollectionOrder {
    @NSManaged internal var tag_id: NSNumber
    @NSManaged internal var id: NSNumber
    @NSManaged internal var order: NSNumber
    @NSManaged internal var group: CoreData_CollectionGroup
    @NSManaged internal var tag: CoreData_Tag
    @NSManaged internal var dirty: Bool
    @NSManaged internal var group_id: NSNumber
}
