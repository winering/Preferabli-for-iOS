//
//  RatingType.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/8/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import UIKit

/// The rating type of a ``Tag``. Can be one of four valid values.
public enum RatingType {
    /// A user really loved the product.
    case LOVE
    /// A user enjoyed the product.
    case LIKE
    /// A user found the product to be OK. Would drink if somebody else was paying for it.
    case SOSO
    /// A user really did not like the product.
    case DISLIKE
    /// Not a valid rating.
    case NONE
    
    static internal func getRatingTypeBasedOffTagValue(value : String?) -> RatingType {
        if (value != nil) {
            switch value! {
            case "0":
                return RatingType.NONE
            case "1":
                return RatingType.DISLIKE
            case "2":
                return RatingType.SOSO
            case "3":
                return RatingType.LIKE
            case "4":
                return RatingType.LOVE
            default:
                return RatingType.NONE
            }
        }
        
        return RatingType.NONE;
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
    
    public func compare(_ other: RatingType) -> ComparisonResult {
        return self.getValue().caseInsensitiveCompare(other.getValue())
    }
}
