//
//  Session.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 10/10/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation

internal class SessionData : BaseObject {
    
    internal var user_id : NSNumber?
    internal var customer_id : NSNumber?
    internal var token_access : String?
    internal var token_refresh : String?
    internal var intercom_hmac : String?

    internal init(map : [String : Any]) {
        user_id = map["user_id"] as? NSNumber
        customer_id = map["customer_id"] as? NSNumber
        token_access = map["token_access"] as? String
        token_refresh = map["token_refresh"] as? String
        intercom_hmac = map["intercom_hmac"] as? String
        super.init(id: map["id"] as? NSNumber ?? NSNumber.init(value: 0))
        saveSession()
    }

    internal func saveSession() {
        let defaults = PreferabliTools.getKeyStore()
        defaults.set(token_access, forKey: "access_token")
        defaults.set(token_refresh, forKey: "refresh_token")
        defaults.set(intercom_hmac, forKey: "intercom_hmac")
        Preferabli.api.refreshDefaults()
    }
}
