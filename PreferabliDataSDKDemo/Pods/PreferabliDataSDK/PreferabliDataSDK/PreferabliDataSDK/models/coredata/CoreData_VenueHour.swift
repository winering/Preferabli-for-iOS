//
//  CoreData_VenueHour.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/18/21.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CoreData_VenueHour)
internal class CoreData_VenueHour: NSManagedObject {
    
}

extension CoreData_VenueHour {
    @NSManaged internal var id: NSNumber
    @NSManaged internal var weekday: String?
    @NSManaged internal var open_time: String?
    @NSManaged internal var close_time: String?
    @NSManaged internal var is_closed: Bool
    @NSManaged internal var created_at: Date
    @NSManaged internal var updated_at: Date
    @NSManaged internal var venue: CoreData_Venue?
    
}
