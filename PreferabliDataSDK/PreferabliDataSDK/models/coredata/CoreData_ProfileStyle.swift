//
//  CoreData_PreferenceStyle.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/6/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

@objc(CoreData_ProfileStyle)
internal class CoreData_ProfileStyle: NSManagedObject {
    
}

extension CoreData_ProfileStyle {
    @NSManaged internal var conflict: Bool
    @NSManaged internal var id: NSNumber
    @NSManaged internal var order_profile: NSNumber
    @NSManaged internal var order_recommend: NSNumber
    @NSManaged internal var rating: NSNumber
    @NSManaged internal var strength: NSNumber
    @NSManaged internal var style_id: NSNumber
    @NSManaged internal var recommend: Bool
    @NSManaged internal var refine: Bool
    @NSManaged internal var style: CoreData_Style
    @NSManaged internal var keywords: String?
    @NSManaged internal var created_at: Date
    @NSManaged internal var profile: CoreData_Profile
}
