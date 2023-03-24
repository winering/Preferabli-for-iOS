//
//  CoreData_FoodCategory.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 9/22/21.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CoreData_FoodCategory)
internal class CoreData_FoodCategory: NSManagedObject {
    @NSManaged internal var id: NSNumber
    @NSManaged internal var name: String
    @NSManaged internal var icon_url: String?
    @NSManaged internal var styles: NSSet?
}
