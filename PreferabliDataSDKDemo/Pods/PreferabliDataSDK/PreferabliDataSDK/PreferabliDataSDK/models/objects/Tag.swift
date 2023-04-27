//
//  Tag.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/14/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData
import UIKit


/// Chronicles a user's interaction with a product. Is one of a type ``TagType``.
public class Tag : BaseObject {

     public var collection_id: NSNumber
     public var comment: String?
     public var created_at: Date
     public var location: String?
     public var badge: String?
     public var tagged_in_collection_id: NSNumber?
     public var tagged_in_channel_id: NSNumber?
     public var tagged_in_channel_name: String?
     public var type: String
     public var updated_at: Date
     public var user_id: NSNumber
     public var value: String?
     public var bin: String?
     public var variant_id: NSNumber
     public var product_id: NSNumber
     public var quantity: NSNumber?
     public var format_ml: NSNumber?
     public var price: NSNumber?
     public var variant: Variant?
    
    internal init(tag : CoreData_Tag, holding_variant : Variant) {
        collection_id = tag.collection_id
        comment = tag.comment
        created_at = tag.created_at
        location = tag.location
        badge = tag.badge
        tagged_in_collection_id = tag.tagged_in_collection_id
        tagged_in_channel_id = tag.tagged_in_channel_id
        tagged_in_channel_name = tag.tagged_in_channel_name
        type = tag.type
        updated_at = tag.updated_at
        user_id = tag.user_id
        value = tag.value
        bin = tag.bin
        variant_id = tag.variant_id
        product_id = tag.product_id
        quantity = tag.quantity
        format_ml = tag.format_ml
        price = tag.price
        variant = holding_variant
        super.init(id: tag.id)
    }
    
    /// The type of the tag.
    var tag_type : TagType {
        return TagType.getTagTypeBasedOffDatabaseName(value: type)
    }
    
    /// The rating level of the tag. Only for tags of type ``TagType/RATING``.
    var rating_level : RatingLevel {
        return RatingLevel.getRatingLevelBasedOffTagValue(value: value)
    }
    
    /// Sort tags by date.
    /// - Parameter tags: an array of tags to be sorted.
    /// - Returns: a sorted array of tags.
    static public func sortTagsByDate(tags : Array<Tag>) -> [Tag] {
        return tags.sorted { $0.created_at.compare($1.created_at) == ComparisonResult.orderedDescending }
    }
    
    /// Gets the formmated version of ``price``.
    /// - Parameter currency_code: code of the currency you would like to use for formatting.
    /// - Returns: a currency formatted price.
    public func getPrice(currency_code: String = (Locale.current.currencySymbol ?? "USD")) -> String {
        let formatter = NumberFormatter()
        formatter.locale = PreferabliTools.getLocaleForCurrencyCode(currencyCode: currency_code)
        formatter.numberStyle = .currency
        return formatter.string(from: price ?? NSNumber.init(value: 0)) ?? ""
    }
}

extension Tag {
    /// See ``Preferabli/deleteTag(tag_id:onCompletion:onFailure:)``.
    public func delete(onCompletion : @escaping (Product) -> ()  = {_ in }, onFailure : @escaping (PreferabliException) -> () = {_ in }) {
        Preferabli.main.deleteTag(tag_id: id, onCompletion: onCompletion, onFailure: onFailure)
    }
    
    /// See ``Preferabli/editTag(tag_id:tag_type:year:rating:location:notes:price:quantity:format_ml:onCompletion:onFailure:)``.
    public func edit(year : NSNumber, rating : RatingLevel = .NONE, location : String? = nil, notes : String? = nil, price : NSNumber? = nil, quantity : NSNumber? = nil, format_ml : NSNumber? = nil, onCompletion : @escaping (Product) -> () = {_ in }, onFailure : @escaping (PreferabliException) -> () = {_ in }) {
        Preferabli.main.editTag(tag_id: id, tag_type: tag_type, year: year, rating: rating, location: location, notes: notes, price: price, quantity: quantity, format_ml: format_ml, onCompletion: onCompletion, onFailure: onFailure)
    }
}

/// The degree of appeal for a product as identified by a ``Tag``.
public enum RatingLevel {
    /// A user loved the product.
    case LOVE
    /// A user liked the product.
    case LIKE
    /// A user did not find the product to be appealing, but not as far as a dislike.  We like to say, "I'd drink it but only if I wasn't paying for it."
    case SOSO
    /// A user disliked the product.
    case DISLIKE
    /// Not a valid rating.
    case NONE
    
    static internal func getRatingLevelBasedOffTagValue(value : String?) -> RatingLevel {
        if (value != nil) {
            switch value! {
            case "0":
                return RatingLevel.NONE
            case "1":
                return RatingLevel.DISLIKE
            case "2":
                return RatingLevel.SOSO
            case "3":
                return RatingLevel.LIKE
            case "4":
                return RatingLevel.LOVE
            default:
                return RatingLevel.NONE
            }
        }
        
        return RatingLevel.NONE;
    }
    
    internal func getValue() -> String {
        switch self {
        case .LOVE:
            return "4"
        case .LIKE:
            return "3"
        case .SOSO:
            return "2"
        case .DISLIKE:
            return "1"
        case .NONE:
            return "0"
        }
    }
    
    public func compare(_ other: RatingLevel) -> ComparisonResult {
        return self.getValue().caseInsensitiveCompare(other.getValue())
    }
}

/// Type of a ``Tag``. Tags may can contain different information depending on it's type.
public enum TagType {
    case RATING
    case CELLAR
    case PURCHASE
    case WISHLIST
    case OTHER
    
    static internal func getTagTypeBasedOffDatabaseName(value : String?) -> TagType {
        if (value != nil) {
            switch value! {
            case "rating":
                return .RATING
            case "collection":
                return .CELLAR
            case "purchase":
                return .PURCHASE
            case "wishlist":
                return .WISHLIST
            default:
                return .OTHER
            }
        }
        
        return .OTHER;
    }

    internal func getDatabaseName() -> String {
        switch self {
        case .RATING:
            return "rating"
        case .CELLAR:
            return "collection"
        case .PURCHASE:
            return "purchase"
        case .WISHLIST:
            return "wishlist"
        case .OTHER:
            return "other"
        }
    }
    
    public func compare(_ other: TagType) -> ComparisonResult {
        return self.getDatabaseName().caseInsensitiveCompare(other.getDatabaseName())
    }
}
