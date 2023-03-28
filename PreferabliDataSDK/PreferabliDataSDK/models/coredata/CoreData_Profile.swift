//
//  CoreData_Profile.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/27/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

@objc(CoreData_Profile)
internal class CoreData_Profile: NSManagedObject {
    
}

extension CoreData_Profile {
    @NSManaged internal var id: NSNumber
    @NSManaged internal var user_id: NSNumber
    @NSManaged internal var customer_id: NSNumber
    @NSManaged internal var score: NSNumber
    @NSManaged internal var foods: NSSet?
    @NSManaged internal var preference_styles: NSSet
    @NSManaged internal var users: NSSet?
}
