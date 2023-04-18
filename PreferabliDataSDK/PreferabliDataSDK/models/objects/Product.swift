//
//  Product.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/14/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData
import UIKit

/// Represents a product within the Preferabli SDK. A product may have one or more ``Variant`` stored in ``variants``. To see how this product is mapped to your own object(s), see ``Variant/merchant_links``. To see a user's interaction with the product, see ``Variant/tags``.
public class Product : BaseObject {
    
    public var brand: String
    public var created_at: Date?
    public var decant: Bool
    public var grape: String
    public var brand_lat: NSNumber?
    public var brand_lon: NSNumber?
    public var show_year_dropdown: Bool
    public var name: String
    public var region: String
    public var type: String
    public var category: String
    public var subcategory: String
    public var updated_at: Date?
    public var primary_image: Media?
    public var variants: [Variant]
    public var brand_id: NSNumber?
    
    internal var producthash: String?
    
    internal init(product : CoreData_Product) {
        brand = product.brand
        created_at = product.created_at
        decant = product.decant
        grape = product.grape
        brand_lat = product.brand_lat
        brand_lon = product.brand_lon
        show_year_dropdown = product.show_year_dropdown
        name = product.name
        region = product.region
        type = product.type
        category = product.category
        subcategory = product.subcategory
        updated_at = product.updated_at
        if (product.primary_image != nil) {
            primary_image = Media.init(media: product.primary_image!)
        }
        variants = Array<Variant>()
        brand_id = product.brand_id
        producthash = product.producthash
        super.init(id: product.id)
        for variant in product.variants.allObjects as! [CoreData_Variant] {
            variants.append(Variant.init(variant: variant, holding_product: self))
        }
    }
    
    /// The ``RatingType`` of the most recent rating within this product for the current user.
    var rating_type : RatingType {
        if let mostRecentRating = most_recent_rating {
            return RatingType.getRatingTypeBasedOffTagValue(value: mostRecentRating.value)
        }
        
        return RatingType.NONE
    }
    
    /// The first instance within the product of tag type ``TagType/WISHLIST`` for the current user.
    var wishlist_tag : Tag? {
        for variant in variants {
            for tag in variant.tags {
                if (tag.tag_type == .WISHLIST) {
                    return tag
                }
            }
        }
        
        return nil
    }
    
    /// All the product's tags of type ``TagType/PURCHASE`` for the current user.
    var purchase_tags: Set<Tag> {
        var purchaseTags = Set<Tag>()
        for variant in variants {
            for tag in variant.tags {
                if (tag.tag_type == .PURCHASE) {
                    purchaseTags.insert(tag)
                }
            }
        }
        
        return purchaseTags
    }
    
    /// All the product's tags of type ``TagType/CELLAR`` for the current user.
    var cellar_tags: Set<Tag> {
        let cellarIds = (CoreData_UserCollection.mr_find(byAttribute: "relationship_type", withValue: "mycellar") as! [CoreData_UserCollection]).map() { $0.collection_id }
        var cellarTags = Set<Tag>()
        for variant in variants {
            for tag in variant.tags {
                if (tag.tag_type == .CELLAR && cellarIds.contains(tag.collection_id)) {
                    cellarTags.insert(tag)
                }
            }
        }
        
        return cellarTags
    }
    
    /// The user's most recent tag of type ``TagType/PURCHASE`` within this product for the current user.
    var most_recent_purchase: Tag? {
        var date = Date.init(timeIntervalSince1970: 0)
        var mostRecentPurchase : Tag?
        for tag in purchase_tags {
            let compareToDate = tag.created_at
            if (date < compareToDate) {
                date = compareToDate
                mostRecentPurchase = tag
            }
        }
        return mostRecentPurchase
    }
    
    /// Lets us know if the current user has purchased this product.
    /// - Returns: true if it was purchased.
    public func wasPurchased() -> Bool {
        return purchase_tags.count != 0
    }
    
    /// Lets us know if the current user has wishlisted this product.
    /// - Returns: true if it was wishlisted.
    public func isOnWishlist() -> Bool {
        return wishlist_tag != nil
    }
    
    /// Lets us know if the current user has this product in their cellar.
    /// - Returns: true if the product is in the user's cellar.
    public func isInCellar() -> Bool {
        return cellar_tags.count != 0
    }
    
    /// All the product's tags of type ``TagType/RATING`` for the current user.
    var ratings_tags: Set<Tag> {
        var ratingsTags = Set<Tag>()
        for variant in variants {
            for tag in variant.ratings_tags {
                ratingsTags.insert(tag)
            }
        }
        return ratingsTags
    }
    
    /// The most recent tag of type ``TagType/RATING`` for the current user.
    var most_recent_rating: Tag? {
        var date = Date.init(timeIntervalSince1970: 0)
        var mostRecentRating : Tag?
        for tag in ratings_tags {
            let compareToDate = tag.created_at
            if (date < compareToDate) {
                date = compareToDate
                mostRecentRating = tag
            }
        }
        return mostRecentRating
    }
    
    /// Lets us know if the product is still being curated.
    /// - Returns: true if the product has not been curated.
    public func isBeingIdentified() -> Bool {
        return brand.lowercased().containsIgnoreCase("identified")
    }
    
    /// Get the product image.
    /// - Parameters:
    ///   - width: returns an image with the specified width in pixels.
    ///   - height: returns an image with the specified height in pixels.
    ///   - quality: returns an image with the specified quality. Scales from 0 - 100.
    /// - Returns: the URL of the requested image.
    public func getImage(width : CGFloat, height : CGFloat, quality : Int = 80) -> URL? {
        if (primary_image == nil || PreferabliTools.isNullOrWhitespace(string: primary_image!.path) || primary_image!.path.contains("placeholder")) {
            for variant in variants {
                if (variant.primary_image == nil || PreferabliTools.isNullOrWhitespace(string: variant.primary_image!.path) || variant.primary_image!.path.contains("placeholder")) {
                    continue
                }
                return variant.getImage(width: width, height: height, quality: quality)
            }
        }
        return PreferabliTools.getImageUrl(image: primary_image?.path, width: width, height: height, quality: quality)
    }
    
    /// The type of a product. Only for wines.
    var product_type: ProductType {
        return ProductType.getProductTypeFromString(value: type)
    }
    
    /// The category of a product.
    var product_category: ProductCategory {
        return ProductCategory.getProductCategoryFromString(value: category)
        
    }
    
    /// Gets the Preferabli price of the most recent ``Variant``.
    /// - Returns: Preferabli price represented by dollar signs in a string.
    ///
    /// Prices represent Retail | Restaurant
    /// - $ = Less than $12 | < $30
    /// - $$ = $12 to $19.99 | $30 - $45
    /// - $$$ = $20 to $49.99 | $45 - $110
    /// - $$$$ = $50 to $74.99 | $110 - $160
    /// - $$$$$ = $75 and up | > $160
    public func getPrice() -> String {
        return Product.getPrice(num_dollar_signs: most_recent_variant.num_dollar_signs)
    }
    
    static internal func getPrice(num_dollar_signs : NSNumber) -> String {
        var dollarSigns = ""
        for _ in (0..<num_dollar_signs.intValue){
            dollarSigns = dollarSigns + "$"
        }
        return dollarSigns
    }
    
    /// The most recent ``Variant``.
    var most_recent_variant: Variant {
        var mostRecentYear = NSNumber(integerLiteral: -2)
        var mostRecentVariant : Variant?
        for variant in variants {
            if (variant.year.intValue  > mostRecentYear.intValue && variant.id.intValue > 0) {
                mostRecentYear = variant.year
                mostRecentVariant = variant
            }
        }
        
        if (mostRecentVariant == nil) {
            // We should always have a variant. Create one if it doesn't exist.
            mostRecentVariant = Variant.init(year: Variant.CURRENT_VARIANT_YEAR, product: self)
            variants.append(mostRecentVariant!)
        }
        
        return mostRecentVariant!
    }
    
    /// Gets a ``Variant`` by its id.
    /// - Parameter id: a variant id.
    /// - Returns: the corresponding variant. Returns *nil* if this product does not contain the variant.
    public func getVariantWithId(id : NSNumber) -> Variant? {
        for variant in variants {
            if (variant.id == id) {
                return variant
            }
        }
        
        return nil
    }
    
    /// Get a ``Variant`` by its year.
    /// - Parameter year: a variant year.
    /// - Returns: the corresponding variant. Returns *nil* if this product does not contain the variant.
    public func getVariantWithYear(year : NSNumber) -> Variant? {
        for variant in variants {
            if (variant.year == year) {
                return variant
            }
        }
        
        return nil
    }
    
    /// Filters products by a user's search.
    /// - Parameters:
    ///   - products: an array of products to be filtered.
    ///   - search_text: user's search query.
    /// - Returns: an array of filtered products.
    static public func filterProducts(products : Array<Product>, search_text : String) -> Array<Product> {
        var filteredWines = Array<Product>()
        if (search_text.isEmptyOrWhitespace()) {
            filteredWines = products
        } else {
            let searchTerms = search_text.components(separatedBy: " ")
            filteredWines = products.filter() {
                for searchTerm in searchTerms {
                    if ($0.filterProduct(search_term: searchTerm)) {
                        continue
                    } else {
                        return false
                    }
                }
                return true
            }
        }
        
        return filteredWines
    }
    
    internal func filterProduct(search_term : String) -> Bool {
        if (search_term.isEmptyOrWhitespace()) {
            return true
        } else if (name.containsIgnoreCase(search_term)) {
            return true
        } else if (grape.containsIgnoreCase(search_term)) {
            return true
        } else if (region.containsIgnoreCase(search_term)) {
            return true
        } else if (brand.containsIgnoreCase(search_term)) {
            return true
        } else if (type.containsIgnoreCase(search_term)) {
            return true
        } else {
            for tag in ratings_tags {
                if (tag.comment?.containsIgnoreCase(search_term) ?? false) {
                    return true
                } else if (tag.location?.containsIgnoreCase(search_term) ?? false) {
                    return true
                }
            }
        }
        
        return false
    }
}

// All of our Preferabli API actions go here.
extension Product {
    /// See ``Preferabli/whereToBuy(product_id:fulfill_sort:append_nonconforming_results:lock_to_integration:onCompletion:onFailure:)``.
    public func whereToBuy(fulfill_sort : FulfillSort = FulfillSort.init(), append_nonconforming_results : Bool = true, lock_to_integration : Bool = true,  onCompletion: @escaping (WhereToBuy) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        most_recent_variant.whereToBuy(fulfill_sort: fulfill_sort, append_nonconforming_results: append_nonconforming_results, lock_to_integration: lock_to_integration, onCompletion: onCompletion, onFailure: onFailure)
    }
    
    /// See ``Preferabli/wishlistProduct(product_id:year:location:notes:price:format_ml:onCompletion:onFailure:)`` and ``Preferabli/deleteTag(tag_id:onCompletion:onFailure:)``.
    public func toggleWishlist(onCompletion : @escaping (Product) -> ()  = {_ in }, onFailure : @escaping (PreferabliException) -> () = {_ in }) {
        let tag = wishlist_tag
        var variant = most_recent_variant
        if (tag != nil) {
            variant = tag!.variant!
        }
        variant.toggleWishlist(onCompletion: onCompletion, onFailure: onFailure)
    }
    
    /// See ``Preferabli/rateProduct(product_id:year:rating:location:notes:price:quantity:format_ml:onCompletion:onFailure:)``.
    public func rate(rating : RatingType, location : String? = nil, notes : String? = nil, price : NSNumber? = nil, quantity : NSNumber? = nil, format_ml : NSNumber? = nil, onCompletion : @escaping (Product) -> () = {_ in }, onFailure : @escaping (PreferabliException) -> () = {_ in }) {
        most_recent_variant.rate(rating: rating, location: location, notes: notes, price: price, quantity: quantity, format_ml: format_ml, onCompletion: onCompletion, onFailure: onFailure)
    }
    
    /// See ``Preferabli/lttt(product_id:year:collection_id:include_merchant_links:onCompletion:onFailure:)``.
    public func lttt(collection_id : NSNumber = Preferabli.getPrimaryInventoryId(), onCompletion: @escaping ([Product]) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        most_recent_variant.lttt(collection_id: collection_id, onCompletion: onCompletion, onFailure: onFailure)
    }
    
    /// See ``Preferabli/getPreferabliScore(product_id:year:onCompletion:onFailure:)``.
    public func getPreferabliScore(force_refresh : Bool = false, onCompletion : @escaping (PreferenceData) -> ()  = {_ in }, onFailure : @escaping (PreferabliException) -> () = {_ in }) {
        most_recent_variant.getPreferabliScore(force_refresh: force_refresh, onCompletion: onCompletion, onFailure: onFailure)
    }
}
