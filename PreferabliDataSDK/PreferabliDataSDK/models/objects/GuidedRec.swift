//
//  GuidedRec.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 10/10/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation

/// A Guided Rec questionnaire.
public class GuidedRec : BaseObject {
    
    /// The default wine questionnaire.
    public static let WINE_DEFAULT : NSNumber = 1
    
    public var name : String?
    public var default_currency : String?
    public var default_price_min : NSNumber?
    public var default_price_max : NSNumber?
    public var max_results_per_type : NSNumber?
    public var questions : [GuidedRecQuestion]

    internal init(map : [String : Any]) {
        name = map["name"] as? String
        default_currency = map["default_currency"] as? String
        default_price_min = map["default_price_min"] as? NSNumber
        default_price_max = map["default_price_max"] as? NSNumber
        questions = Array<GuidedRecQuestion>()
        for question in (map["questions"] as! NSArray) {
            questions.append(GuidedRecQuestion.init(map: question as! [String : Any]))
        }
        max_results_per_type = map["maximum_selected"] as? NSNumber
        super.init(id: map["id"] as? NSNumber ?? NSNumber.init(value: 0))
    }
}
