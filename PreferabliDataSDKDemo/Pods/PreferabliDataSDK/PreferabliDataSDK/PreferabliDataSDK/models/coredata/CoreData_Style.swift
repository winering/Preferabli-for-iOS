//
//  CoreData_Style.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/6/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

@objc(CoreData_Style)
internal class CoreData_Style: NSManagedObject {
    
}

extension CoreData_Style {
    @NSManaged internal var desc: String
    @NSManaged internal var id: NSNumber
    @NSManaged internal var name: String
    @NSManaged internal var order: NSNumber
    @NSManaged internal var type: String
    @NSManaged internal var primary_image_url: String?
    @NSManaged internal var product_category: String
    @NSManaged internal var foods: NSSet
    @NSManaged internal var preference_style: NSSet?
    @NSManaged internal var locations: NSSet
}
