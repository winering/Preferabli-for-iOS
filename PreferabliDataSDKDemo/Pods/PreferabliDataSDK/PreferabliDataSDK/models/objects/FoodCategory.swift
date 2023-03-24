//
//  FoodCategory.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 9/22/21.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//
//

import Foundation
import CoreData

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
