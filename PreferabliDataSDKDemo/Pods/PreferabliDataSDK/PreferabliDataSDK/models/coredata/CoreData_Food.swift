//
//  CoreData_Food.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/7/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

@objc(CoreData_Food)
internal class CoreData_Food: NSManagedObject {

}

extension CoreData_Food {
    @NSManaged internal var id: NSNumber
    @NSManaged internal var name: String
    @NSManaged internal var desc: String
    @NSManaged internal var keywords: String?
    @NSManaged internal var styles: NSSet
    @NSManaged internal var food_category_id: NSNumber?
    @NSManaged internal var food_category_name: String?
    @NSManaged internal var food_category_url: String?
}
