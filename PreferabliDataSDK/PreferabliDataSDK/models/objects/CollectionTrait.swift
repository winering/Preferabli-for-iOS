//
//  CollectionTrait.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/12/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

/// A trait descriptor for a collection.
internal class CollectionTrait : BaseObject {
    
    internal var name: String
    internal var order: NSNumber
    internal var restrict_to_ring_it: Bool
    
    internal init(collection_trait : CoreData_CollectionTrait) {
        name = collection_trait.name
        order = collection_trait.order
        restrict_to_ring_it = collection_trait.restrict_to_ring_it
        super.init(id: collection_trait.id)
    }
}
