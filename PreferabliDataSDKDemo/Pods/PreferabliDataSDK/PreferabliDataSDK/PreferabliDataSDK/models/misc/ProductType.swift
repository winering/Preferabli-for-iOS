//
//  ProductType.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/8/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import UIKit

/// The recognized type of a ``Product``.  At this time, non-wine products use the type ``ProductType/OTHER``.
public enum ProductType {
    case RED
    case WHITE
    case ROSE
    case SPARKLING
    case FORTIFIED
    /// Use other if product is not a wine (e.g., a whiskey, mezcal/tequila, or beer).
    case OTHER

    internal func getTypeName() -> String {
        switch self {
        case .RED:
            return "red"
        case .WHITE:
            return "white"
        case .ROSE:
            return "rosé"
        case .SPARKLING:
            return "sparkling"
        case .FORTIFIED:
            return "fortified"
        case .OTHER:
            return "other"
        }
    }
    
    static internal func getProductTypeFromString(value : String?) -> ProductType {
        if (value != nil) {
            switch value!.lowercased() {
            case "red":
                return .RED
            case "white":
                return .WHITE
            case "rosé":
                return .ROSE
            case "fortified":
                return .FORTIFIED
            case "sparkling":
                return .SPARKLING
            default:
                return .OTHER
            }
        }
        
        return .OTHER
    }
    
    /// Is a specific prouduct  a wine?
    /// - Returns: true if the product type corresponds to a wine.
    public func isWine() -> Bool {
        return self == .RED || self == .WHITE || self == .ROSE || self == .SPARKLING || self == .FORTIFIED
    }
}
