//
//  Customer.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 11/14/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation

/// A logged in merchant customer.
public class Customer : BaseObject {
    
    public var avatar_url: String?
    public var merchant_user_email_address: String?
    public var merchant_user_id: String?
    public var merchant_user_name: String?
    public var merchant_user_display_name: String?
    public var role: String?
    public var user_id: NSNumber?
    public var has_profile: Bool
    public var claim_code: String?
    public var ratings_collection_id: NSNumber

    internal init(map : [String : Any]) {
        avatar_url = map["avatar_url"] as? String
        merchant_user_email_address = map["merchant_user_email_address"] as? String
        merchant_user_id = map["merchant_user_id"] as? String
        merchant_user_name = map["merchant_user_name"] as? String
        merchant_user_display_name = map["merchant_user_display_name"] as? String
        role = map["role"] as? String
        user_id = map["user_id"] as? NSNumber
        has_profile = map["has_profile"] as? Bool ?? false
        claim_code = map["claim_code"] as? String
        ratings_collection_id = map["ratings_collection_id"] as! NSNumber
        super.init(id: map["id"] as? NSNumber ?? NSNumber.init(value: 0))
        PreferabliTools.getKeyStore().set(id, forKey: "customer_id")
        PreferabliTools.getKeyStore().set(merchant_user_email_address, forKey: "email")
        PreferabliTools.getKeyStore().set(ratings_collection_id, forKey: "ratings_id")
    }
    
    internal init(customer : CoreData_Customer) {
        avatar_url = customer.avatar_url
        merchant_user_email_address = customer.merchant_user_email_address
        merchant_user_id = customer.merchant_user_id
        merchant_user_name = customer.merchant_user_name
        merchant_user_display_name = customer.merchant_user_display_name
        role = customer.role
        user_id = customer.user_id
        has_profile = customer.has_profile
        claim_code = customer.claim_code
        ratings_collection_id = customer.ratings_collection_id
        super.init(id: customer.id)
    }
    
    /// Get a customer's display name.
    /// - Returns: the name as a string.
    public func getName() -> String {
        if (!PreferabliTools.isNullOrWhitespace(string: merchant_user_display_name)) {
            return merchant_user_display_name!
        } else if (!PreferabliTools.isNullOrWhitespace(string: merchant_user_name)) {
            return merchant_user_name!
        } else if (!PreferabliTools.isNullOrWhitespace(string: merchant_user_email_address)) {
            return merchant_user_email_address!
        } else if (!PreferabliTools.isNullOrWhitespace(string: merchant_user_id)) {
            return merchant_user_id!
        }
        
        return ""
    }
}
