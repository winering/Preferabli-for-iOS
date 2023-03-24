//
//  Search.swift
//  PreferabliSDK
//
//  Created by Nicholas Bortolussi on 8/16/22.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//
//

import Foundation
import CoreData

internal class Search {
    
    internal var count: NSNumber
    internal var last_searched: Date?
    internal var text: String?
    
    internal init(text : String) {
        self.text = text
        self.count = 0
        self.last_searched = Date.init()
    }
    
    internal func getLastSearched() -> Date {
       if let last_searched = last_searched {
           return last_searched
       }
        
       return Date.init()
   }
    
    static internal func sortSearchesByLastSearched(searches : Array<Search>) -> [Search] {
        return searches.sorted {
            let date1 = $0.getLastSearched()
            let date2 = $1.getLastSearched()

            if (date1.compare(date2) == ComparisonResult.orderedSame) {
                return $0.count.compare($1.count) == ComparisonResult.orderedDescending
            }
            return date1.compare(date2) == ComparisonResult.orderedDescending
        }
    }
    
    static internal func sortSearchesByCount(searches : Array<Search>) -> [Search] {
        return searches.sorted {
            if ($0.count == $1.count) {
                let date1 = $0.getLastSearched()
                let date2 = $1.getLastSearched()
                return date1.compare(date2) == ComparisonResult.orderedDescending
            }
            
            return $0.count.compare($1.count) == ComparisonResult.orderedDescending
        }
    }
}
