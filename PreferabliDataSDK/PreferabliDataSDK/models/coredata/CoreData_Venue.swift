//
//  CoreData_Venue.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/14/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

@objc(CoreData_Venue)
internal class CoreData_Venue: NSManagedObject {
    
}

extension CoreData_Venue {
    @NSManaged internal var address_l1: String?
    @NSManaged internal var address_l2: String?
    @NSManaged internal var city: String?
    @NSManaged internal var country: String?
    @NSManaged internal var display_name: String
    @NSManaged internal var id: NSNumber
    @NSManaged internal var lat: NSNumber?
    @NSManaged internal var lon: NSNumber?
    @NSManaged internal var primary_inventory_id: NSNumber?
    @NSManaged internal var featured_collection_id: NSNumber?
    @NSManaged internal var is_virtual: Bool
    @NSManaged internal var name: String?
    @NSManaged internal var phone: String?
    @NSManaged internal var email_address: String?
    @NSManaged internal var state: String?
    @NSManaged internal var url: String?
    @NSManaged internal var url_facebook: String?
    @NSManaged internal var url_instagram: String?
    @NSManaged internal var url_twitter: String?
    @NSManaged internal var url_youtube: String?
    @NSManaged internal var zip_code: String?
    @NSManaged internal var notes: String?
    @NSManaged internal var collections: NSSet?
    @NSManaged internal var channels: NSSet?
    @NSManaged internal var active_delivery_methods: NSSet?
    @NSManaged internal var channel_venues: NSSet?
    @NSManaged internal var images: NSSet?
    @NSManaged internal var hours: NSSet?
}
