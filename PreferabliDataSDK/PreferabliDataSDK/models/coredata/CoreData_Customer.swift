//
//  CoreData_Customer.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/14/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(CoreData_Customer)
internal class CoreData_Customer: NSManagedObject {
    
}

extension CoreData_Customer {
    @NSManaged public var id: NSNumber
    @NSManaged public var avatar_url: String?
    @NSManaged public var merchant_user_email_address: String?
    @NSManaged public var merchant_user_id: String?
    @NSManaged public var merchant_user_name: String?
    @NSManaged public var merchant_user_display_name: String?
    @NSManaged public var role: String?
    @NSManaged public var user_id: NSNumber
    @NSManaged public var has_profile: Bool
    @NSManaged public var claim_code: String?
    @NSManaged public var ratings_collection_id: NSNumber
}
