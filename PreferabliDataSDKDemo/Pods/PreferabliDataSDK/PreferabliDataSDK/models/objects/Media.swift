//
//  Media.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/14/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData
import UIKit

/// An image or video.
public class Media : BaseObject {
    
    public var created_at: Date?
    public var path: String
    public var type: String?
    
    internal init(map : [String : Any]) {
        created_at = map["created_at"] as? Date
        path = map["path"] as! String
        type = map["type"] as? String
        super.init(id: map["id"] as? NSNumber ?? NSNumber.init(value: 0))
    }
    
    internal init(media : CoreData_Media) {
        created_at = media.created_at
        path = media.path
        type = media.type
        super.init(id: media.id)
    }
}
