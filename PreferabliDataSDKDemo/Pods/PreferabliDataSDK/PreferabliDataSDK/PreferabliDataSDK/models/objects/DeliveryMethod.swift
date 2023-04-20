//
//  DeliveryMethod.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 1/8/20.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//
//

import Foundation
import CoreData

/// Represents a location that a ``Venue`` provides a specified delivery method (``ShippingType``).
public class DeliveryMethod : BaseObject {
    
    public var shipping_type: String
    public var state_abbreviation: String?
    public var state_display_name: String?
    public var country: String?
    public var shipping_cost_note: String?
    public var shipping_speed_note: String?
    
    internal init(map : [String : Any]) {
        shipping_type = map["shipping_type"] as! String
        state_abbreviation = map["state_abbreviation"] as? String
        state_display_name = map["state_display_name"] as? String
        country = map["country"] as? String
        shipping_cost_note = map["shipping_cost_note"] as? String
        shipping_speed_note = map["shipping_speed_note"] as? String
        
        super.init(id: map["id"] as? NSNumber ?? NSNumber.init(value: 0))
    }
    
    internal init(method : CoreData_DeliveryMethod) {
        shipping_type = method.shipping_type
        state_abbreviation = method.state_abbreviation
        state_display_name = method.state_display_name
        country = method.country
        shipping_cost_note = method.shipping_cost_note
        shipping_speed_note = method.shipping_speed_note
        super.init(id: method.id)
    }
    
    /// Shipping Type of this fulfillment method.
    var type : ShippingType {
        return ShippingType.getShippingTypeBasedOffDatabaseName(value: shipping_type)
    }
}
