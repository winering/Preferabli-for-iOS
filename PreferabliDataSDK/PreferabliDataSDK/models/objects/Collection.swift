//
//  Collection.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/14/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData
import UIKit

/// A Collection is a selection of Products, organized into one or more groupings.  For example, a Collection can represent an inventory for a store or just a subset of Products, such as selection of Products that are currently on sale or a selection of private-label Products.
///
/// In general, a Collection will be an Inventory or an Event.  Events are temporal in nature, such as a tasting events or weekly promotions.  Inventories, whether entire inventories or subsets of an inventory, are meant to change from time to time but are not specifically temporal in nature.  A Collection may be a Cellar type (e.g., a ``Customer``'s personal cellar) or Other type.
public class Collection : BaseObject {
    
    public var channel_id: NSNumber?
    public var code: String?
    public var desc: String?
    public var end_date: Date?
    public var updated_at: Date
    public var display_time: Bool
    public var is_browsable: Bool
    public var is_my_cellar: Bool
    public var product_count: NSNumber
    public var name: String
    public var badge_method: String
    public var currency: String
    public var timezone: String
    public var `public`: Bool
    public var published: Bool
    public var archived: Bool
    public var display_price: Bool
    public var display_quantity: Bool
    public var display_bin: Bool
    public var has_predict_order: Bool
    public var is_randomized: Bool
    public var display_group_headings: Bool
    public var is_blind: Bool
    public var start_date: Date?
    public var venue_id: NSNumber?
    public var primary_image: Media?
    public var venue: Venue?
    public var versions: [CollectionVersion]
    public var sort_channel_name: String
    
    /// Collection Type of this collection.  In general, collections will be an Inventory or an Event.  Events are temporal in nature, such as a tasting event or a sale.  Inventories, whether entire inventories or subsets of an inventory, are meant to change from time to time but are not specifically temporal in nature.
    var type : CollectionType {
        return CollectionType.getCollectionTypeBasedOffCollection(collection: self)
    }
    
    internal var traits: [CollectionTrait]
    
    internal init(collection : CoreData_Collection) {
        channel_id = collection.channel_id
        code = collection.code
        desc = collection.desc
        end_date = collection.end_date
        updated_at = collection.updated_at
        display_time = collection.display_time
        is_browsable = collection.is_browsable
        is_my_cellar = collection.is_my_cellar
        product_count = collection.product_count
        name = collection.name
        badge_method = collection.badge_method
        currency = collection.currency
        timezone = collection.timezone
        `public` = collection.public
        published = collection.published
        archived = collection.archived
        display_price = collection.display_price
        display_quantity = collection.display_quantity
        display_bin = collection.display_bin
        has_predict_order = collection.has_predict_order
        is_randomized = collection.is_randomized
        display_group_headings = collection.display_group_headings
        is_blind = collection.is_blind
        start_date = collection.start_date
        venue_id = collection.venue_id
        if (collection.primary_image != nil) {
            primary_image = Media.init(media: collection.primary_image!)
        }
        if (collection.venue != nil) {
            venue = Venue.init(venue: collection.venue!, first: false)
        }
        versions = Array<CollectionVersion>()
        sort_channel_name = collection.sort_channel_name
        traits = Array<CollectionTrait>()

        super.init(id: collection.id)
        for version in collection.versions.allObjects as! [CoreData_CollectionVersion] {
            versions.append(CollectionVersion.init(collection_version: version, holding_collection: self))
        }
        for trait in collection.traits.allObjects as! [CoreData_CollectionTrait] {
            traits.append(CollectionTrait.init(collection_trait: trait))
        }
    }
    
    /// Get the collection image.
    /// - Parameters:
    ///   - width: returns an image with the specified width in pixels.
    ///   - height: returns an image with the specified height in pixels.
    ///   - quality: returns an image with the specified quality. Scales from 0 - 100.
    /// - Returns: the URL of the requested image.
    public func getImage(width : CGFloat, height : CGFloat, quality : Int = 80) -> URL? {
        return PreferabliTools.getImageUrl(image: primary_image?.path, width: width, height: height, quality: quality)
    }
    
    /// Get the start date of the collection. Start dates are useful for collections of type Event.
    /// - Returns: the start date - or nil if it does not exist.
    public func getStartDate() -> Date? {
        if let startDate = start_date {
            return startDate
        }
        return nil
    }
    
    /// Get the last updated date of the collection.
    /// - Returns: the updated at date.
    public func getUpdatedDate() -> Date {
        return updated_at
    }
    
    /// Get the end date of the collection. End dates are useful for collection of type Event.
    /// - Returns: the end date - or nil if it does not exist.
    public func getExpirationDate() -> Date? {
        if let expirationDate = end_date {
            return expirationDate
        }
        return nil
    }
    
    /// This helper method fitlers an array of collections to an array of collections where the type is Inventory.
    /// - Parameter collections: array of collections of different types.
    /// - Returns: array of collection of type Inventory.
    static public func filterToInventories(collections : Array<Collection>) -> [Collection] {
        return collections.filter() {
            return $0.isInventory()
        }
    }
    
    /// Sort collections by their updated at date.
    /// - Parameters:
    ///   - collections: array of collections to be sorted.
    ///   - comparison_result: can be ascending or descending. Defaults to *descending*.
    /// - Returns: a sorted array of collections.
    static public func sortCollectionsByLastUpdated(collections : Array<Collection>, comparison_result: ComparisonResult = .orderedDescending) -> [Collection] {
        return collections.sorted {
            let date1 = $0.getUpdatedDate()
            let date2 = $1.getUpdatedDate()
            
            if (date1.compare(date2) == ComparisonResult.orderedSame) {
                return PreferabliTools.alphaSortIgnoreThe(x: $0.name, y: $1.name)
            }
            return date1.compare(date2) == comparison_result
        }
    }
    
    /// Sort collections alphabetically.
    /// - Parameters:
    ///   - collections: array of collections to be sorted.
    ///   - comparison_result: can be ascending or descending. Defaults to *ascending*.
    /// - Returns: a sorted array of collections.
    static public func sortCollectionsAlpha(collections : Array<Collection>, comparison_result: ComparisonResult = .orderedAscending) -> [Collection] {
        return collections.sorted {
            return PreferabliTools.alphaSortIgnoreThe(x: $0.name, y: $1.name, comparisonResult: comparison_result)
        }
    }
    
    /// Filter collections by search.
    /// - Parameters:
    ///   - collections: array of collections to be filtered.
    ///   - search_text: string that contains the search term.
    /// - Returns: a filtered array of collections.
    static public func filterCollections(collections : Array<Collection>, search_text : String) -> Array<Collection> {
        var filteredCollections = Array<Collection>()
        if (search_text.isEmptyOrWhitespace()) {
            filteredCollections = collections
        } else {
            let searchTerms = search_text.components(separatedBy: " ")
            filteredCollections = collections.filter() {
            innerloop:
                for searchTerm in searchTerms {
                    if ($0.filterCollection(search_term: searchTerm)) {
                        continue
                    } else {
                        return false
                    }
                }
                return true
            }
        }
        return filteredCollections
    }
    
    internal func filterCollection(search_term : String) -> Bool {
        if (search_term.isEmptyOrWhitespace()) {
            return true
        } else if (name.containsIgnoreCase(search_term)) {
            return true
        } else if (sort_channel_name.containsIgnoreCase(search_term)) {
            return true
        } else if (venue?.display_name.containsIgnoreCase(search_term) ?? false) {
            return true
        }
        return false
    }
    
    /// Lets us know if a collection is of the type ``CollectionType/INVENTORY``.
    /// - Returns: true if an inventory.
    public func isInventory() -> Bool {
        for trait in traits {
            if (trait.id == 86) {
                return true
            }
        }
        
        return false
    }
    
    /// Lets us know if a collection is of the type ``CollectionType/EVENT``.
    /// - Returns: true if an event.
    public func isEvent() -> Bool {
        for trait in traits {
            if (trait.id == 84 || trait.id == 88 || trait.id == 90) {
                return true
            }
        }
        
        return false
    }
}
