//
//  GuidedRecQuestion.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 10/10/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation

/// A question within a ``GuidedRec`` quiz.
public class GuidedRecQuestion : BaseObject {
    
    public var number : NSNumber?
    public var choices : [GuidedRecChoice]
    public var type : String?
    public var minimum_selected : NSNumber?
    public var maximum_selected : NSNumber?
    public var text : String?

    internal init(map : [String : Any]) {
        number = map["number"] as? NSNumber
        choices = Array<GuidedRecChoice>()
        for choice in (map["choices"] as! NSArray) {
            choices.append(GuidedRecChoice.init(map: choice as! [String : Any]))
        }
        type = map["type"] as? String
        minimum_selected = map["minimum_selected"] as? NSNumber
        maximum_selected = map["maximum_selected"] as? NSNumber
        text = map["text"] as? String
        super.init(id: map["id"] as? NSNumber ?? NSNumber.init(value: 0))
    }
}
