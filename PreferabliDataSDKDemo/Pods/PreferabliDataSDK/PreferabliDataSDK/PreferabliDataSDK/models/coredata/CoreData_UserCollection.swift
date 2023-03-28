//
//  CoreData_UserCollection.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/21/18.
//  Copyright © 2018 Wine Ring. All rights reserved.
//
//

import Foundation
import CoreData


@objc(CoreData_UserCollection)
internal class CoreData_UserCollection: NSManagedObject {
    @NSManaged internal var collection_id: NSNumber
    @NSManaged internal var id: NSNumber
    @NSManaged internal var relationship_type: String
    @NSManaged internal var is_pinned: Bool
    @NSManaged internal var is_admin: Bool
    @NSManaged internal var is_editor: Bool
    @NSManaged internal var is_viewer: Bool
    @NSManaged internal var archived_at: Date?
    @NSManaged internal var created_at: Date?
    @NSManaged internal var updated_at: Date?
    @NSManaged internal var collection: CoreData_Collection?
}
