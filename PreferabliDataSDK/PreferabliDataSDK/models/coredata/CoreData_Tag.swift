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
    static internal func sortTags(sortedIds : Array<NSManagedObjectID>, tags: [CoreData_Tag]) -> Array<CoreData_Tag> {
        return tags.sorted {
            let first = sortedIds.firstIndex(of: $0.objectID)!
            let second = sortedIds.firstIndex(of: $1.objectID)!
            return first < second
        }
    }
    
    internal func isRating() -> Bool {
        if (PreferabliTools.getKeyStore().bool(forKey: "MerchantWineRingApp")) {
            return type == "rating"
        }
        return type == "rating" && collection_id.intValue == PreferabliTools.getKeyStore().integer(forKey: "ratings_id")
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
