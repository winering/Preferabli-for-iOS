//
//  FulfillSortType.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 1/14/21.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation

/// Used to sort within <doc:WhereToBuy>.
public class FulfillSort : Sort {
    
    public var include_shipping : Bool
    public var include_delivery : Bool
    public var include_pickup : Bool
    public var variant_year : NSNumber
    public var distance_miles : NSNumber
    /// *If sorting by distance, location MUST be present!*
    public var location : Location?

    public init(type : SortType = SortType.PRICE, ascending : Bool = true, include_shipping : Bool = true, include_delivery : Bool = true, include_pickup : Bool = true, variant_year : NSNumber = Variant.NON_VARIANT, distance_miles : NSNumber = NSNumber.init(value: 75), location : Location? = nil) {
        self.include_shipping = include_shipping
        self.include_delivery = include_delivery
        self.include_pickup = include_pickup
        self.variant_year = variant_year
        self.distance_miles = distance_miles
        self.location = location
        super.init(type: type, ascending: ascending)
    }
}
