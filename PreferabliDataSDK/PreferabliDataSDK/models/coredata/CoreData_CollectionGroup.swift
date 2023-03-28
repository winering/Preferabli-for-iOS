//
//  CoreData_CollectionGroup.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/9/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

@objc(CoreData_CollectionGroup)
internal class CoreData_CollectionGroup: NSManagedObject {
    
    static internal func sortGroups(groups: [CoreData_CollectionGroup]) -> Array<CoreData_CollectionGroup> {
        return groups.sorted {
            return $0.order?.compare($1.order ?? NSNumber.init(value: 0)) == ComparisonResult.orderedAscending
        }
    }
    
}

extension CoreData_CollectionGroup {
    @NSManaged internal var display_name: Bool
    @NSManaged internal var id: NSNumber
    @NSManaged internal var name: String
    @NSManaged internal var order: NSNumber?
    @NSManaged internal var orderings_count: NSNumber
    @NSManaged internal var orderings: NSSet
    @NSManaged internal var version: CoreData_CollectionVersion
}
