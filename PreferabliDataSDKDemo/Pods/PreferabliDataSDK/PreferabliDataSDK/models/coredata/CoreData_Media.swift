//
//  CoreData_Media.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/14/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

@objc(CoreData_Media)
internal class CoreData_Media: NSManagedObject {

}

extension CoreData_Media {
    @NSManaged internal var created_at: Date?
    @NSManaged internal var id: NSNumber
    @NSManaged internal var path: String
    @NSManaged internal var type: String?
    @NSManaged internal var updated_at: Date?
}
