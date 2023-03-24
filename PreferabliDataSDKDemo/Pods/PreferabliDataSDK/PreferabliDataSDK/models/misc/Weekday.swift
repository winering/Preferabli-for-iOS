//
//  Weekday.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/8/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import UIKit

/// Represents a day of the week for use within ``VenueHour``.
public enum Weekday {
    case MONDAY
    case TUESDAY
    case WEDNESDAY
    case THURSDAY
    case FRIDAY
    case SATURDAY
    case SUNDAY
    case NONE

    static internal func getWeekdayFromString(weekday : String?) -> Weekday {
        if (weekday != nil) {
            switch weekday! {
            case "monday":
                return .MONDAY
            case "tuesday":
                return .TUESDAY
            case "wednesday":
                return .WEDNESDAY
            case "thursday":
                return .THURSDAY
            case "friday":
                return .FRIDAY
            case "saturday":
                return .SATURDAY
            case "sunday":
                return .SUNDAY
            default:
                return .NONE
            }
        }
        
        return NONE;
    }
    
    internal func getStringFromWeekday() -> String {
        switch self {
        case .MONDAY:
            return "monday"
        case .TUESDAY:
            return "tuesday"
        case .WEDNESDAY:
            return "wednesday"
        case .THURSDAY:
            return "thursday"
        case .FRIDAY:
            return "friday"
        case .SATURDAY:
            return "saturday"
        case .SUNDAY:
            return "sunday"
        case .NONE:
            return "none"
        }
    }
    
    public func compare(_ other: Weekday) -> ComparisonResult {
        return self.getStringFromWeekday().caseInsensitiveCompare(other.getStringFromWeekday())
    }
}
