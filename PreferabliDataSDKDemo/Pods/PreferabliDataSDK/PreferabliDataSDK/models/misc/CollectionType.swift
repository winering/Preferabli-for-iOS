//
//  CollectionType.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/8/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import UIKit

/// The type of a ``Collection``.
public enum CollectionType {
    case EVENT
    case INVENTORY
    case CELLAR
    case OTHER
    
    static internal func getCollectionTypeBasedOffCollection(collection : Collection) -> CollectionType {
        if (collection.is_my_cellar) {
            return .CELLAR
        } else if (collection.isEvent()) {
            return .EVENT
        } else if (collection.isInventory()) {
            return .INVENTORY
        }
        
        return .OTHER
    }
}
