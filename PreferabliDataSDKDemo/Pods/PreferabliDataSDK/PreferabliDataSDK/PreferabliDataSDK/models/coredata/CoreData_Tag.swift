//
//  CoreData_Tag.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/14/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(CoreData_Tag)
internal class CoreData_Tag: NSManagedObject {
    internal func isRating() -> Bool {
        return type == "rating"
    }
}


extension CoreData_Tag {
    @NSManaged internal var collection_id: NSNumber
    @NSManaged internal var comment: String?
    @NSManaged internal var created_at: Date
    @NSManaged internal var id: NSNumber
    @NSManaged internal var location: String?
    @NSManaged internal var badge: String?
    @NSManaged internal var tagged_in_collection_id: NSNumber?
    @NSManaged internal var tagged_in_channel_id: NSNumber?
    @NSManaged internal var tagged_in_channel_name: String?
    @NSManaged internal var type: String
    @NSManaged internal var updated_at: Date
    @NSManaged internal var user_id: NSNumber
    @NSManaged internal var value: String?
    @NSManaged internal var bin: String?
    @NSManaged internal var variant_id: NSNumber
    @NSManaged internal var product_id: NSNumber
    @NSManaged internal var quantity: NSNumber?
    @NSManaged internal var format_ml: NSNumber?
    @NSManaged internal var price: NSNumber?
    @NSManaged internal var sharing: NSSet?
    @NSManaged internal var variant: CoreData_Variant
    @NSManaged internal var dirty: Bool
    @NSManaged internal var orderings: NSSet?
    @NSManaged internal var customer_id: NSNumber
    @NSManaged internal var temp_image_id: NSNumber?
}
