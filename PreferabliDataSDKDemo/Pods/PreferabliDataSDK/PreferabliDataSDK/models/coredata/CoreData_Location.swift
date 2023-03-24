//
//  CoreData_Location.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 9/16/21.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CoreData_Location)
internal class CoreData_Location: NSManagedObject {

}

extension CoreData_Location {
    @NSManaged internal var id: NSNumber
    @NSManaged internal var latitude: NSNumber
    @NSManaged internal var longitude: NSNumber
    @NSManaged internal var style: CoreData_Style?
}
