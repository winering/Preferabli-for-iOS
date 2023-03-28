//
//  CoreData_CollectionTrait.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/12/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

@objc(CoreData_CollectionTrait)
internal class CoreData_CollectionTrait: NSManagedObject {

}

extension CoreData_CollectionTrait {
    @NSManaged internal var id: NSNumber
    @NSManaged internal var name: String
    @NSManaged internal var order: NSNumber
    @NSManaged internal var restrict_to_ring_it: Bool
}
