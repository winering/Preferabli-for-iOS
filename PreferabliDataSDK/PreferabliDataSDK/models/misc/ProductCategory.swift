//
//  ProductType.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/8/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import UIKit

/// The category of a ``Product``.  
public enum ProductCategory {
    case WHISKEY
    case MEZCAL
    case BEER
    case WINE
    case NONE

    internal func getCategoryName() -> String {
        switch self {
        case .WHISKEY:
            return "whiskey"
        case .MEZCAL:
            return "tequila"
        case .BEER:
            return "beer"
        case .WINE:
            return "wine"
        case .NONE:
            return ""
        }
    }
    
    static internal func getProductCategoryFromString(value : String?) -> ProductCategory {
        if (value != nil) {
            switch value!.lowercased() {
            case "whiskey":
                return .WHISKEY
            case "tequila":
                return .MEZCAL
            case "beer":
                return .BEER
            case "wine":
                return .WINE
            default:
                return .NONE
            }
        }
        
        return .NONE
    }
}
