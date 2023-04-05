//
//  ProductType.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/8/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import UIKit

/// The type of a ``Product``. Mainly for wines. Will be ``OTHER`` if not a wine.
public enum ProductType {
    case RED
    case WHITE
    case ROSE
    case SPARKLING
    case FORTIFIED
    /// Use other if product is a whiskey, tequila, or beer.
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
    
    /// Is this prouduct type a wine?
    /// - Returns: true if the product type corresponds to a wine.
    public func isWine() -> Bool {
        return self == .RED || self == .WHITE || self == .ROSE || self == .SPARKLING || self == .FORTIFIED
    }
}
