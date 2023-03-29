//
//  APIService.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 10/10/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import CoreData
import Alamofire

/// Internal class used for interacting with our API.
internal class APIService {
    
    private var alamo : SessionManager?
    private var urlCache : URLCache?
    
    /// Create Alamo class that interacts with our API.
    internal func createAlamo() {
        let defaults = PreferabliTools.getKeyStore()
                
        var headers: HTTPHeaders = ["client_interface" : defaults.string(forKey: "CLIENT_INTERFACE")!, "client_interface_version" : String(Preferabli.versionCode)]
                
        if let access_token = defaults.string(forKey: "access_token") {
            headers.updateValue("Bearer " + access_token, forKey: "Authorization")
        }
        if (Preferabli.loggingEnabled) {
            print(headers)
        }


        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = headers
        configuration.timeoutIntervalForRequest = 30
        let halfgig = 500 * 1024 * 1024
        urlCache = URLCache.init(memoryCapacity: halfgig, diskCapacity: halfgig, diskPath: "myDataPath")
        configuration.urlCache = urlCache
        configuration.requestCachePolicy = .useProtocolCachePolicy
        alamo = Alamofire.SessionManager(configuration: configuration)
        alamo!.adapter = LoggingAdapter.init(loggingEnabled: Preferabli.loggingEnabled)
    }

    internal func clearUrlCache() {
        urlCache?.removeAllCachedResponses()
    }
    
    internal func getAlamo() throws -> SessionManager {
        return try getAlamo(requiresAccessToken: true)
    }
    
    internal func getAlamo(requiresAccessToken : Bool) throws -> SessionManager {
        objc_sync_enter(Preferabli.api)
        defer { objc_sync_exit(Preferabli.api) }
        
        if (PreferabliTools.isNullOrWhitespace(string: PreferabliTools.getKeyStore().string(forKey: "CLIENT_INTERFACE"))) {
            throw PreferabliException.init(type: .InvalidClientInterface)
        }
        
        if (requiresAccessToken && PreferabliTools.isNullOrWhitespace(string: PreferabliTools.getKeyStore().string(forKey: "access_token"))) {
            throw PreferabliException.init(type: .InvalidAccessToken)
        }
        
        if (alamo == nil) {
            createAlamo()
        }
        
        return alamo!
    }
    
    internal func refreshDefaults() {
        objc_sync_enter(Preferabli.api)
        defer { objc_sync_exit(Preferabli.api) }
        
        alamo = nil
    }
}

private class LoggingAdapter: RequestAdapter {
    
    private let loggingEnabled : Bool
    
    internal init(loggingEnabled : Bool) {
        self.loggingEnabled = loggingEnabled
    }
    
    fileprivate func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        if (loggingEnabled) {
            if (urlRequest.urlRequest != nil) {
                print(urlRequest.urlRequest!.httpMethod ?? "")
                if (urlRequest.urlRequest!.url != nil) {
                    print(urlRequest.urlRequest!.url!.absoluteString)
                }
                if (urlRequest.urlRequest!.httpBody != nil) {
                    print(urlRequest.urlRequest!.httpBody ?? "")
                }
            }
        }
        return urlRequest
    }
}

/// These are our API routes.
internal struct APIEndpoints {
    internal static let baseUrl = "https://api.preferabli.com/api/6.1/"
    internal static let postSession = baseUrl + "sessions"
    internal static let getRec = baseUrl + "recs"
    internal static let styles = baseUrl + "styles"
    internal static let postMedia = baseUrl + "media"
    internal static let resetPassword = baseUrl + "resetpassword"
    internal static let users = baseUrl + "users"
    internal static let products = baseUrl + "products"
    internal static let search = baseUrl + "search"
    internal static let imageRec = baseUrl + "imagerec"
    internal static let lttt = baseUrl + "lttt"
    internal static let flttt = baseUrl + "flttt"
    internal static let foods = baseUrl + "foods"
    internal static let wheretobuy = baseUrl + "wheretobuy"

    internal static func integration(id : NSNumber) -> String {
        return baseUrl + "integrations/\(id)"
    }
    
    internal static func lookupConversion(id : NSNumber) -> String {
        return baseUrl + "integrations/\(id)/lookups"
    }
    
    internal static func lttt(id : Int) -> String {
        return baseUrl + "integration/\(id)/lttt"
    }
    
    internal static func customer(id : NSNumber, customerId : NSNumber) -> String {
        return baseUrl + "channels/\(id)/customers/\(customerId)"
    }

    internal static func guidedRec(id : Int) -> String {
        return baseUrl + "questionnaire/\(id)"
    }
    
    internal static func guidedRecResults() -> String {
        return baseUrl + "query"
    }
    
    internal static func guidedRecResults(id : Int) -> String {
        return baseUrl + "query?override_collection_ids[]=\(id)"
    }
    
    internal static func customerTags(id : NSNumber, and customerId : NSNumber) -> String {
        return baseUrl + "channels/\(id)/customers/\(customerId)/tags"
    }
    
    internal static func customerProfile(id : NSNumber, and customerId : NSNumber) -> String {
        return baseUrl + "channels/\(id)/customers/\(customerId)/profile?include_styles=false"
    }
    
    internal static func collection(id : NSNumber) -> String {
        return baseUrl + "collections/\(id)"
    }
    
    internal static func product(id : NSNumber) -> String {
        return baseUrl + "products/\(id)"
    }

    internal static func user(id : NSNumber) -> String {
        return baseUrl + "users/\(id)"
    }
    
    internal static func wili() -> String {
        return baseUrl + "wili"
    }
    
    internal static func tags(id : NSNumber) -> String {
        return baseUrl + "collections/\(id)/tags"
    }
    
    internal static func variants(product_id : NSNumber) -> String {
        return baseUrl + "products/\(product_id)/variants"
    }
    
    internal static func style(id : NSNumber) -> String {
        return baseUrl + "styles/\(id)"
    }
    
    internal static func channel(id : NSNumber) -> String {
        return baseUrl + "channels/\(id)"
    }
    
    internal static func tag(collectionId : NSNumber, tagId : NSNumber) -> String {
        return baseUrl + "collections/\(collectionId)/tags/\(tagId)"
    }
    
    internal static func groups(collectionId : NSNumber, versionId : NSNumber) -> String {
        return baseUrl + "collections/\(collectionId)/versions/\(versionId)/groups"
    }
    
    internal static func orderings(collectionId : NSNumber, versionId : NSNumber, groupId : NSNumber) -> String {
        return baseUrl + "collections/\(collectionId)/versions/\(versionId)/groups/\(groupId)/orderings"
    }
    
    internal static func ordering(collectionId : NSNumber, versionId : NSNumber, groupId : NSNumber, orderingId : NSNumber) -> String {
        return baseUrl + "collections/\(collectionId)/versions/\(versionId)/groups/\(groupId)/orderings/\(orderingId)"
    }
    
    internal static func variant(product_id : NSNumber, variant_id : NSNumber) -> String {
        return baseUrl + "products/\(product_id)/variants/\(variant_id)"
    }
    
    internal static func customerTag(id : NSNumber, customerId : NSNumber, tagId : NSNumber) -> String {
        return baseUrl + "channels/\(id)/customers/\(customerId)/tags/\(tagId)"
    }
    
    internal static func customerTags(id : Int, customerId : NSNumber) -> String {
           return baseUrl + "channels/\(id)/customers/\(customerId)/tags"
    }
    
    internal static func userCollections(id : NSNumber) -> String {
        return baseUrl + "users/\(id)/usercollections"
    }
    
    internal static func userCollection(id : NSNumber, userCollectionId : NSNumber) -> String {
        return baseUrl + "users/\(id)/usercollections/\(userCollectionId)"
    }
    
    internal static func profile(id : NSNumber) -> String {
        return baseUrl + "users/\(id)/profile?include_styles=false"
    }
    
    internal static func userTags(id : NSNumber) -> String {
        return baseUrl + "users/\(id)/tags"
    }

    internal static func userTag(id : NSNumber, tagId : NSNumber) -> String {
        return baseUrl + "users/\(id)/tags/\(tagId)"
    }
}
