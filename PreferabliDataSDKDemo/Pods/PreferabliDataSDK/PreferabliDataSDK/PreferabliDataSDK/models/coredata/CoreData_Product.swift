//
//  CoreData_Product.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/14/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(CoreData_Product)
internal class CoreData_Product: NSManagedObject {
    
    public func getVariantWithId(id : NSNumber) -> CoreData_Variant? {
        for variant in variants.allObjects as! [CoreData_Variant] {
            if (variant.id == id) {
                return variant
            }
        }
        
        return nil
    }
}

extension CoreData_Product {
    @NSManaged internal var brand: String
    @NSManaged internal var created_at: Date?
    @NSManaged internal var decant: Bool
    @NSManaged internal var grape: String
    @NSManaged internal var id: NSNumber
    @NSManaged internal var brand_lat: NSNumber?
    @NSManaged internal var brand_lon: NSNumber?
    @NSManaged internal var dirty: Bool
    @NSManaged internal var show_year_dropdown: Bool
    @NSManaged internal var name: String
    @NSManaged internal var region: String
    @NSManaged internal var type: String
    @NSManaged internal var category: String
    @NSManaged internal var subcategory: String
    @NSManaged internal var rateSourceLocation: String
    @NSManaged internal var updated_at: Date?
    @NSManaged internal var primary_image: CoreData_Media?
    @NSManaged internal var variants: NSSet
    @NSManaged internal var temp_image_id: NSNumber?
    @NSManaged internal var front_image: Data?
    @NSManaged internal var back_image: Data?
    @NSManaged internal var brand_id: NSNumber?
    @NSManaged internal var producthash: String?
}
