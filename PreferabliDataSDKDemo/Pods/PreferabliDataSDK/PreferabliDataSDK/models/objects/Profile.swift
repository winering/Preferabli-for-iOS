//
//  Profile.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 12/27/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData

/// A user's preference profile contains information on what a user likes and dislikes.
public class Profile : BaseObject {
    
    public var user_id: NSNumber
    public var customer_id: NSNumber
    
    /// A score that represents how developed a profile is.
    public var score: NSNumber
    public var preference_styles: [PreferenceStyle]
    
    internal init(profile : CoreData_Profile) {
        user_id = profile.user_id
        customer_id = profile.customer_id
        score = profile.score
        preference_styles = Array<PreferenceStyle>()
        super.init(id: profile.id)
        for preference_style in profile.preference_styles.allObjects as! [CoreData_PreferenceStyle] {
            preference_styles.append(PreferenceStyle.init(preference_style: preference_style, holding_profile: self))
        }
    }
}
