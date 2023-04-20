//
//  Venue+CoreDataProperties.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/14/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

/// A venue represents the details for a specific location. If returned as part of ``WhereToBuy``, will contain an array of ``MerchantProductLink``s as ``links``.
public class Venue : BaseObject {
    
    public var address_l1: String?
    public var address_l2: String?
    public var city: String?
    public var country: String?
    public var display_name: String
    public var lat: NSNumber?
    public var lon: NSNumber?
    public var primary_inventory_id: NSNumber?
    public var featured_collection_id: NSNumber?
    public var is_virtual: Bool
    public var name: String?
    public var phone: String?
    public var email_address: String?
    public var state: String?
    public var url: String?
    public var url_facebook: String?
    public var url_instagram: String?
    public var url_twitter: String?
    public var url_youtube: String?
    public var zip_code: String?
    public var notes: String?
    public var images = [Media]()
    public var hours = [VenueHour]()
    
    internal var hasShipping : Bool?
    internal var hasLocalDelivery : Bool?
    internal var hasPickup : Bool?
    
    /// All of the links in stock at this venue. Call Where to Buy to populate.
    public var links = [MerchantProductLink]()
    /// Available delivery methods for the current user. Call Where to Buy to populate.
    public var active_delivery_methods = [DeliveryMethod]()
    
    internal init(map : [String : Any]) {
        address_l1 = map["address_l1"] as? String
        address_l2 = map["address_l2"] as? String
        city = map["city"] as? String
        country = map["country"] as? String
        display_name = map["display_name"] as! String
        lat = map["lat"] as? NSNumber
        lon = map["lon"] as? NSNumber
        primary_inventory_id = map["primary_inventory_id"] as? NSNumber
        featured_collection_id = map["featured_collection_id"] as? NSNumber
        is_virtual = map["is_virtual"] as? Bool ?? false
        name = map["name"] as? String
        phone = map["phone"] as? String
        email_address = map["email_address"] as? String
        state = map["state"] as? String
        url = map["url"] as? String
        url_facebook = map["url_facebook"] as? String
        url_instagram = map["url_instagram"] as? String
        url_youtube = map["url_youtube"] as? String
        zip_code = map["zip_code"] as? String
        notes = map["notes"] as? String
    
        if (map["lookups"] != nil) {
            for lookup in map["lookups"] as! Array<[String : Any]> {
                links.append(MerchantProductLink.init(map: lookup))
            }
            links = MerchantProductLink.sortLinksByPrice(links: links, ascending: true)
        }
        
        for method in map["active_delivery_methods"] as! Array<[String : Any]> {
            active_delivery_methods.append(DeliveryMethod.init(map: method))
        }
        
        for media in map["images"] as! Array<[String : Any]> {
            images.append(Media.init(map: media))
        }
        
        for hour in map["hours"] as! Array<[String : Any]> {
            hours.append(VenueHour.init(map: hour))
        }
        
        super.init(id: map["id"] as? NSNumber ?? NSNumber.init(value: 0))
    }
    
    internal init(venue : CoreData_Venue, first : Bool) {
        address_l1 = venue.address_l1
        address_l2 = venue.address_l2
        city = venue.city
        country = venue.country
        display_name = venue.display_name
        lat = venue.lat
        lon = venue.lon
        primary_inventory_id = venue.primary_inventory_id
        featured_collection_id = venue.featured_collection_id
        is_virtual = venue.is_virtual
        name = venue.name
        phone = venue.phone
        email_address = venue.email_address
        state = venue.state
        url = venue.url
        url_facebook = venue.url_facebook
        url_instagram = venue.url_instagram
        url_youtube = venue.url_youtube
        zip_code = venue.zip_code
        notes = venue.notes
        
        for method in venue.active_delivery_methods?.allObjects as! [CoreData_DeliveryMethod] {
            active_delivery_methods.append(DeliveryMethod.init(method: method))
        }
        
        for media in venue.images?.allObjects as! [CoreData_Media] {
            images.append(Media.init(media: media))
        }

        super.init(id: venue.id)
        
        for hour in venue.hours?.allObjects as! [CoreData_VenueHour] {
            hours.append(VenueHour.init(venue_hour: hour))
        }
    }
    
    /// Get your distance in miles to the venue.
    /// - Parameters:
    ///   - your_lat: user's latitude as a NSNumber.
    ///   - your_lon: user's longitude as a NSNumer.
    /// - Returns: user's distance to the venue in miles.
    public func getDistanceInMiles(your_lat: NSNumber, your_lon: NSNumber) -> Int? {
            return PreferabliTools.calculateDistanceInMiles(lat1: your_lat, lon1: your_lon, lat2: lat, lon2: lon)
    }
    
    /// Get a formatted return of the address for a specific venue.
    /// - Parameter one_line: pass true if you want the address returned in one line. False returns the address in a multiline format.
    /// - Returns: the venue's full formatted address.
    public func getFormattedAddress(one_line : Bool) -> String {
        var newLine = "\n"
        if one_line {
            newLine = " | "
        }
        let firstTwo = (PreferabliTools.isNullOrWhitespace(string: address_l1) ? "" : (address_l1! + newLine)) + (PreferabliTools.isNullOrWhitespace(string: address_l2) ? "" : (address_l2! + newLine))
        var third = PreferabliTools.isNullOrWhitespace(string: city) ? "" : (city! + ", ")
        third = third + (state ?? "") + " " + (zip_code ?? "") + (PreferabliTools.isNullOrWhitespace(string: country) ? "" : (newLine + country!))
        return firstTwo + third
    }
    
    /// Get the venue's city and state.
    /// - Returns: city, state, city and state, or a blank string depending on the information available.
    public func getCityState() -> String {
        if (PreferabliTools.isNullOrWhitespace(string: ((city ?? "") + (state ?? "")))) {
            return ""
        } else if (PreferabliTools.isNullOrWhitespace(string: city)) {
            return state ?? ""
        } else if (PreferabliTools.isNullOrWhitespace(string: state)) {
            return city ?? ""
        } else {
            return (city ?? "") + ", " + (state ?? "")
        }
    }
    
    /// Get the venue's shipping speed.
    /// - Returns: the venue's notes about its shipping speed.
    public func getShippingSpeedNote() -> String? {
        for delivery_method in active_delivery_methods{
            if (delivery_method.shipping_type == "standard_shipping") {
                return delivery_method.shipping_speed_note
            }
        }
        
        return ""
    }
    
    /// Get the venue's shipping cost.
    /// - Returns: the venue's notes about its shipping cost.
    public func getShippingCostNote() -> String? {
        for delivery_method in active_delivery_methods {
            if (delivery_method.shipping_type == "standard_shipping") {
                return delivery_method.shipping_cost_note
            }
        }
        
        return ""
    }
    
    /// Does the venue offer shipping?
    /// - Returns: true if the venue can ship to the user.
    public func getHasShipping() -> Bool {
        if (hasShipping == nil) {
            getDeliveryMethods()
        }
        
        return hasShipping!
    }
    
    /// Does the venue offer local delivery?
    /// - Returns: true if the venue can deliver locally to the user.
    public func getHasLocalDelivery() -> Bool {
        if (hasLocalDelivery == nil) {
            getDeliveryMethods()
        }
        
        return hasLocalDelivery!
    }
    
    /// Does the venue offer pickup?
    /// - Returns: true if the the user can pickup at the venue.
    public func getHasPickup() -> Bool {
        if (hasPickup == nil) {
            getDeliveryMethods()
        }
        
        return hasPickup!
    }
    
    /// Get the open time for the given day of the week for a venue.
    /// - Parameter weekday: a day of the week.
    /// - Returns: the opening time of the venue if it is available. Returns *nil* if it does not exist.
    public func getOpenTime(weekday : Weekday) -> String? {
        let venueHours = hours
        for hour in venueHours {
            if (hour.day_of_week == weekday) {
                return hour.open_time
            }
        }
        
        return nil
    }
    
    /// Get the close time for the given day of the week for a venue.
    /// - Parameter weekday: a day of the week.
    /// - Returns: the closing time of the venue if it is available. Returns *nil* if it does not exist.
    public func getCloseTime(weekday : Weekday) -> String {
        let venueHours = hours
        for hour in venueHours {
            if (hour.day_of_week == weekday) {
                return hour.close_time ?? ""
            }
        }
        
        return ""
    }
    
    /// Get whether a venue is closed for the given day of the week.
    /// - Parameter weekday: a day of the week.
    /// - Returns: true if the venue is closed on the given day.
    public func getIsClosed(weekday : Weekday) -> Bool {
        let venueHours = hours
        for hour in venueHours {
            if (hour.day_of_week == weekday) {
                return hour.is_closed
            }
        }
        
        return false
    }
    
    internal func getDeliveryMethods() {
        hasShipping = false
        hasLocalDelivery = false
        hasPickup = false
        
        for delivery_method in active_delivery_methods {
            if (delivery_method.shipping_type == "standard_shipping") {
                hasShipping = true
            } else if (delivery_method.shipping_type == "local_delivery") {
                hasLocalDelivery = true
            } else if (delivery_method.shipping_type == "pickup") {
                hasPickup = true
            }
        }
    }
    
    /// Filter venues by a user's search.
    /// - Parameters:
    ///   - venues: an array of venues to be filtered.
    ///   - search_text: user's search query as a string.
    /// - Returns: a filtered array of venues.
    static public func filterVenues(venues : Array<Venue>, search_text : String) -> Array<Venue> {
        var filteredVenues = Array<Venue>()
        if (search_text.isEmptyOrWhitespace()) {
            filteredVenues = venues
        } else {
            let searchTerms = search_text.components(separatedBy: " ")
            filteredVenues = venues.filter() {
                for searchTerm in searchTerms {
                    if ($0.filterVenue(search_term: searchTerm)) {
                        continue
                    } else {
                        return false
                    }
                }
                return true
            }
        }
        
        filteredVenues = filteredVenues.filter() { $0.links.count > 0 }
        
        return filteredVenues
    }
    
    internal func filterVenue(search_term : String) -> Bool {
        if (search_term.isEmptyOrWhitespace()) {
            return true
        } else if (country?.containsIgnoreCase(search_term) ?? false) {
            return true
        } else if (city?.containsIgnoreCase(search_term) ?? false) {
            return true
        } else if (display_name.containsIgnoreCase(search_term)) {
            return true
        } else if (name?.containsIgnoreCase(search_term) ?? false) {
            return true
        } else if (state?.containsIgnoreCase(search_term) ?? false) {
            return true
        } else if (address_l1?.containsIgnoreCase(search_term) ?? false) {
            return true
        } else if (address_l2?.containsIgnoreCase(search_term) ?? false) {
            return true
        } else {
            for lookup in links {
                if (lookup.filterLink(search_term: search_term)) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Get the Facebook url for a venue.
    /// - Returns: the full Facebook url of the venue.
    public func getFacebookUrl() -> String {
        return "https://www.facebook.com/" + (url_facebook ?? "")
    }
    
    /// Get the Instagram url for a venue.
    /// - Returns: the full Instagram url of the venue.
    public func getInstagramUrl() -> String {
        return "https://www.instagram.com/" + (url_instagram ?? "")
    }
    
    /// Get the Twitter url for a venue.
    /// - Returns: the full Twitter url of the venue.
    public func getTwitterUrl() -> String {
        return "https://www.twitter.com/" + (url_twitter ?? "")
    }
    
    /// Get the YouTube url for a venue.
    /// - Returns: the full YouTube url of the venue.
    public func getYoutubeUrl() -> String {
        return "https://www.youtube.com/" + (url_youtube ?? "")
    }
    
    /// Sort an array of venues by their distance from the user.
    /// - Parameters:
    ///   - venues: an array of venues to be sorted.
    ///   - ascending: true for ascending order. False for descending.
    ///   - your_lat: user's latitude as a NSNumber.
    ///   - your_lon: user's longitude as a NSNumber.
    /// - Returns: a sorted array of venues.
    static public func sortVenuesByDistance(venues: [Venue], ascending : Bool, your_lat: NSNumber, your_lon: NSNumber) -> Array<Venue> {
        return venues.sorted {
            if ($0.getDistanceInMiles(your_lat: your_lat, your_lon: your_lon) == nil) {
                return false
            } else if ($1.getDistanceInMiles(your_lat: your_lat, your_lon: your_lon) == nil) {
                return true
            }
            
            if ($0.getDistanceInMiles(your_lat: your_lat, your_lon: your_lon) == $1.getDistanceInMiles(your_lat: your_lat, your_lon: your_lon)) {
                return PreferabliTools.alphaSortIgnoreThe(x: $0.name ?? "", y: $1.name ?? "")
            }
            
            if (ascending) {
                return $0.getDistanceInMiles(your_lat: your_lat, your_lon: your_lon)! < $1.getDistanceInMiles(your_lat: your_lat, your_lon: your_lon)!
            } else {
                return $0.getDistanceInMiles(your_lat: your_lat, your_lon: your_lon)! > $1.getDistanceInMiles(your_lat: your_lat, your_lon: your_lon)!
            }
        }
    }
}
