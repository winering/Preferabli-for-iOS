//
//  ShippingType.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/8/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import UIKit

/// Represents a fulfillment method for a ``Venue``. Contained within ``DeliveryMethod``.
public enum ShippingType {
    case SHIPPING
    case LOCAL_DELIVERY
    case PICKUP
    
    static internal func getShippingTypeBasedOffDatabaseName(value : String?) -> ShippingType {
        if (value != nil) {
            switch value! {
            case "standard_shipping":
                return .SHIPPING
            case "local_delivery":
                return .LOCAL_DELIVERY
            case "pickup":
                return .PICKUP
            default:
                return .SHIPPING
            }
        }
        
        return .SHIPPING;
    }

    internal func getDatabaseName() -> String {
        switch self {
        case .SHIPPING:
            return "standard_shipping"
        case .LOCAL_DELIVERY:
            return "local_delivery"
        case .PICKUP:
            return "pickup"
        }
    }
    
    public func compare(_ other: TagType) -> ComparisonResult {
        return self.getDatabaseName().caseInsensitiveCompare(other.getDatabaseName())
    }
}
