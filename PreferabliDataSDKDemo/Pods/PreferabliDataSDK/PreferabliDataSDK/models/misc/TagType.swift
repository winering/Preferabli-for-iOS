//
//  TagType.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/8/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import UIKit

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
