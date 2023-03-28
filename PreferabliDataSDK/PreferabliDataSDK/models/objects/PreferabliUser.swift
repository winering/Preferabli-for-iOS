//
//  PreferabliUser.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/14/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation

/// A logged in Preferabli user.
public class PreferabliUser : BaseObject {
    
    public var account_level: NSNumber?
    public var birthyear: NSNumber?
    public var country: String?
    public var display_name: String?
    public var email: String?
    public var is_team_ringit: Bool
    public var fname: String?
    public var gender: String?
    public var lname: String?
    public var location: String?
    public var claim_code: String?
    public var subscribed: Bool?
    public var zip_code: String?
    public var avatar: Media?
    public var rating_collection_id: NSNumber?
    public var wishlist_collection_id: NSNumber?
    
    internal var has_kiosks: Bool?
    internal var has_merchant_access: Bool
    internal var provided_feedback_at : String?
    internal var intercom_hmac : String?
    internal var admin: Int32
    
    internal init(map : [String : Any]) {
        account_level = map["account_level"] as? NSNumber
        birthyear = map["birthyear"] as? NSNumber
        rating_collection_id = map["rating_collection_id"] as? NSNumber
        wishlist_collection_id = map["wishlist_collection_id"] as? NSNumber
        country = map["country"] as? String
        display_name = map["display_name"] as? String
        email = map["email"] as? String
        fname = map["fname"] as? String
        gender = map["gender"] as? String
        lname = map["lname"] as? String
        location = map["location"] as? String
        claim_code = map["claim_code"] as? String
        zip_code = map["zip_code"] as? String
        is_team_ringit = map["is_team_ringit"] as! Bool
        subscribed = map["subscribed"] as? Bool
        has_kiosks = map["has_kiosks"] as? Bool
        has_merchant_access = map["has_merchant_access"] as! Bool
        provided_feedback_at = map["provided_feedback_at"] as? String
        intercom_hmac = map["intercom_hmac"] as? String
        admin = map["admin"] as! Int32
        super.init(id: map["id"] as? NSNumber ?? NSNumber.init(value: 0))
        PreferabliTools.setUserProperties(user: self)
    }
    
    /// Get the path to the user's avatar.
    /// - Returns: a string path.
    public func getImage() -> String {
        return avatar?.path ?? ""
    }
    
    /// Is the user an admin?
    /// - Returns: returns true if an admin.
    internal func isAdmin() -> Bool {
        return admin == 1
    }
}
