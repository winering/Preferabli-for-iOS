//
//  Food.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/7/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

/// You can use foods to get pairings within ``Preferabli/getRecs(product_category:product_type:collection_id:price_min:price_max:style_ids:food_ids:include_merchant_links:onCompletion:onFailure:)``.
public class Food: BaseObject {
    
    public var name: String
    public var desc: String
    public var keywords: String?
    public var food_category_id: NSNumber?
    public var food_category_name: String?
    internal var food_category_url: String?
    
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
    
    /// Get the food's image.
    /// - Parameters:
    ///   - width: returns an image with the specified width in pixels.
    ///   - height: returns an image with the specified height in pixels.
    ///   - quality: returns an image with the specified quality. Scales from 0 - 100.
    /// - Returns: the URL of the requested image.
    public func getImage(width : CGFloat, height : CGFloat, quality : Int = 80) -> URL? {
        return PreferabliTools.getImageUrl(image: food_category_url, width: width, height: height, quality: quality)
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

internal class FoodCategory : BaseObject {
    
    internal var name: String
    internal var icon_url: String?
    
    internal init(food_category : CoreData_FoodCategory) {
        name = food_category.name
        icon_url = food_category.icon_url
        super.init(id: food_category.id)
    }
    
    static internal func sortFoodCats(foodCats: [FoodCategory]) -> Array<FoodCategory> {
        return foodCats.sorted {
            return $0.name.caseInsensitiveCompare($1.name) == ComparisonResult.orderedAscending
        }
    }
}
