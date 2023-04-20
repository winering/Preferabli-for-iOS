//
//  Food.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/7/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

/// You can use foods to get pairings within <doc:Get-Recs>.
public class Food: BaseObject {
    
    public var name: String
    public var desc: String
    public var keywords: String?
    public var food_category_id: NSNumber?
    public var food_category_name: String?
    public var food_category_url: String?
    
    internal init(food : CoreData_Food) {
        name = food.name
        desc = food.desc
        keywords = food.keywords
        food_category_id = food.food_category_id
        food_category_name = food.food_category_name
        food_category_url = food.food_category_url
        super.init(id: food.id)
    }
    
    /// Sort foods alphabetically.
    /// - Parameter foods: an array of foods to be sorted.
    /// - Returns: a sorted array of foods.
    static public func sortFoodsAlpha(foods: [Food]) -> Array<Food> {
        return foods.sorted {
            return $0.name.caseInsensitiveCompare($1.name) == ComparisonResult.orderedAscending
        }
    }
    
    /// Filter foods by submitted search terms.
    /// - Parameters:
    ///   - foods: an array of foods to be filtered.
    ///   - search_text: string that contains the search term.
    /// - Returns: a filtered array of foods.
    static public func filterFoods(foods : Array<Food>, search_text : String) -> Array<Food> {
        var filteredFoods = Array<Food>()
        if (search_text.isEmptyOrWhitespace()) {
            filteredFoods = foods
        } else {
            let searchTerms = search_text.components(separatedBy: " ")
            filteredFoods = foods.filter() {
                innerloop:
                    for searchTerm in searchTerms {
                        if ($0.filterFood(search_term: searchTerm)) {
                            continue
                        } else {
                            return false
                        }
                }
                return true
            }
        }
        return filteredFoods
    }
    
     internal func filterFood(search_term : String) -> Bool {
        if (search_term.isEmptyOrWhitespace()) {
            return true
        } else if (name.containsIgnoreCase(search_term)) {
            return true
        } else if (keywords?.containsIgnoreCase(search_term) ?? false) {
            return true
        } else {
            return false
        }
    }
}
