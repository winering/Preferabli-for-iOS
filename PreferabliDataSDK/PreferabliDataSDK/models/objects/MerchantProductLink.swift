//
//  MerchantProductLink.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 1/28/20.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//
//

import Foundation
import CoreData


/// This is the link between a Preferabli product and a merchant product.  If returned as part of ``WhereToBuy``, will contain an array of ``Venue`` as ``venues``.
public class MerchantProductLink : BaseObject {
    
    public var variant_id: NSNumber?
    public var product_id: NSNumber?
    public var merchant_variant_id: String?
    public var merchant_product_id: String?
    public var price_currency: String?
    public var year: NSNumber?
    public var format_ml: NSNumber?
    public var landing_url: String?
    public var product_name: String?
    public var price: String?
    
    /// All of the venues that include the specific item in the inventory collection. Call Where to Buy to populate.
    public var venues: [Venue]?
    /// True if this item does not conform to all Where to Buy query parameters.
    public var nonconforming_result: Bool
    
    internal init(map : [String : Any]) {
        variant_id = map["variant_id"] as? NSNumber
        product_id = map["product_id"] as? NSNumber
        merchant_variant_id = map["merchant_variant_id"] as? String
        merchant_product_id = map["merchant_product_id"] as? String
        price_currency = map["price_currency"] as? String
        nonconforming_result = map["nonconforming_result"] as? Bool ?? false
        year = map["year"] as? NSNumber
        format_ml = map["format_ml"] as? NSNumber
        landing_url = map["landing_url"] as? String
        product_name = map["product_name"] as? String
        price = map["price"] as? String
        
        if (map["venues"] != nil) {
            venues = Array<Venue>()
            for venue in map["venues"] as! Array<[String : Any]> {
                venues!.append(Venue.init(map: venue))
            }
        }
        
        super.init(id: map["id"] as? NSNumber ?? NSNumber.init(value: 0))
    }
    
//    internal init(lookup : CoreData_MerchantProductLink, first : Bool) {
//        variant_id = lookup.variant_id
//        price_currency = lookup.price_currency
//        nonconforming_result = lookup.nonconforming_result
//        year = lookup.variant_year
//        format_ml = lookup.format_ml
//        landing_url = lookup.landing_url
//        product_name = lookup.product_name
//        price = lookup.bottle_price
//
//        if (first) {
//            var wtbVenues = Array<Venue>()
//            for venue in lookup.venues?.allObjects as! [CoreData_Venue] {
//                wtbVenues.append(Venue.init(venue: venue, first: false))
//            }
//            venues = Venue.sortVenues(venues: wtbVenues, ascending: true)
//        }
//
//        super.init(id: lookup.id)
//    }
    
    /// Filter links by submitted search terms.
    /// - Parameters:
    ///   - lookups: an array of links to be filtered.
    ///   - search_text: search terms as a string.
    /// - Returns: a filtered array of links.
    static public func filterLinks(lookups : Array<MerchantProductLink>, search_text : String) -> Array<MerchantProductLink> {
        var filteredLookups = Array<MerchantProductLink>()
        if (search_text.isEmptyOrWhitespace()) {
            filteredLookups = lookups
        } else {
            let searchTerms = search_text.components(separatedBy: " ")
            filteredLookups = lookups.filter() {
                for searchTerm in searchTerms {
                    if ($0.filterLink(search_term: searchTerm)) {
                        continue
                    } else {
                        return false
                    }
                }
                return true
            }
        }
        
        filteredLookups = filteredLookups.filter() { $0.getVenues().count > 0 }
        
        return filteredLookups
    }
    
    internal func filterLink(search_term : String) -> Bool {
        if (search_term.isEmptyOrWhitespace()) {
            return true
        } else if (product_name?.containsIgnoreCase(search_term) ?? false) {
            return true
        } else {
            for venue in getVenues() {
                if (venue.filterVenue(search_term: search_term)) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Gets an array of Where to Buy venues.
    /// - Returns: an array of ``Venue``. Returns an empty array if not populated.
    public func getVenues() -> Array<Venue> {
        if (venues == nil) {
            venues = Array<Venue>()
        }
        return venues!
    }
    
    /// Sorts links by price.
    /// - Parameters:
    ///   - links: an array of links to be sorted.
    ///   - ascending: true if you want results returned in ascending order. Defaults to *true*.
    /// - Returns: a sorted array of links.
    static public func sortLinksByPrice(links : Array<MerchantProductLink>, ascending : Bool = true) -> [MerchantProductLink] {
        return links.sorted {
            let integer1 = Float($0.price ?? "") ?? -1
            let price1 = NSNumber(value: integer1)
            
            let integer2 = Float($1.price ?? "") ?? -1
            let price2 = NSNumber(value: integer2)
            
            if (price1 == price2) {
                return PreferabliTools.alphaSortIgnoreThe(x: $0.product_name ?? "", y: $1.product_name ?? "")
            }
            
            if (ascending) {
                return price1.floatValue < price2.floatValue
            } else {
                return price1.floatValue > price2.floatValue
            }
        }
    }
    
    /// Gets price formatted with the currency.
    /// - Returns: a string representing the localized price.
    public func getFormattedPrice() -> String {
        if (price == nil) {
            return ""
        }
        let formatter = NumberFormatter()
        formatter.locale = PreferabliTools.getLocaleForCurrencyCode(currencyCode: price_currency)
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber.init(value: Double(price!)!))!
    }
}

// All of our Preferabli API actions go here.
extension MerchantProductLink {
    /// See ``Preferabli/whereToBuy(product_id:fulfill_sort:append_nonconforming_results:lock_to_integration:onCompletion:onFailure:)``.
    public func whereToBuy(fulfill_sort : FulfillSort = FulfillSort.init(), append_nonconforming_results : Bool = true, lock_to_integration : Bool = true,  onCompletion: @escaping (WhereToBuy) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        if (product_id != nil) {
            Preferabli.main.whereToBuy(product_id: product_id!, fulfill_sort: fulfill_sort, append_nonconforming_results: append_nonconforming_results, lock_to_integration: lock_to_integration, onCompletion: onCompletion, onFailure: onFailure)
        }
    }
}
