//
//  CollectionGroup.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/9/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

/// Products in a Collection are organized into one or more groups.  A CollectionGroup object sits within a ``CollectionVersion``.  Each CollectionGroup has an order representing its display ``order`` within a Collection.  Products that are tagged as belonging to a Collection are ordered within the applicable CollectionGroup with ``orderings``
public class CollectionGroup : BaseObject {
    
    public var name: String
    public var order: NSNumber?
    public var orderings_count: NSNumber
    public var orderings: [CollectionOrder]
    public var version: CollectionVersion
    
    internal init(collection_group : CoreData_CollectionGroup, holding_version : CollectionVersion) {
        name = collection_group.name
        order = collection_group.order
        orderings_count = collection_group.orderings_count
        orderings = Array<CollectionOrder>()
        version = holding_version
        super.init(id: collection_group.id)
        for ordering in collection_group.orderings.allObjects as! [CoreData_CollectionOrder] {
            orderings.append(CollectionOrder.init(collection_tag_order: ordering, holding_group: self))
        }
    }
    
    /// Sort groups by their order.
    /// - Parameter groups: an array of groups to be sorted.
    /// - Returns: a sorted array of groups.
    static public func sortGroups(groups: [CollectionGroup]) -> Array<CollectionGroup> {
        return groups.sorted {
            return $0.order?.compare($1.order ?? NSNumber.init(value: 0)) == ComparisonResult.orderedAscending
        }
    }
}
