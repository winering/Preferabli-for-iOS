//
//  RatingLevel.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/8/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import UIKit

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
    
    static internal func getRatingTypeBasedOffTagValue(value : String?) -> RatingLevel {
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
