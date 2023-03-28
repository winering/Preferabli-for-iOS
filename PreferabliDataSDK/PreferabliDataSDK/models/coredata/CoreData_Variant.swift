//
//  CoreData_Variant.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/14/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(CoreData_Variant)
internal class CoreData_Variant: NSManagedObject {
    
}

extension CoreData_Variant {
    @NSManaged internal var created_at: Date?
    @NSManaged internal var fresh: Bool
    @NSManaged internal var id: NSNumber
    @NSManaged internal var num_dollar_signs: NSNumber
    @NSManaged internal var price: Double
    @NSManaged internal var recommendable: Bool
    @NSManaged internal var updated_at: Date?
    @NSManaged internal var year: NSNumber
    @NSManaged internal var primary_image: CoreData_Media?
    @NSManaged internal var product: CoreData_Product
    @NSManaged internal var tags: NSSet
    @NSManaged internal var collectionVintageOrders: NSSet
}
