//
//  CollectionVersion.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/9/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

/// A version of a ``Collection``. Most collections will only have one version.
public class CollectionVersion : BaseObject {
    
    public var name: String
    public var order: NSNumber
    public var collection: Collection
    public var groups: [CollectionGroup]
    
    internal init(collection_version : CoreData_CollectionVersion, holding_collection : Collection) {
        name = collection_version.name
        order = collection_version.order
        collection = holding_collection
        groups = Array<CollectionGroup>()
        super.init(id: collection_version.id)
        for group in collection_version.groups.allObjects as! [CoreData_CollectionGroup] {
            groups.append(CollectionGroup.init(collection_group: group, holding_version: self))
        }
    }
}
