//
//  Style.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/6/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

/// Styles express how product characteristics synthesize in the context of human perception and define the nature of consumer taste preferences. These are *not* unique for each customer, which are represented as ``ProfileStyle``.
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
    
    /// Get the style image.
    /// - Parameters:
    ///   - width: returns an image with the specified width in pixels.
    ///   - height: returns an image with the specified height in pixels.
    ///   - quality: returns an image with the specified quality. Scales from 0 - 100.
    /// - Returns: the URL of the requested image.
    public func getImage(width : CGFloat, height : CGFloat, quality : Int = 80) -> URL? {
        return PreferabliTools.getImageUrl(image: primary_image_url, width: width, height: height, quality: quality)
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
