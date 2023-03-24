//
//  GuidedRecChoice.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 10/10/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation

/// A choice within a ``GuidedRecQuestion``. Pass an array of these to get results from ``Preferabli/getGuidedRecResults(selected_choice_ids:price_min:price_max:collection_id:onCompletion:onFailure:)``.
public class GuidedRecChoice : BaseObject {

    public var number : NSNumber
    public var requires_choice_ids : [NSNumber]?
    public var text : String?
    
    internal init(map : [String : Any]) {
        number = map["number"] as! NSNumber
        requires_choice_ids = map["requires_choice_ids"] as? [NSNumber]
        text = map["text"] as? String
        super.init(id: map["id"] as? NSNumber ?? NSNumber.init(value: 0))
    }
}
