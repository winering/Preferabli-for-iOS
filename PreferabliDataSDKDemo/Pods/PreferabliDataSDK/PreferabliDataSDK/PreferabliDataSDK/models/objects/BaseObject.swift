//
//  BaseObject.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 2/3/23.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation

/// Most of the Preferabli Data SDK classes inherit from this object.
public class BaseObject : Hashable {
    
    public var id: NSNumber
    
    internal init(id : NSNumber) {
        self.id = id
    }
    
    public static func == (lhs: BaseObject, rhs: BaseObject) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
}
