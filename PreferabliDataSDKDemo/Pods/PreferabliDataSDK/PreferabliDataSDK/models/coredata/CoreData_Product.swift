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
    
    public func getMostRecentVariant() -> CoreData_Variant {
        return mostRecentVariant!
    }
    
    var mostRecentVariant: CoreData_Variant? {
        var mostRecentYear = NSNumber(integerLiteral: -2)
        var mostRecentVariant : CoreData_Variant?
        for vintage in variants.allObjects as! [CoreData_Variant] {
            if (vintage.year.intValue  > mostRecentYear.intValue && vintage.id.intValue > 0) {
                mostRecentYear = vintage.year
                mostRecentVariant = vintage
            }
        }
        
        return mostRecentVariant!
    }
    
    public func getVariantWithId(id : NSNumber) -> CoreData_Variant? {
        for vintage in variants.allObjects as! [CoreData_Variant] {
            if (vintage.id == id) {
                return vintage
            }
        }
        
        return nil
    }
    
    static internal func sortProducts(sortedIds : Array<NSManagedObjectID>, products: [CoreData_Product]) -> Array<CoreData_Product> {
        return products.sorted {
            let first = sortedIds.firstIndex(of: $0.objectID)!
            let second = sortedIds.firstIndex(of: $1.objectID)!
            return first < second
        }
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
