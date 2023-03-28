//
//  CoreData_Collection.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/14/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(CoreData_Collection)
internal class CoreData_Collection: NSManagedObject {
    internal func getFirstVersion(context : NSManagedObjectContext) -> CoreData_CollectionVersion {
       if (versions.count > 0) {
           return versions.allObjects[0] as! CoreData_CollectionVersion
       }
       
       return CoreData_CollectionVersion.mr_createEntity(in: context)!
   }
}

extension CoreData_Collection {
    @NSManaged internal var channel_id: NSNumber?
    @NSManaged internal var sort_channel_id: NSNumber
    @NSManaged internal var code: String?
    @NSManaged internal var desc: String?
    @NSManaged internal var end_date: Date?
    @NSManaged internal var updated_at: Date
    @NSManaged internal var auto_wili: Bool
    @NSManaged internal var has_image: Bool
    @NSManaged internal var is_pinned: Bool
    @NSManaged internal var display_time: Bool
    @NSManaged internal var is_browsable: Bool
    @NSManaged internal var is_my_cellar: Bool
    @NSManaged internal var lbs_order: NSNumber
    @NSManaged internal var product_count: NSNumber
    @NSManaged internal var id: NSNumber
    @NSManaged internal var name: String
    @NSManaged internal var badge_method: String
    @NSManaged internal var currency: String
    @NSManaged internal var timezone: String
    @NSManaged internal var `public`: Bool
    @NSManaged internal var published: Bool
    @NSManaged internal var archived: Bool
    @NSManaged internal var display_price: Bool
    @NSManaged internal var display_quantity: Bool
    @NSManaged internal var display_bin: Bool
    @NSManaged internal var has_predict_order: Bool
    @NSManaged internal var is_randomized: Bool
    @NSManaged internal var display_group_headings: Bool
    @NSManaged internal var is_blind: Bool
    @NSManaged internal var start_date: Date?
    @NSManaged internal var venue_id: NSNumber?
    @NSManaged internal var primary_image: CoreData_Media?
    @NSManaged internal var venue: CoreData_Venue?
    @NSManaged internal var versions: NSSet
    @NSManaged internal var sort_channel_name: String
    @NSManaged internal var traits: NSSet
    @NSManaged internal var order: NSNumber
    @NSManaged internal var location_based_recs: Bool
    @NSManaged internal var user_collections: NSSet
}
