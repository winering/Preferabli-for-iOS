//
//  Style.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/6/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

/// Styles express how product characteristics synthesize in the context of human perception and define the nature of consumer taste preferences. These are *not* unique for each customer.
public class Style : BaseObject {
    
    public var desc: String
    public var name: String
    public var order: NSNumber
    public var type: String
    public var primary_image_url: String?
    public var product_category: String
    public var locations: [Location]
    
    internal init(style : CoreData_Style) {
        desc = style.desc
        name = style.name
        order = style.order
        type = style.type
        primary_image_url = style.primary_image_url
        product_category = style.product_category
        locations = Array<Location>()
        super.init(id: style.id)
        for location in style.locations.allObjects as! [CoreData_Location] {
            locations.append(Location.init(location: location))
        }
    }
    
    /// Get the path of the style's primary image.
    /// - Returns: a string path.
    public func getImage() -> String {
        return primary_image_url ?? ""
    }
    
    /// Get product type.
    /// - Returns: ``ProductType`` of the style.
    public func getProductType() -> ProductType {
         return ProductType.getProductTypeFromString(value: type)
    }
    
    /// Get product category.
    /// - Returns: ``ProductCategory`` of the style.
    public func getProductCategory() -> ProductCategory {
       return ProductCategory.getProductCategoryFromString(value: product_category);
   }
    
}
