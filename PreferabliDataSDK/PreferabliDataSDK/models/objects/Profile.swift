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
    internal var score: NSNumber
    public var profile_styles: [ProfileStyle]
    
    internal init(profile : CoreData_Profile) {
        user_id = profile.user_id
        customer_id = profile.customer_id
        score = profile.score
        profile_styles = Array<ProfileStyle>()
        super.init(id: profile.id)
        for profile_style in profile.preference_styles.allObjects as! [CoreData_ProfileStyle] {
            profile_styles.append(ProfileStyle.init(profile_style: profile_style, holding_profile: self))
        }
    }
}
