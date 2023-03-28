//
//  LabelRecResult.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 1/13/17.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

/// Returned by ``Preferabli/labelRecognition(image:include_merchant_links:onCompletion:onFailure:)``.
public class LabelRecResult {
    
    /// A score on a scale of 0 - 100 which represents how close of a match the supplied label is to the ``Product``.
    public var score: NSNumber
    public var product: Product
    
    internal init(score : NSNumber, product : Product) {
        self.score = score
        self.product = product
    }
}
