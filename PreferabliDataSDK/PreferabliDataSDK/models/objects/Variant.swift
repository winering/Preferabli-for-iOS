//
//  Wine+CoreDataProperties.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/14/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData
import UIKit

/// Used to represent any variation of a ``Product``. An example would be different vintages of the same wine.
public class Variant : BaseObject {
    
    /// Used to represent the most recent variant of a product.
    public static let CURRENT_VARIANT_YEAR : NSNumber = -1
    /// Used to represent a product that does not have variants.
    public static let NON_VARIANT : NSNumber = 0
    
    public var created_at: Date?
    public var fresh: Bool
    public var num_dollar_signs: NSNumber
    public var price: Double
    public var recommendable: Bool
    public var updated_at: Date?
    public var year: NSNumber
    public var primary_image: Media?
    public var product: Product
    public var tags: [Tag]
    
    // transient, computed values
    internal var preference_data : PreferenceData?
    public var merchant_links : [MerchantProductLink]?
    
    internal init(year : NSNumber, product : Product) {
        self.created_at = Date.init()
        self.fresh = false
        self.num_dollar_signs = 0
        self.price = 0.0
        self.recommendable = false
        self.updated_at = Date.init()
        self.year = year
        self.primary_image = nil
        self.product = product
        self.tags = Array<Tag>()
        super.init(id: NSNumber.init(value: PreferabliTools.generateRandomLongId()))
    }
    
    internal init(variant : CoreData_Variant, holding_product : Product?) {
        created_at = variant.created_at
        fresh = variant.fresh
        num_dollar_signs = variant.num_dollar_signs
        price = variant.price
        recommendable = variant.recommendable
        updated_at = variant.updated_at
        year = variant.year
        if (variant.primary_image != nil) {
            primary_image = Media.init(media: variant.primary_image!)
        }
        if (holding_product == nil) {
            product = Product.init(product: variant.product)
        } else {
            product = holding_product!
        }
        tags = Array<Tag>()
        super.init(id: variant.id)
        for tag in variant.tags.allObjects as! [CoreData_Tag] {
            tags.append(Tag.init(tag: tag, holding_variant: self))
        }
    }
    
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
    
    /// The ``RatingType`` of the most recent rating of this variant for the current user.
    var rating_type : RatingType {
        if (most_recent_rating != nil) {
            return RatingType.getRatingTypeBasedOffTagValue(value: most_recent_rating!.value)
        }
        
        return .NONE
    }

    var cellar_tags: Set<Tag> {
        var collectionTags = Set<Tag>()
        for tag in tags {
            if (tag.tag_type == .CELLAR) {
                    collectionTags.insert(tag)
                }
        }
        
        return collectionTags
    }
    
    /// Gets the Preferabli price of this variant.
    /// - Returns: Preferabli price represented by dollar signs in a string.
    ///
    /// Prices represent Retail | Restaurant
    /// - $ = Less than $12 | < $30
    /// - $$ = $12 to $19.99 | $30 - $45
    /// - $$$ = $20 to $49.99 | $45 - $110
    /// - $$$$ = $50 to $74.99 | $110 - $160
    /// - $$$$$ = $75 and up | > $160
    public func getPrice() -> String {
        return Product.getPrice(num_dollar_signs: num_dollar_signs)
    }
    
    /// All the variant's tags of type ``TagType/PURCHASE`` for the current user.
    var purchase_tags: Set<Tag> {
        var purchaseTags = Set<Tag>()
        for tag in tags {
            if (tag.tag_type == .PURCHASE) {
                    purchaseTags.insert(tag)
                }
        }
        
        return purchaseTags
    }
    
    /// Get the variant image.
    /// - Parameters:
    ///   - width: returns an image with the specified width in pixels.
    ///   - height: returns an image with the specified height in pixels.
    ///   - quality: returns an image with the specified quality. Scales from 0 - 100.
    /// - Returns: the URL of the requested image.
    public func getImage(width : CGFloat, height : CGFloat, quality : Int = 80) -> URL? {
        if (primary_image == nil || PreferabliTools.isNullOrWhitespace(string: primary_image!.path) || primary_image!.path.contains("placeholder")) {
            if (product.primary_image == nil || PreferabliTools.isNullOrWhitespace(string: product.primary_image!.path) || product.primary_image!.path.contains("placeholder")) {
                return nil
            }
            return product.getImage(width: width, height: height, quality: quality)
        }
        return PreferabliTools.getImageUrl(image: primary_image?.path, width: width, height: height, quality: quality)
    }
    
    /// All the variant's tags of type ``TagType/RATING`` for the current user.
    var ratings_tags: Set<Tag> {
        var ratingsTags = Set<Tag>()
        for tag in tags {
                if (tag.tag_type == .RATING) {
                    ratingsTags.insert(tag)
                }
        }
        return ratingsTags
    }
    
    /// Get a ``Tag`` by its id.
    /// - Parameter id: id of the ``Tag``.
    /// - Returns: the tag in question or *nil* if it does not exist in this variant.
     public func getTagWithId(id : NSNumber) -> Tag? {
        for tag in tags {
                if (tag.id == id) {
                    return tag
                }
        }
        
        return nil
    }
    
    /// Lets us know if the current user has wishlisted this product.
    /// - Returns: true if it was wishlisted.
    public func isOnWishlist() -> Bool {
       return wishlist_tag != nil
   }
    
    /// The first instance within this variant of tag type ``TagType/WISHLIST`` for the current user.
    var wishlist_tag : Tag? {
               for tag in tags {
                   if (tag.tag_type == .WISHLIST) {
                           return tag
                       }
               }
       
       return nil
   }
}

// All of our Preferabli API actions go here.
extension Variant {
    /// See ``Preferabli/whereToBuy(product_id:fulfill_sort:append_nonconforming_results:lock_to_integration:onCompletion:onFailure:)``.
    public func whereToBuy(fulfill_sort : FulfillSort = FulfillSort.init(), append_nonconforming_results : Bool = true, lock_to_integration : Bool = true,  onCompletion: @escaping (WhereToBuy) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        fulfill_sort.variant_year = year
        Preferabli.main.whereToBuy(product_id: product.id, fulfill_sort: fulfill_sort, append_nonconforming_results: append_nonconforming_results, lock_to_integration: lock_to_integration, onCompletion: onCompletion, onFailure: onFailure)
    }
    
    /// See ``Preferabli/wishlistProduct(product_id:year:location:notes:price:format_ml:onCompletion:onFailure:)`` and ``Preferabli/deleteTag(tag_id:onCompletion:onFailure:)``.
    public func toggleWishlist(onCompletion : @escaping (Product) -> () = {_ in }, onFailure : @escaping (PreferabliException) -> () = {_ in }) {
        if (isOnWishlist()) {
            Preferabli.main.deleteTag(tag_id: wishlist_tag!.id, onCompletion: onCompletion, onFailure: onFailure)
        } else {
            Preferabli.main.wishlistProduct(product_id: product.id, year: year, onCompletion: onCompletion, onFailure: onFailure)
        }
    }
    
    /// See ``Preferabli/rateProduct(product_id:year:rating:location:notes:price:quantity:format_ml:onCompletion:onFailure:)``.
    public func rate(rating : RatingType, location : String? = nil, notes : String? = nil, price : NSNumber? = nil, quantity : NSNumber? = nil, format_ml : NSNumber? = nil, onCompletion : @escaping (Product) -> () = {_ in }, onFailure : @escaping (PreferabliException) -> () = {_ in }) {
        Preferabli.main.rateProduct(product_id: product.id, year: year, rating: rating, location: location, notes: notes, price: price, quantity: quantity, format_ml: format_ml, onCompletion: onCompletion, onFailure: onFailure)
    }
    
    /// See ``Preferabli/lttt(product_id:year:collection_id:onCompletion:onFailure:)``.
    public func lttt(collection_id : NSNumber = Preferabli.getPrimaryInventoryId(), onCompletion: @escaping ([Product]) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        Preferabli.main.lttt(product_id: product.id, year: year, collection_id: collection_id, onCompletion: onCompletion, onFailure: onFailure)
    }
    
    /// See ``Preferabli/getPreferabliScore(product_id:year:onCompletion:onFailure:)``.
    public func getPreferabliScore(force_refresh : Bool = false, onCompletion : @escaping (PreferenceData) -> ()  = {_ in }, onFailure : @escaping (PreferabliException) -> () = {_ in }) {
        if (preference_data == nil || force_refresh) {
            Preferabli.main.getPreferabliScore(product_id: product.id, year: year, onCompletion: onCompletion, onFailure: onFailure)
        } else {
            onCompletion(preference_data!)
        }
    }
}
