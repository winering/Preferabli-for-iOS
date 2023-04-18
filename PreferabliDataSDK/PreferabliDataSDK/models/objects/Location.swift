//
//  Location.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 9/16/21.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//
//

import Foundation
import CoreData

/// A location (must have either a latitude / longitude or a zip code).
public class Location : BaseObject {
    
    public var latitude: NSNumber?
    public var longitude: NSNumber?
    public var zip_code: String?
    
    internal init(location : CoreData_Location) {
        latitude = location.latitude
        longitude = location.longitude
        zip_code = nil
        super.init(id: location.id)
    }
    
    internal init(zip_code : String) {
        latitude = nil
        longitude = nil
        self.zip_code = zip_code
        super.init(id: NSNumber.init(value: PreferabliTools.generateRandomLongId()))
    }
    
    internal init(latitude : NSNumber, longitude : NSNumber) {
        self.latitude = latitude
        self.longitude = longitude
        self.zip_code = nil
        super.init(id: NSNumber.init(value: PreferabliTools.generateRandomLongId()))
    }
}
