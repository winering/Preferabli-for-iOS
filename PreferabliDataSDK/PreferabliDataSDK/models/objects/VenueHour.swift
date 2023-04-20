//
//  VenueHour.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/18/21.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//
//

import Foundation
import CoreData

/// Represents a venue's open and close times for a given day. Each day of the week has separate corresponding values.
public class VenueHour : BaseObject {
    
    public var weekday: String?
    public var open_time: String?
    public var close_time: String?
    public var is_closed: Bool
    
    internal init(map : [String : Any]) {
        weekday = map["weekday"] as? String
        open_time = map["open_time"] as? String
        close_time = map["close_time"] as? String
        is_closed = map["is_closed"] as! Bool
        
        super.init(id: map["id"] as? NSNumber ?? NSNumber.init(value: 0))
    }
    
    internal init(venue_hour : CoreData_VenueHour) {
        weekday = venue_hour.weekday
        open_time = venue_hour.open_time
        close_time = venue_hour.close_time
        is_closed = venue_hour.is_closed
        super.init(id: venue_hour.id)
    }
    
    var day_of_week : Weekday {
        return Weekday.getWeekdayFromString(weekday: weekday)
    }
}
