//
//  CollectionOrder.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/9/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

/// The link between a ``Tag`` (which in turn references a ``Product``) and a ``Collection``, including its ordering within the Collection.
public class CollectionOrder : BaseObject {
    
    public var tag_id: NSNumber
    public var order: NSNumber
    public var group: CollectionGroup
    public var tag: Tag?
    public var group_id: NSNumber

    internal init(collection_tag_order : CoreData_CollectionOrder, holding_group : CollectionGroup) {
        tag_id = collection_tag_order.tag_id
        order = collection_tag_order.order
        group = holding_group
        tag = Tag.init(tag: collection_tag_order.tag, holding_variant: Variant.init(variant: collection_tag_order.tag.variant, holding_product: Product.init(product: collection_tag_order.tag.variant.product)))
        group_id = collection_tag_order.group_id
        super.init(id: collection_tag_order.id)
    }
}
