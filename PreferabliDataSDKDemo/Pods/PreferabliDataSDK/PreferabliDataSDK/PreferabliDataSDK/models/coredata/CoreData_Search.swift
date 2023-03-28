//
//  CoreData_Search.swift
//  PreferabliSDK
//
//  Created by Nicholas Bortolussi on 8/16/22.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CoreData_Search)
internal class CoreData_Search: NSManagedObject {

}


extension CoreData_Search {
    @NSManaged internal var count: NSNumber
    @NSManaged internal var last_searched: Date?
    @NSManaged internal var text: String?

}
