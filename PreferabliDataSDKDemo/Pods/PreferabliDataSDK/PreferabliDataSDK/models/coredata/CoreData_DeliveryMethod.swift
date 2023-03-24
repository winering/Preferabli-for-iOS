//
//  CoreData_DeliveryMethod.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 1/8/20.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CoreData_DeliveryMethod)
internal class CoreData_DeliveryMethod: NSManagedObject {
    
}

extension CoreData_DeliveryMethod {
    @NSManaged internal var id: NSNumber
    @NSManaged internal var shipping_type: String
    @NSManaged internal var state_abbreviation: String?
    @NSManaged internal var state_display_name: String?
    @NSManaged internal var country: String?
    @NSManaged internal var shipping_cost_note: String?
    @NSManaged internal var shipping_speed_note: String?
    @NSManaged internal var venue: CoreData_Venue?
}
