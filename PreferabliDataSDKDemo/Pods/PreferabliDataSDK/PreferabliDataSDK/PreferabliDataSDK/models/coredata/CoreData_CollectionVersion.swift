//
//  CoreData_CollectionVersion.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/9/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

@objc(CoreData_CollectionVersion)
internal class CoreData_CollectionVersion: NSManagedObject {

}

extension CoreData_CollectionVersion {
    @NSManaged internal var id: NSNumber
    @NSManaged internal var name: String
    @NSManaged internal var order: NSNumber
    @NSManaged internal var collection: CoreData_Collection
    @NSManaged internal var groups: NSSet
}
