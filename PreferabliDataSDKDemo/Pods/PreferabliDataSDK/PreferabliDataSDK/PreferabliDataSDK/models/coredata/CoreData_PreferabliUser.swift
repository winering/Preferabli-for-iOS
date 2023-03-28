//
//  CoreData_PreferabliUser.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/14/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

@objc(CoreData_PreferabliUser)
internal class CoreData_PreferabliUser: NSManagedObject {
    
}

extension CoreData_PreferabliUser {
    @NSManaged internal var account_level: NSNumber?
    @NSManaged internal var birthyear: NSNumber?
    @NSManaged internal var order: NSNumber
    @NSManaged internal var country: String?
    @NSManaged internal var display_name: String?
    @NSManaged internal var email: String?
    @NSManaged internal var enable_image_rec: Bool
    @NSManaged internal var is_team_ringit: Bool
    @NSManaged internal var isHidden: Bool
    @NSManaged internal var isNotHideable: Bool
    @NSManaged internal var has_where_to_buy: Bool
    @NSManaged internal var fname: String?
    @NSManaged internal var gender: String?
    @NSManaged internal var id: NSNumber
    @NSManaged internal var lname: String?
    @NSManaged internal var location: String?
    @NSManaged internal var password: String?
    @NSManaged internal var claim_code: String?
    @NSManaged internal var subscribed: Bool
    @NSManaged internal var has_merchant_access: Bool
    @NSManaged internal var has_kiosks: Bool
    @NSManaged internal var zip_code: String?
    @NSManaged internal var intercom_hmac: String?
    @NSManaged internal var avatar: CoreData_Media?
    @NSManaged internal var connections: NSSet
    @NSManaged internal var channels: NSSet
    @NSManaged internal var rating_collection_id: NSNumber?
    @NSManaged internal var provided_feedback_at: Date?
    @NSManaged internal var wishlist_collection_id: NSNumber?
    @NSManaged internal var admin: Int32
}
