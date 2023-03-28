//
//  DataResponseExt.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 1/23/18.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import Alamofire

extension DataResponse {
    internal func isNotCached() -> Bool {
        var eTag = response!.allHeaderFields["ETag"] as? String
        if (PreferabliTools.isNullOrWhitespace(string: eTag)) {
            eTag = response!.allHeaderFields["Etag"] as? String
        }
        let isEtagged = PreferabliTools.isNullOrWhitespace(string: eTag) || PreferabliTools.getKeyStore().string(forKey: "etag " + request!.url!.absoluteString) != eTag
        PreferabliTools.getKeyStore().set(eTag, forKey: "etag " + request!.url!.absoluteString)
        return isEtagged
    }
}
