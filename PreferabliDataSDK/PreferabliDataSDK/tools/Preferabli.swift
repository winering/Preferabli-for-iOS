//
//  Preferabli.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 5/20/20.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import UIKit
import MagicalRecord
import CoreData
import SwiftEventBus
import Mixpanel
import Alamofire

/// This is the primary class you will utilize to access the Preferabli Data SDK.
public class Preferabli {
    
    /// Use this instance to make Preferabli API calls.
    public static var main = Preferabli()
    
    internal static var loggingEnabled = false
    internal static var versionCode = 12
    internal static let api = APIService()
    internal static var hasBeenInitialized = false
    internal static var startupThreadRunning = false
    internal static var wiliDictionary = [NSNumber : Bool]()
    
    /// The primary inventory id of your integration.
    public static var PRIMARY_INVENTORY_ID : NSNumber = NSNumber.init(value: PreferabliTools.getKeyStore().integer(forKey: "PRIMARY_INVENTORY_ID"))
    /// The channel id of your integration.
    public static var CHANNEL_ID : NSNumber = NSNumber.init(value: PreferabliTools.getKeyStore().integer(forKey: "CHANNEL_ID"))
    /// The  id of your integration.
    public static var INTEGRATION_ID : NSNumber = NSNumber.init(value: PreferabliTools.getKeyStore().integer(forKey: "INTEGRATION_ID"))
    
    private init() {} // This prevents others from using the default '()' initializer for this class.
    
    /// Call this in your App Delegate's didFinishLaunchingWithOptions with your supplied information. Contact us if you do not have your **client_interface** and/or **integration_id**.
    /// - Parameters:
    ///   - client_interface: your unique identifier - provided by Preferabli.
    ///   - integration_id: your integration id - provided by Preferabli. You may have more than one integration for different segments of your business (depending on how your account is set up).
    ///   - logging_enabled: pass true for full logging. Defaults to *false*.
    static public func initialize(client_interface: String, integration_id : NSNumber, logging_enabled : Bool = false) {
        hasBeenInitialized = true
        loggingEnabled = logging_enabled
        
        INTEGRATION_ID = integration_id
        
        PreferabliTools.getKeyStore().set(integration_id, forKey: "INTEGRATION_ID")
        PreferabliTools.getKeyStore().set(client_interface, forKey: "CLIENT_INTERFACE")
        api.createAlamo()
        
        PreferabliTools.setupCoreDataStack()
        PreferabliTools.handleUpgrade()
        
        Mixpanel.initialize(token: "ff8f35c4aa7d67838380626736c19066", trackAutomaticEvents: false, instanceName: "PreferabliDataSDK")
        Mixpanel.mainInstance().registerSuperProperties(["CLIENT_INTERFACE" : client_interface, "INTEGRATION_ID" : integration_id])
        
        PreferabliTools.setupAnalyticsListeners()
        PreferabliTools.addSDKProperties()
        
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            handleStartupActions()
        })
    }
    
    private static func handleStartupActions() {
        do {
            startupThreadRunning = true
            try createAnonymousSession()
            try getIntegration()
            startupThreadRunning = false
            Preferabli.main.loadUserData()
        } catch {
            // Don't worry about it here but it will be checked and run before any calls to SDK can be made.
            startupThreadRunning = false
        }
    }
    
    private func loadUserData() {
        if (Preferabli.isPreferabliUserLoggedIn() || Preferabli.isCustomerLoggedIn()) {
            PreferabliTools.startNewWorkThread(priority: .normal, {
                Preferabli.main.getProfileActual()
                Preferabli.main.getRatedProducts(include_merchant_links: false, priority: .normal)
                //                    Preferabli.main.getWishlistProducts()
                Preferabli.main.getPurchasedProducts(include_merchant_links: false, priority: .normal)
            })
        }
    }
    
    private static func createAnonymousSession() throws {
        if (PreferabliTools.isNullOrWhitespace(string: PreferabliTools.getKeyStore().string(forKey: "access_token"))) {
            let sessionParameters =  ["login_as_anonymous" : true]
            var sessionResponse = try Preferabli.api.getAlamo(requiresAccessToken: false).post(APIEndpoints.postSession, json: sessionParameters)
            sessionResponse = try PreferabliTools.continueOrThrowPreferabliException(response: sessionResponse)
            _ = SessionData(map: try PreferabliTools.continueOrThrowJSONException(data: sessionResponse.data!) as! [String : Any])
        }
    }
    
    private static func getIntegration() throws {
        do {
            let integration_id = Preferabli.INTEGRATION_ID
            var integrationResponse = try Preferabli.api.getAlamo().get(APIEndpoints.integration(id: integration_id))
            integrationResponse = try PreferabliTools.continueOrThrowPreferabliException(response: integrationResponse)
            let integrationDictionary = try PreferabliTools.continueOrThrowJSONException(data: integrationResponse.data!) as! [String : Any]
            CHANNEL_ID = integrationDictionary["channel_id"] as! NSNumber
            PRIMARY_INVENTORY_ID = integrationDictionary["primary_collection_id"] as! NSNumber
            PreferabliTools.getKeyStore().set(CHANNEL_ID, forKey: "CHANNEL_ID")
            PreferabliTools.getKeyStore().set(PRIMARY_INVENTORY_ID, forKey: "PRIMARY_INVENTORY_ID")
            
        } catch {
            if let PreferabliException = error as? PreferabliException {
                if (PreferabliException.getCode() != 0) {
                    throw type(of: PreferabliException).init(type: .InvalidIntegrationId)
                }
            }
            throw error
        }
    }
    
    /// Will let you know if a user is logged in or not.
    /// - Returns: bool
    static public func isPreferabliUserLoggedIn() -> Bool {
        return PreferabliTools.isPreferabliUserLoggedIn()
    }
    
    /// Will let you know if a customer is logged in or not.
    /// - Returns: bool
    static public func isCustomerLoggedIn() -> Bool {
        return PreferabliTools.isCustomerLoggedIn()
    }
    
    /// Will get you the collection id of your integration's primary inventory.
    /// - Returns: collection id
    static public func getPrimaryInventoryId() -> NSNumber {
        return NSNumber.init(value: PreferabliTools.getKeyStore().integer(forKey: "PRIMARY_INVENTORY_ID"))
    }
    
    /// Get the Powered By Preferabli logo for use in your app.
    /// - Parameter light_background: pass true if you want the version suitable for a light background. Pass false for the dark background version.
    /// - Returns: Powered By Preferabli logo.
    static public func getPoweredByPreferabliLogo(light_background : Bool) -> UIImage {
        return UIImage.init(named: light_background ? "powered_by_light_bg.png" : "powered_by_dark_bg.png", in: Bundle.init(for: Preferabli.self), compatibleWith: nil)!
    }
    
    private func canWeContinue(needsToBeLoggedIn : Bool) throws {
        if (!Preferabli.hasBeenInitialized) {
            throw PreferabliException.init(type: .InvalidClientInterface)
        } else if (!PreferabliTools.isKeyPresentInKeyStore(key: "access_token") && !Preferabli.startupThreadRunning) {
            Preferabli.handleStartupActions()
            try canWeContinue(needsToBeLoggedIn: needsToBeLoggedIn)
        } else if (!PreferabliTools.isKeyPresentInKeyStore(key: "access_token")) {
            Thread.sleep(forTimeInterval: 1)
            try canWeContinue(needsToBeLoggedIn: needsToBeLoggedIn)
        } else if (!PreferabliTools.isKeyPresentInKeyStore(key: "CHANNEL_ID") && !Preferabli.startupThreadRunning) {
            Preferabli.handleStartupActions()
            try canWeContinue(needsToBeLoggedIn: needsToBeLoggedIn)
        } else if (!PreferabliTools.isKeyPresentInKeyStore(key: "CHANNEL_ID")) {
            Thread.sleep(forTimeInterval: 1)
            try canWeContinue(needsToBeLoggedIn: needsToBeLoggedIn)
        } else if (needsToBeLoggedIn && !PreferabliTools.isPreferabliUserLoggedIn() && !PreferabliTools.isCustomerLoggedIn()) {
            throw PreferabliException.init(type: .InvalidAccessToken)
        } else if (needsToBeLoggedIn && PreferabliTools.isLoggedOutOrLoggingOut()) {
            throw PreferabliException.init(type: .InvalidAccessToken)
        }
    }
    
    private func handleError(error : Error, onFailure: @escaping (PreferabliException) -> ()) {
        let wrError = error as? PreferabliException ?? PreferabliException.init(error: error)
        
        if (Preferabli.loggingEnabled) {
            print(wrError.getMessage())
        }
        DispatchQueue.main.async {
            onFailure(wrError)
        }
    }
    
    /// Link an existing customer or create a new one if they are not in our system.
    /// - Parameters:
    ///   - merchant_customer_identification: unique identifier for your customer. Usually an email address or a phone number.
    ///   - merchant_customer_verification: authentication key given to you by your API.
    ///   - onCompletion: returns ``Customer`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func loginCustomer(merchant_customer_identification : String, merchant_customer_verification : String, onCompletion: @escaping (Customer) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            self.loginCustomerActual(merchant_customer_identification: merchant_customer_identification, merchant_customer_verification: merchant_customer_verification, onCompletion: onCompletion, onFailure: onFailure)
        })
    }
    
    private func loginCustomerActual(merchant_customer_identification : String, merchant_customer_verification : String, onCompletion: @escaping (Customer) -> (), onFailure: @escaping (PreferabliException) -> ()) {
        do {
            try canWeContinue(needsToBeLoggedIn: false)
            
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "login_customer"])
            
            let parameters = ["merchant_customer_identification": merchant_customer_identification, "merchant_customer_verification" : merchant_customer_verification, "merchant_channel_id" : Preferabli.CHANNEL_ID] as [String : Any]
            
            var sessionResponse = try Preferabli.api.getAlamo(requiresAccessToken: false).post(APIEndpoints.postSession, json: parameters)
            sessionResponse = try PreferabliTools.continueOrThrowPreferabliException(response: sessionResponse)
            let session = SessionData(map: try PreferabliTools.continueOrThrowJSONException(data: sessionResponse.data!) as! [String : Any])
            
            var customerResponse = try Preferabli.api.getAlamo().get(APIEndpoints.customer(id: Preferabli.CHANNEL_ID, customerId: session.customer_id!))
            customerResponse = try PreferabliTools.continueOrThrowPreferabliException(response: customerResponse)
            let customerDictionary = try PreferabliTools.continueOrThrowJSONException(data: customerResponse.data!) as! [String : Any]
            let customerData = Customer(map: customerDictionary)
            
            DispatchQueue.main.async {
                onCompletion(customerData)
            }
            
            loadUserData()
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
    
    /// Login an existing Preferabli user.
    /// - Parameters:
    ///   - email: user's email address.
    ///   - password: user's password.
    ///   - onCompletion: returns ``PreferabliUser`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func loginPreferabliUser(email : String, password : String, onCompletion: @escaping (PreferabliUser) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            self.loginPreferabliUserActual(email: email, password: password, onCompletion: onCompletion, onFailure: onFailure)
        })
    }
    
    private func loginPreferabliUserActual(email : String, password : String, onCompletion: @escaping (PreferabliUser) -> (), onFailure: @escaping (PreferabliException) -> ()) {
        do {
            try canWeContinue(needsToBeLoggedIn: false)
            
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "login_user"])
            
            let context = NSManagedObjectContext.mr_()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            let parameters = ["email": email, "password" : password]
            
            var sessionResponse = try Preferabli.api.getAlamo(requiresAccessToken: false).post(APIEndpoints.postSession, json: parameters)
            sessionResponse = try PreferabliTools.continueOrThrowPreferabliException(response: sessionResponse)
            let session = SessionData(map: try PreferabliTools.continueOrThrowJSONException(data: sessionResponse.data!) as! [String : Any])
            
            var userResponse = try Preferabli.api.getAlamo().get(APIEndpoints.user(id: session.user_id!))
            userResponse = try PreferabliTools.continueOrThrowPreferabliException(response: userResponse)
            let userDictionary = try PreferabliTools.continueOrThrowJSONException(data: userResponse.data!) as! [String : Any]
            
            let userData = PreferabliUser(map: userDictionary)
            _ = CoreData_PreferabliUser.mr_import(from: userDictionary, in: context)
            
            context.mr_saveToPersistentStoreAndWait()
            
            DispatchQueue.main.async {
                onCompletion(userData)
            }
            
            loadUserData()
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
    
    /// Signup a new Preferabli user.
    /// - Parameters:
    ///   - email: user's email address.
    ///   - password: user's password.
    ///   - user_claim_code: use if the user has previous ratings tied to a claim code. Defaults to *nil*.
    ///   - cellar_name: changes the name of the user's default first cellar. Defaults to *nil*.
    ///   - onCompletion: returns ``PreferabliUser`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func signupPreferabliUser(email : String, password : String, user_claim_code : String? = nil, cellar_name : String? = nil, onCompletion: @escaping (PreferabliUser) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            self.signupPreferabliUserActual(email: email, password: password, user_claim_code: user_claim_code,  cellar_name: cellar_name, onCompletion: onCompletion, onFailure: onFailure)
        })
    }
    
    private func signupPreferabliUserActual(email : String, password : String, user_claim_code : String?, cellar_name : String?, onCompletion: @escaping (PreferabliUser) -> (), onFailure: @escaping (PreferabliException) -> ()) {
        do {
            try canWeContinue(needsToBeLoggedIn: false)
            
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "signup_user"])
            
            let context = NSManagedObjectContext.mr_()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            var parameters = ["email": email, "password" : password, "subscribed" : 1] as [String : Any]
            if (!PreferabliTools.isNullOrWhitespace(string: user_claim_code)) {
                parameters["use_user_claim_code"] = user_claim_code
            }
            if (!PreferabliTools.isNullOrWhitespace(string: cellar_name)) {
                parameters["cellar_name"] = cellar_name
            }
            
            var userResponse = try Preferabli.api.getAlamo().post(APIEndpoints.users, json: parameters)
            userResponse = try PreferabliTools.continueOrThrowPreferabliException(response: userResponse)
            let userDictionary = try PreferabliTools.continueOrThrowJSONException(data: userResponse.data!) as! [String : Any]
            
            let userData = PreferabliUser(map: userDictionary)
            _ = CoreData_PreferabliUser.mr_import(from: userDictionary, in: context)
            
            context.mr_saveToPersistentStoreAndWait()
            
            DispatchQueue.main.async {
                onCompletion(userData)
            }
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
    
    /// Logout a customer / Preferabli user.
    /// - Parameters:
    ///   - onCompletion: returns if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func logout(onCompletion: @escaping () -> () = { }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            self.logoutActual(onCompletion: onCompletion, onFailure: onFailure)
        })
    }
    
    private func logoutActual(onCompletion: @escaping () -> (), onFailure: @escaping (PreferabliException) -> ()) {
        do {
            try canWeContinue(needsToBeLoggedIn: true)
            
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "logout"])
            
            PreferabliTools.logout()
            
            DispatchQueue.main.async {
                onCompletion()
            }
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
    
    /// Resets the password of an existing Preferabli user.
    /// - Parameters:
    ///   - email: user's email address.
    ///   - onCompletion: returns if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func forgotPassword(email : String, onCompletion: @escaping () -> () = { }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            self.forgotPasswordActual(email: email, onCompletion: onCompletion, onFailure: onFailure)
        })
    }
    
    private func forgotPasswordActual(email : String, onCompletion: @escaping () -> (), onFailure: @escaping (PreferabliException) -> ()) {
        do {
            try canWeContinue(needsToBeLoggedIn: false)
            
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "forgot_password"])
            
            let parameters = ["email": email]
            
            var forgotResponse = try Preferabli.api.getAlamo(requiresAccessToken: false).get(APIEndpoints.resetPassword, params: parameters)
            forgotResponse = try PreferabliTools.continueOrThrowPreferabliException(response: forgotResponse)
            
            DispatchQueue.main.async {
                onCompletion()
            }
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
    
    /// Performs label recognition on a supplied image. Returns any ``Product`` matches.
    /// - Parameters:
    ///   - image: label image you want to search for.
    ///   - include_merchant_links: pass true if you want the results to include an array of ``MerchantProductLink`` embedded in ``Variant``. These connect Preferabli products to your own. Passing true requires additional resources and therefore will take longer. Defaults to *true*.
    ///   - onCompletion: returns ``Media``, \[``LabelRecResult``\] if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func labelRecognition(image : UIImage, include_merchant_links: Bool = true, onCompletion: @escaping (Media, [LabelRecResult]) -> () = {_,_  in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            self.labelRecognitionActual(image: image, include_merchant_links: include_merchant_links, onCompletion: onCompletion, onFailure: onFailure)
        })
    }
    
    private func labelRecognitionActual(image : UIImage, include_merchant_links: Bool, onCompletion: @escaping (Media, [LabelRecResult]) -> (), onFailure: @escaping (PreferabliException) -> ()) {
        do {
            try canWeContinue(needsToBeLoggedIn: false)
            
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "label_rec"])
            
            let context = NSManagedObjectContext.mr_()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            let resizedImage = PreferabliTools.resizeImage(image: image, newDimension: 1000)!
            let imageData = resizedImage.jpegData(compressionQuality: 0.60)!
            var mediaResponse = try Preferabli.api.getAlamo().syncUpload(url: APIEndpoints.postMedia, data: imageData)
            mediaResponse = try PreferabliTools.continueOrThrowPreferabliException(response: mediaResponse)
            let imageDictionary = try PreferabliTools.continueOrThrowJSONException(data: mediaResponse.data!)
            let cdMedia = CoreData_Media.mr_import(from: imageDictionary, in: context)
            let media = Media.init(media: cdMedia)
            
            var imageRecResponse = try Preferabli.api.getAlamo().get(APIEndpoints.imageRec, params: ["media_id" : media.id])
            imageRecResponse = try PreferabliTools.continueOrThrowPreferabliException(response: imageRecResponse)
            let imageRecDictionaries = try PreferabliTools.continueOrThrowJSONException(data: imageRecResponse.data!) as! Array<[String : Any]>
            var labelRecResults = Array<LabelRecResult>()
            var productsToReturn = Array<Product>()
            for imageRec in imageRecDictionaries {
                let product = CoreData_Product.mr_import(from: imageRec["product"] as Any, in: context)
                let actualProduct = Product.init(product: product)
                productsToReturn.append(actualProduct)
                let labelRecResult = LabelRecResult.init(score: imageRec["score"] as! NSNumber, product: actualProduct)
                labelRecResults.append(labelRecResult)
            }
            
            context.mr_saveToPersistentStoreAndWait()
            
            if (include_merchant_links) {
                try addMerchantDataToProducts(products: productsToReturn)
            }
            
            DispatchQueue.main.async {
                onCompletion(media, labelRecResults)
            }
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
    
    /// Search for a ``Product``.
    /// - Parameters:
    ///   - query: your search query.
    ///   - lock_to_integration: pass true if you only want to draw results from your integration. Defaults to *false*.
    ///   - product_categories: pass any ``ProductCategory`` that you would like the results to conform to. Pass *nil* for all results. Defaults to *nil*.
    ///   - product_types: pass any ``ProductType`` that you would like the results to conform to. Pass *nil* for all results. Defaults to *nil*.
    ///   - include_merchant_links: pass true if you want the results to include an array of ``MerchantProductLink`` embedded in ``Variant``. These connect Preferabli products to your own. Passing true requires additional resources and therefore will take longer. Defaults to *true*.
    ///   - onCompletion: returns an array of ``Product`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func searchProducts(query : String, lock_to_integration : Bool = false, product_categories : [ProductCategory]? = nil, product_types : [ProductType]? = nil, include_merchant_links: Bool = true, onCompletion: @escaping ([Product]) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            self.searchProductsActual(query: query, lock_to_integration: lock_to_integration, product_categories: product_categories, product_types: product_types, include_merchant_links: include_merchant_links, onCompletion: onCompletion, onFailure: onFailure)
        })
    }
    
    private func searchProductsActual(query : String, lock_to_integration : Bool, product_categories : [ProductCategory]?, product_types : [ProductType]?, include_merchant_links: Bool, onCompletion: @escaping ([Product]) -> (), onFailure: @escaping (PreferabliException) -> ()) {
        do {
            try canWeContinue(needsToBeLoggedIn: false)
            
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "search_products"])
            
            var dictionary: [String : Any] = ["search" : query , "search_types" : ["products"]]
            if (lock_to_integration) {
                dictionary["channel_id"] = Preferabli.CHANNEL_ID
                dictionary["search_types"] = ["tags"]
            }
            
            if (product_types != nil) {
                var types = Array<String>()
                var categories = Array<String>()
                for productType in product_types! {
                    if (productType == .RED) {
                        types.append(productType.getTypeName())
                    } else if (productType == .WHITE) {
                        types.append(productType.getTypeName())
                    } else if (productType == .ROSE) {
                        types.append(productType.getTypeName())
                    } else if (productType == .SPARKLING) {
                        types.append(productType.getTypeName())
                    } else if (productType == .FORTIFIED) {
                        types.append(productType.getTypeName())
                    }
                }
                
                for productCategory in product_categories! {
                    if (productCategory == .WHISKEY) {
                        categories.append(productCategory.getCategoryName())
                    } else if (productCategory == .MEZCAL) {
                        categories.append(productCategory.getCategoryName())
                    } else if (productCategory == .BEER) {
                        categories.append(productCategory.getCategoryName())
                    } else if (productCategory == .WINE) {
                        categories.append(productCategory.getCategoryName())
                    }
                }
                
                if (types.count > 0) {
                    dictionary["product_types"] = types
                }
                if (categories.count > 0) {
                    dictionary["product_categories"] = categories
                }
            }
            
            let context = NSManagedObjectContext.mr_()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            var searchResponse = try Preferabli.api.getAlamo().get(APIEndpoints.search, params: dictionary)
            searchResponse = try PreferabliTools.continueOrThrowPreferabliException(response: searchResponse)
            let searchDictionary = try PreferabliTools.continueOrThrowJSONException(data: searchResponse.data!) as! [String : Any]
            
            var search = CoreData_Search.mr_findFirst(byAttribute: "text", withValue: query, in: context)
            if (search == nil) {
                search = CoreData_Search.mr_createEntity(in: context)
            }
            
            search?.count = NSNumber.init(value: search!.count.intValue + 1)
            search?.text = query
            search?.last_searched = Date.init()
            context.mr_saveToPersistentStoreAndWait()
            
            var productsToReturn = Array<Product>()
            if let products = searchDictionary["products"] as? Array<[String : Any]> {
                for productDictionary in products {
                    let product = CoreData_Product.mr_findFirst(byAttribute: "id", withValue: productDictionary["id"]!, in: context) ?? CoreData_Product.mr_import(from: productDictionary, in: context)
                    if (product.variants.count == 0) {
                        let variant = CoreData_Variant.mr_createEntity(in: context)!
                        variant.id = NSNumber.init(value: PreferabliTools.generateRandomLongId())
                        variant.num_dollar_signs = productDictionary["latest_variant_num_dollar_signs"] as! NSNumber
                        variant.product = product
                    }
                    
                    productsToReturn.append(Product.init(product: product))
                }
            }
            
            if let tags = searchDictionary["tags"] as? Array<[String : Any]> {
                for tagDictionary in tags {
                    let product = CoreData_Product.mr_findFirst(byAttribute: "id", withValue: tagDictionary["product_id"]!, in: context) ?? CoreData_Product.mr_import(from: tagDictionary, in: context)
                    product.type = tagDictionary["product_type"] as! String
                    product.name = tagDictionary["product_name"] as! String
                    product.category = tagDictionary["product_category"] as! String
                    product.id = tagDictionary["product_id"] as! NSNumber
                    
                    let variant = CoreData_Variant.mr_findFirst(byAttribute: "id", withValue: tagDictionary["variant_id"]!, in: context) ?? CoreData_Variant.mr_createEntity(in: context)!
                    variant.id = tagDictionary["variant_id"] as! NSNumber
                    variant.price = tagDictionary["price"] as! Double
                    variant.num_dollar_signs = tagDictionary["num_dollar_signs"] as! NSNumber
                    variant.product = product
                    
                    productsToReturn.append(Product.init(product: product))
                }
            }
            
            context.mr_saveToPersistentStoreAndWait()
            
            if (include_merchant_links) {
                try addMerchantDataToProducts(products: productsToReturn)
            }
            
            DispatchQueue.main.async {
                onCompletion(productsToReturn)
            }
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
    
    /// Get rated products. Customer / Preferabli user must be logged in to run this call.
    /// - Parameters:
    ///   - force_refresh: pass true if you want to force a refresh from the API and wait for the results to return. Otherwise, the call will load locally if available and run a background refresh only if one has not been initiated in the past 5 minutes. Defaults to *false*.
    ///   - include_merchant_links: pass true if you want the results to include an array of ``MerchantProductLink`` embedded in ``Variant``. These connect Preferabli products to your own. Passing true requires additional resources and therefore will take longer. Defaults to *true*.
    ///   - onCompletion: returns an array of ``Product`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func getRatedProducts(force_refresh : Bool = false, include_merchant_links: Bool = true, onCompletion: @escaping ([Product]) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        getRatedProducts(force_refresh: force_refresh, include_merchant_links: include_merchant_links, priority: .veryHigh, onCompletion: onCompletion, onFailure: onFailure)
    }
    
    internal func getRatedProducts(force_refresh : Bool = false, include_merchant_links: Bool = true, priority : Operation.QueuePriority = .veryHigh, onCompletion: @escaping ([Product]) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: priority, {
            
            do {
                try self.canWeContinue(needsToBeLoggedIn: true)
                SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "get_rated_products"])
                
                let products : Array<Product>
                if (Preferabli.isPreferabliUserLoggedIn()) {
                    products = try self.getProductsInCollection(priority: priority, force_refresh: force_refresh, collection_id: NSNumber.init(value: PreferabliTools.getKeyStore().integer(forKey: "ratings_id")))
                } else {
                    products = try self.getCustomerTagProducts(force_refresh: force_refresh, tag_type: "rating")
                }
                
                if (include_merchant_links) {
                    try self.addMerchantDataToProducts(products: products)
                }
                
                DispatchQueue.main.async {
                    onCompletion(products)
                }
                
            } catch {
                self.handleError(error: error, onFailure: onFailure)
            }
        })
    }
    
    /// Get wishlisted products. Customer / Preferabli user must be logged in to run this call.
    /// - Parameters:
    ///   - force_refresh: pass true if you want to force a refresh from the API and wait for the results to return. Otherwise, the call will load locally if available and run a background refresh only if one has not been initiated in the past 5 minutes. Defaults to *false*.
    ///   - include_merchant_links: pass true if you want the results to include an array of ``MerchantProductLink`` embedded in ``Variant``. These connect Preferabli products to your own. Passing true requires additional resources and therefore will take longer. Defaults to *true*.
    ///   - onCompletion: returns an array of ``Product`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func getWishlistedProducts(force_refresh : Bool = false, include_merchant_links: Bool = true, onCompletion: @escaping ([Product]) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        getWishlistedProducts(force_refresh: force_refresh, include_merchant_links: include_merchant_links, priority: .veryHigh, onCompletion: onCompletion, onFailure: onFailure)
    }
    
    internal func getWishlistedProducts(force_refresh : Bool = false, include_merchant_links: Bool = true, priority : Operation.QueuePriority = .veryHigh, onCompletion: @escaping ([Product]) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: priority, {
            do {
                try self.canWeContinue(needsToBeLoggedIn: true)
                SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "get_wishlist_products"])
                
                let products : Array<Product>
                if (Preferabli.isPreferabliUserLoggedIn()) {
                    products = try self.getProductsInCollection(priority: priority, force_refresh: force_refresh, collection_id: NSNumber.init(value: PreferabliTools.getKeyStore().integer(forKey: "wishlist_id")))
                } else {
                    products = try self.getCustomerTagProducts(force_refresh: force_refresh, tag_type: "wishlist")
                }
                
                if (include_merchant_links) {
                    try self.addMerchantDataToProducts(products: products)
                }
                
                DispatchQueue.main.async {
                    onCompletion(products)
                }
                
            } catch {
                self.handleError(error: error, onFailure: onFailure)
            }
        })
    }
    
    /// Get purchased products. Customer / Preferabli user must be logged in to run this call.
    /// - Parameters:
    ///   - force_refresh: pass true if you want to force a refresh from the API and wait for the results to return. Otherwise, the call will load locally if available and run a background refresh only if one has not been initiated in the past 5 minutes. Defaults to *false*.
    ///   - lock_to_integration: pass true if you only want to draw results from your integration. Defaults to *true*.
    ///   - include_merchant_links: pass true if you want the results to include an array of ``MerchantProductLink`` embedded in ``Variant``. These connect Preferabli products to your own. Passing true requires additional resources and therefore will take longer. Defaults to *true*.
    ///   - onCompletion: returns an array of ``Product`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func getPurchasedProducts(force_refresh : Bool = false, lock_to_integration : Bool = true, include_merchant_links: Bool = true, onCompletion: @escaping ([Product]) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        getPurchasedProducts(force_refresh: force_refresh, lock_to_integration: lock_to_integration, include_merchant_links: include_merchant_links, priority: .veryHigh, onCompletion: onCompletion, onFailure: onFailure)
    }
    
    internal func getPurchasedProducts(force_refresh : Bool = false, lock_to_integration : Bool = true, include_merchant_links: Bool = true, priority : Operation.QueuePriority = .veryHigh, onCompletion: @escaping ([Product]) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: priority, {
            do {
                try self.canWeContinue(needsToBeLoggedIn: true)
                SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "get_purchase_history"])
                
                let products : Array<Product>
                if (Preferabli.isPreferabliUserLoggedIn()) {
                    products = try PreferabliUserTools.sharedInstance.getPurchaseHistory(priority: priority, forceRefresh: force_refresh, lock_to_integration: lock_to_integration)
                } else {
                    products = try self.getCustomerTagProducts(force_refresh: force_refresh, tag_type: "purchase")
                }
                
                if (include_merchant_links) {
                    try self.addMerchantDataToProducts(products: products)
                }
                
                onCompletion(products)
                
            } catch {
                self.handleError(error: error, onFailure: onFailure)
            }
        })
    }
    
    private func getProductsInCollection(priority : Operation.QueuePriority, force_refresh : Bool, collection_id : NSNumber) throws -> [Product] {
        try canWeContinue(needsToBeLoggedIn: true)
        
        let context = NSManagedObjectContext.mr_()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        if (force_refresh || !PreferabliTools.getKeyStore().bool(forKey: "hasLoaded\(collection_id)")) {
            try LoadCollectionTools.sharedInstance.loadCollectionViaTags(in: context, priority: priority, with: collection_id)
        } else if (PreferabliTools.hasMinutesPassed(minutes: 5, startDate: PreferabliTools.getKeyStore().object(forKey: "lastCalled\(collection_id)") as? Date)) {
            PreferabliTools.startNewWorkThread(priority: .low) {
                do {
                    let context = NSManagedObjectContext.mr_()
                    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                    try LoadCollectionTools.sharedInstance.loadCollectionViaTags(in: context, priority: .low, with: collection_id)
                } catch {
                    // catching any issues here so that we can still pull up our saved data
                    if (Preferabli.loggingEnabled) {
                        print(error)
                    }
                }
            }
        }
        
        let predicate = NSPredicate(format: "SUBQUERY(variants, $v, ANY $v.tags.collection_id == %d).@count != 0", collection_id)
        let products = CoreData_Product.mr_findAll(with: predicate, in: context) as! [CoreData_Product]
        
        var productsToReturn = Array<Product>()
        for product in products {
            productsToReturn.append(Product.init(product: product))
        }
        
        try canWeContinue(needsToBeLoggedIn: true)
        
        return productsToReturn
    }
    
    private func getCustomerTagProducts(force_refresh : Bool, tag_type : String?) throws -> [Product]  {
        try canWeContinue(needsToBeLoggedIn: true)
        
        let context = NSManagedObjectContext.mr_()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        if (force_refresh || !PreferabliTools.getKeyStore().bool(forKey: "hasLoaded" + (tag_type ?? "AllCustomerTags"))) {
            try self.getCustomerTagProductsActual(context: context, tag_type: tag_type)
        } else if (PreferabliTools.hasMinutesPassed(minutes: 5, startDate: PreferabliTools.getKeyStore().object(forKey: "lastCalled" + (tag_type ?? "AllCustomerTags")) as? Date)) {
            PreferabliTools.startNewWorkThread(priority: .low) {
                do {
                    let context = NSManagedObjectContext.mr_()
                    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                    try self.getCustomerTagProductsActual(context: context, tag_type: tag_type)
                } catch {
                    // catching any issues here so that we can still pull up our saved data
                    if (Preferabli.loggingEnabled) {
                        print(error)
                    }
                }
            }
        }
        
        let predicate : NSPredicate
        if (tag_type != nil) {
            predicate = NSPredicate(format: "SUBQUERY(variants, $v, ANY $v.tags.customer_id = %d).@count != 0 AND SUBQUERY(variants, $v, ANY $v.tags.type = %@).@count != 0", PreferabliTools.getCustomerId().intValue, tag_type!)
        } else {
            predicate = NSPredicate(format: "SUBQUERY(variants, $v, ANY $v.tags.customer_id == %d).@count != 0", PreferabliTools.getCustomerId())
        }
        
        let products = CoreData_Product.mr_findAll(with: predicate, in: context) as! [CoreData_Product]
        
        var productsToReturn = Array<Product>()
        for product in products {
            productsToReturn.append(Product.init(product: product))
        }
        
        try canWeContinue(needsToBeLoggedIn: true)
        
        return productsToReturn
    }
    
    private func getCustomerTagProductsActual(context : NSManagedObjectContext, tag_type : String?) throws {
        var params = ["offset" : 0, "limit" : 9999] as! [String : Any]
        if (tag_type != nil) {
            params["tag_type"] = tag_type!
        }
        var getTagsResponse = try Preferabli.api.getAlamo().get(APIEndpoints.customerTags(id: Preferabli.CHANNEL_ID, and: PreferabliTools.getCustomerId()), params: params)
        getTagsResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getTagsResponse)
        
        let tagDictionaries = try PreferabliTools.continueOrThrowJSONException(data: getTagsResponse.data!) as! NSArray
        var tags = Array<CoreData_Tag>()
        var tagMap = [NSNumber : Array<CoreData_Tag>]()
        for tag in tagDictionaries {
            let tagObject = CoreData_Tag.mr_import(from: tag, in: context)
            tagObject.customer_id = PreferabliTools.getCustomerId()
            tags.append(tagObject)
            if (tagMap[tagObject.variant_id] == nil) {
                var tagArray = Array<CoreData_Tag>()
                tagArray.append(tagObject)
                tagMap[tagObject.variant_id] = tagArray
            } else {
                var tagArray = tagMap[tagObject.variant_id]!
                tagArray.append(tagObject)
                tagMap[tagObject.variant_id] = tagArray
            }
        }
        
        let variantIds = tags.map { $0.variant_id }
        var getProductsResponse = try Preferabli.api.getAlamo().get(APIEndpoints.products, params: ["variant_ids" : variantIds])
        getProductsResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getProductsResponse)
        let productDictionaries = try PreferabliTools.continueOrThrowJSONException(data: getProductsResponse.data!) as! NSArray
        for product in productDictionaries {
            let productObject = CoreData_Product.mr_import(from: product, in: context)
            for variant in productObject.variants.allObjects as! [CoreData_Variant] {
                if let tagArray = tagMap[variant.id] {
                    for tag in tagArray {
                        tag.variant = variant
                    }
                }
            }
        }
        
        context.mr_saveToPersistentStoreAndWait()
        PreferabliTools.getKeyStore().set(Date.init(), forKey: "lastCalled" + (tag_type ?? "AllCustomerTags"))
        PreferabliTools.getKeyStore().set(true, forKey: "hasLoaded" + (tag_type ?? "AllCustomerTags"))
    }
    
    /// Get all the questions and choices needed to run a Guided Rec. Present the questions to the user, then pass the answers to ``Preferabli/getGuidedRecResults(guided_rec_id:selected_choice_ids:price_min:price_max:collection_id:include_merchant_links:onCompletion:onFailure:)`` to get results.
    /// - Parameters:
    ///   - guided_rec_id: id of the Guided Rec you wish to run. See ``GuidedRec`` for all the default Guided Rec options. Defaults to ``GuidedRec/WINE_DEFAULT``.
    ///   - onCompletion: returns ``GuidedRec`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func getGuidedRec(guided_rec_id: NSNumber = GuidedRec.WINE_DEFAULT, onCompletion: @escaping (GuidedRec) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            self.getGuidedRecActual(guided_rec_id: guided_rec_id, onCompletion: onCompletion, onFailure: onFailure)
        })
    }
    
    private func getGuidedRecActual(guided_rec_id: NSNumber, onCompletion: @escaping (GuidedRec) -> (), onFailure: @escaping (PreferabliException) -> ()) {
        do {
            try canWeContinue(needsToBeLoggedIn: false)
            
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "get_guided_rec"])
            
            var instantRecResponse = try Preferabli.api.getAlamo().get(APIEndpoints.guidedRec(id: guided_rec_id))
            instantRecResponse = try PreferabliTools.continueOrThrowPreferabliException(response: instantRecResponse)
            let dictionary = try PreferabliTools.continueOrThrowJSONException(data: instantRecResponse.data!) as! [String : Any]
            let quiz = GuidedRec(map: dictionary)
            
            DispatchQueue.main.async {
                onCompletion(quiz)
            }
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
    
    /// Get Guided Rec results based on the selected ``GuidedRecChoice``.
    /// - Parameters:
    ///   - guided_rec_id: id of the Guided Rec you wish to run.
    ///   - selected_choice_ids: an array of selected ``GuidedRecChoice`` ids.
    ///   - price_min: pass if you want to lock results to a minimum price. Defaults to *nil*.
    ///   - price_max: pass if you want to lock results to a maximum price. Defaults to *nil*.
    ///   - collection_id: the id of a specific ``Collection`` that you want to draw results from. Defaults to ``PRIMARY_INVENTORY_ID``. Pass *nil* for results from anywhere.
    ///   - include_merchant_links: pass true if you want the results to include an array of ``MerchantProductLink`` embedded in ``Variant``. These connect Preferabli products to your own. Passing true requires additional resources and therefore will take longer. Defaults to *true*.
    ///   - onCompletion: returns an array of ``Product`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func getGuidedRecResults(guided_rec_id: NSNumber, selected_choice_ids : Array<NSNumber>, price_min : Int? = nil, price_max : Int? = nil, collection_id : NSNumber? = Preferabli.getPrimaryInventoryId(), include_merchant_links: Bool = true, onCompletion: @escaping ([Product]) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            self.getGuidedRecResultsActual(guided_rec_id: guided_rec_id, selected_choice_ids: selected_choice_ids, price_min: price_min, price_max: price_max, collection_id: collection_id, include_merchant_links: include_merchant_links, onCompletion: onCompletion, onFailure: onFailure)
        })
    }
    
    private func getGuidedRecResultsActual(guided_rec_id: NSNumber, selected_choice_ids : Array<NSNumber>, price_min : Int?, price_max : Int?, collection_id : NSNumber?, include_merchant_links: Bool, onCompletion: @escaping ([Product]) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        do {
            try canWeContinue(needsToBeLoggedIn: false)
            
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "get_guided_rec_results"])
            
            var dictionary = [String : Any]()
            dictionary["limit"] = 8
            dictionary["sort_by"] = "preference"
            dictionary["questionnaire_id"] = guided_rec_id
            dictionary["offset"] = 0
            dictionary["questionnaire_choice_ids"] = selected_choice_ids
            
            var filtersToPass = Array<[String : Any]>()
            var priceMinFilter = [String : Any]()
            if (price_min != nil) {
                priceMinFilter["key"] = "price_min"
                priceMinFilter["value"] = price_min
                filtersToPass.append(priceMinFilter)
            }
            
            var priceMaxFilter = [String : Any]()
            if (price_max != nil) {
                priceMaxFilter["key"] = "price_max"
                priceMaxFilter["value"] = price_max
                filtersToPass.append(priceMaxFilter)
            }
            
            dictionary["filters"] = filtersToPass
            
            let context = NSManagedObjectContext.mr_()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            var recResponse = try Preferabli.api.getAlamo().post(collection_id == nil ? APIEndpoints.guidedRecResults() : APIEndpoints.guidedRecResults(id: collection_id!), json: dictionary)
            recResponse = try PreferabliTools.continueOrThrowPreferabliException(response: recResponse)
            let recDictionary = try PreferabliTools.continueOrThrowJSONException(data: recResponse.data!) as! [String : Any]
            let types = recDictionary["types"] as! Array<[String : Any]>
            
            var productsToReturn = Array<Product>()
            
            for type in types {
                var variant_ids = Array<NSNumber>()
                var all_products = Array<CoreData_Product>()
                let results = type["results"] as! Array<[String : Any]>
                for result in results {
                    variant_ids.append(result["variant_id"] as! NSNumber)
                }
                
                
                var getProductsResponse = try Preferabli.api.getAlamo().get(APIEndpoints.products, params: ["variant_ids" : variant_ids])
                getProductsResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getProductsResponse)
                let productDictionaries = try PreferabliTools.continueOrThrowJSONException(data: getProductsResponse.data!) as! NSArray
                for product in productDictionaries {
                    let importedWine = CoreData_Product.mr_import(from: product, in: context)
                    all_products.append(importedWine)
                }
                
                for variant_id in variant_ids {
                    for product in all_products {
                        for product_variant in product.variants.allObjects as! [CoreData_Variant] {
                            if variant_id == product_variant.id {
                                productsToReturn.append(Product.init(product: product))
                            }
                        }
                    }
                }
            }
            
            context.mr_saveToPersistentStoreAndWait()
            
            if (include_merchant_links) {
                try addMerchantDataToProducts(products: productsToReturn)
            }
            
            DispatchQueue.main.async {
                onCompletion(productsToReturn)
            }
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
    
    /// Get a Like This, Try That recommendation. Start with a ``Product``, get similar tasting results. This function will return personalized results if a user is logged in.
    /// - Parameters:
    ///   - product_id: id of the starting ``Product``.  Only pass a Preferabli product id. If necessary, call ``Preferabli/getPreferabliProductId(merchant_product_id:merchant_variant_id:onCompletion:onFailure:)`` to convert your product id into a Preferabli product id.
    ///   - year: year of the ``Variant`` that you want to get results on. Defaults to ``Variant/CURRENT_VARIANT_YEAR``.
    ///   - collection_id: the id of a specific ``Collection`` that you want to draw results from. Defaults to ``PRIMARY_INVENTORY_ID``.
    ///   - onCompletion: returns an array of ``Product`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func lttt(product_id : NSNumber, year : NSNumber = Variant.CURRENT_VARIANT_YEAR, collection_id : NSNumber = Preferabli.getPrimaryInventoryId(), include_merchant_links: Bool = true, onCompletion: @escaping ([Product]) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            self.ltttActual(product_id: product_id, year: year, collection_id: collection_id, include_merchant_links: include_merchant_links, onCompletion: onCompletion, onFailure: onFailure)
        })
    }
    
    private func ltttActual(product_id : NSNumber, year : NSNumber, collection_id : NSNumber, include_merchant_links: Bool, onCompletion: @escaping ([Product]) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        do {
            try canWeContinue(needsToBeLoggedIn: false)
            
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "lttt"])
            
            var dictionary: [String : Any] = ["product_id" : product_id, "year" : year, "collection_id" : collection_id]
            
            if (Preferabli.isPreferabliUserLoggedIn()) {
                dictionary["user_id"] = PreferabliTools.getPreferabliUserId()
            } else if (Preferabli.isCustomerLoggedIn()) {
                dictionary["channel_customer_id"] = PreferabliTools.getCustomerId()
            }
            
            let context = NSManagedObjectContext.mr_()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            var getProductsResponse = try Preferabli.api.getAlamo().get(APIEndpoints.lttt, params: dictionary)
            getProductsResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getProductsResponse)
            let responseDictionary = try PreferabliTools.continueOrThrowJSONException(data: getProductsResponse.data!) as! [String : Any]
            
            let dictionaries = responseDictionary["results"] as? Array<[String : Any]>
            var productsToReturn = Array<Product>()
            
            if (dictionaries != nil) {
                for dictionary in dictionaries! {
                    let coreProduct = CoreData_Product.mr_import(from: dictionary, in: context)
                    let wili = PreferenceData(title: nil, details: nil, confidence_code: nil, formatted_predict_rating: dictionary["formatted_predict_rating"] as? Int)
                    let product = Product.init(product: coreProduct)
                    product.most_recent_variant.preference_data = wili
                    productsToReturn.append(product)
                }
            }
            
            context.mr_saveToPersistentStoreAndWait()
            
            if (include_merchant_links) {
                try addMerchantDataToProducts(products: productsToReturn)
            }
            
            DispatchQueue.main.async {
                onCompletion(productsToReturn)
            }
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
    
    /// Call this to convert your merchant product / variant id to the Preferabli product id for use with our functions.
    /// - Parameters:
    ///   - merchant_product_id: the id of your product (as it appears in your system). *Either this or merchant_variant_id is required.*
    ///   - merchant_variant_id: the id of your product variant (as it appears in your system). *Used only if you have a hierarchical database format for your products.*
    ///   - onCompletion: returns product id if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func getPreferabliProductId(merchant_product_id : String? = nil, merchant_variant_id : String? = nil, onCompletion: @escaping (NSNumber) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            self.getPreferabliProductIdActual(merchant_product_id: merchant_product_id, merchant_variant_id: merchant_variant_id, onCompletion: onCompletion, onFailure: onFailure)
        })
    }
    
    private func getPreferabliProductIdActual(merchant_product_id : String?, merchant_variant_id : String?, onCompletion: @escaping (NSNumber) -> (), onFailure: @escaping (PreferabliException) -> ()) {
        do {
            try canWeContinue(needsToBeLoggedIn: false)
            
            if (merchant_product_id == nil && merchant_variant_id == nil) {
                throw PreferabliException.init(type: .MappingNotFound)
            }
            
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "get_preferabli_id"])
            
            var dictionaries = Array<[String : Any]>()
            
            var dictionary = [String : Any]()
            dictionary["number"] = 1
            if (merchant_product_id != nil) {
                dictionary["merchant_product_ids"] = [merchant_product_id!]
            }
            if (merchant_variant_id != nil) {
                dictionary["merchant_variant_ids"] = [merchant_variant_id!]
            }
            dictionaries.append(dictionary)
            
            var conversionResponse = try Preferabli.api.getAlamo().post(APIEndpoints.lookupConversion(id: Preferabli.INTEGRATION_ID), jsonObject: dictionaries)
            conversionResponse = try PreferabliTools.continueOrThrowPreferabliException(response: conversionResponse)
            let conversionDictionaries = try PreferabliTools.continueOrThrowJSONException(data: conversionResponse.data!) as! Array<[String : Any]>
            for dictionary in conversionDictionaries {
                let lookups = dictionary["lookups"] as! Array<[String : Any]>
                if (lookups.count > 0) {
                    let lookup = lookups[0]
                    DispatchQueue.main.async {
                        onCompletion((lookup["product_id"] as! NSNumber))
                    }
                    return
                }
            }
            
            throw PreferabliException.init(type: .MappingNotFound)
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
    
    /// Get help finding out where a ``Product`` is in stock.
    /// - Parameters:
    ///   - product_id: id of the starting ``Product``.  Only pass a Preferabli product id. If necessary, call ``Preferabli/getPreferabliProductId(merchant_product_id:merchant_variant_id:onCompletion:onFailure:)`` to convert your product id into a Preferabli product id.
    ///   - fulfill_sort: pass ``FulfillSort`` for sorting & filtering options. If sorting by distance, ``Location`` MUST be present!
    ///   - append_nonconforming_results: pass true if you want results that *DO NOT* conform to all filtering & sorting parameters to be returned. Useful so that something is returned even if the user's filter parameters are too narrow. All results that do not conform contain nonconforming_result = true within. Defaults to *true*.
    ///   - lock_to_integration: pass true if you only want to draw results from your integration. Defaults to *true*.
    ///   - onCompletion: returns ``WhereToBuy`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func whereToBuy(product_id : NSNumber, fulfill_sort : FulfillSort = FulfillSort.init(), append_nonconforming_results : Bool = true, lock_to_integration : Bool = true, onCompletion: @escaping (WhereToBuy) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            self.whereToBuyActual(product_id: product_id, fulfill_sort: fulfill_sort, append_nonconforming_results: append_nonconforming_results, lock_to_integration: lock_to_integration, onCompletion: onCompletion, onFailure: onFailure)
        })
    }
    
    private func whereToBuyActual(product_id : NSNumber, fulfill_sort : FulfillSort, append_nonconforming_results : Bool, lock_to_integration : Bool, onCompletion: @escaping (WhereToBuy) -> (), onFailure: @escaping (PreferabliException) -> ()) {
        do {
            try canWeContinue(needsToBeLoggedIn: false)
            
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "where_to_buy"])
            
            var sort_by = "nearest_first"
            if (fulfill_sort.type == .DISTANCE && fulfill_sort.ascending) {
                sort_by = "nearest_first"
            } else if (fulfill_sort.type == .DISTANCE) {
                sort_by = "furthest_first"
            } else if (fulfill_sort.ascending){
                sort_by = "price_asc"
            } else {
                sort_by = "price_desc"
            }
            
            var params = ["product_id" : product_id, "sort_by" : sort_by, "merge_products" : true, "pickup" : fulfill_sort.include_pickup, "local_delivery" : fulfill_sort.include_delivery, "standard_shipping" : fulfill_sort.include_shipping, "append_nonconforming_results" : append_nonconforming_results, "limit" : 1000, "offset" : 0, "distance_miles" : fulfill_sort.distance_miles] as [String : Any]
            
            if (fulfill_sort.type == .DISTANCE && fulfill_sort.location == nil) {
                throw PreferabliException.init(type: .OtherError, message: "Sort by distance requires a location.")
            } else if (fulfill_sort.location != nil) {
                if (PreferabliTools.isNullOrWhitespace(string: fulfill_sort.location!.zip_code)) {
                    params["lat"] = fulfill_sort.location!.latitude
                    params["long"] = fulfill_sort.location!.longitude
                } else {
                    params["zip_code"] = fulfill_sort.location!.zip_code
                }
            } else {
                params["in_stock_anywhere"] = true
            }
            
            if (lock_to_integration) {
                var channelIds = Array<NSNumber>()
                channelIds.append(Preferabli.CHANNEL_ID)
                params["channel_ids"] = channelIds
            }
            
            if (fulfill_sort.variant_year != Variant.NON_VARIANT) {
                var years = Array<NSNumber>()
                years.append(fulfill_sort.variant_year)
                params["years"] = years
            }
            
            var marketplaceResponse = try Preferabli.api.getAlamo().get(APIEndpoints.wheretobuy, params: params)
            marketplaceResponse = try PreferabliTools.continueOrThrowPreferabliException(response: marketplaceResponse)
            let dictionary = try PreferabliTools.continueOrThrowJSONException(data: marketplaceResponse.data!) as! NSArray
            
            let firstElement = dictionary.firstObject as? [String : Any]
            let venueResults = firstElement?["venue_results"] as? Array<[String : Any]>
            let lookupResults = firstElement?["lookup_results"] as? Array<[String : Any]>
            
            var venues = Array<Venue>()
            if (venueResults != nil) {
                for venueObject in venueResults! {
                    let venue = Venue.init(map: venueObject)
                    venues.append(venue)
                }
            }
            
            var lookups = Array<MerchantProductLink>()
            if (lookupResults != nil) {
                for lookupObject in lookupResults! {
                    let lookup = MerchantProductLink.init(map: lookupObject)
                    lookups.append(lookup)
                }
            }
            
            let WTB = WhereToBuy(links: lookups, venues: venues)
            
            DispatchQueue.main.async {
                onCompletion(WTB)
            }
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
    
    /// Get the Preference Profile of the customer / user. Customer / user must be logged in to run this call.
    /// - Parameters:
    ///   - force_refresh: pass true if you want to force a refresh from the API and wait for the results to return. Otherwise, the call will load locally if available and run a background refresh only if one has not been initiated in the past 5 minutes. Defaults to *false*.
    ///   - onCompletion: returns ``Profile`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func getProfile(force_refresh : Bool = false, onCompletion: @escaping (Profile) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            self.getProfileActual(force_refresh: force_refresh, onCompletion: onCompletion, onFailure: onFailure)
        })
    }
    
    private func getProfileActual(force_refresh : Bool = false, onCompletion: @escaping (Profile) -> () = {_ in }, onFailure: @escaping (PreferabliException) -> ()  = {_ in }) {
        do {
            try canWeContinue(needsToBeLoggedIn: true)
            
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "get_profile"])
            
            let context = NSManagedObjectContext.mr_()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            if (force_refresh || !PreferabliTools.getKeyStore().bool(forKey: "hasLoadedProfile")) {
                try getProfileActual(context: context, force_refresh: force_refresh)
            } else if (PreferabliTools.hasMinutesPassed(minutes: 5, startDate: PreferabliTools.getKeyStore().object(forKey: "lastCalledProfile") as? Date)) {
                PreferabliTools.startNewWorkThread(priority: .low) {
                    do {
                        let context = NSManagedObjectContext.mr_()
                        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                        try self.getProfileActual(context: context, force_refresh: false)
                    } catch {
                        // catching any issues here so that we can still pull up our saved data
                        if (Preferabli.loggingEnabled) {
                            print(error)
                        }
                    }
                }
            }
            
            let predicate = Preferabli.isCustomerLoggedIn() ? NSPredicate.init(format: "customer_id == %@", argumentArray: [PreferabliTools.getCustomerId()]) : NSPredicate.init(format: "user_id == %@", argumentArray: [PreferabliTools.getPreferabliUserId()])
            let coredataProfile = CoreData_Profile.mr_findFirst(with: predicate, in: context)!
            let profile = Profile.init(profile: coredataProfile)
            
            try canWeContinue(needsToBeLoggedIn: true)
            
            DispatchQueue.main.async {
                onCompletion(profile)
            }
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
    
    private func getProfileActual(context : NSManagedObjectContext, force_refresh : Bool) throws {
        var getPreferencesResponse = try Preferabli.api.getAlamo().get(Preferabli.isCustomerLoggedIn() ? APIEndpoints.customerProfile(id: Preferabli.CHANNEL_ID, and: PreferabliTools.getCustomerId()) : APIEndpoints.profile(id: PreferabliTools.getPreferabliUserId()))
        getPreferencesResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getPreferencesResponse)
        
        let styles = CoreData_ProfileStyle.mr_findAll(in: context) as! [CoreData_ProfileStyle]
        let otherProfile = CoreData_Profile.mr_createEntity(in: context)!
        for style in styles {
            style.profile = otherProfile
        }
        
        let profileDictionary = try PreferabliTools.continueOrThrowJSONException(data: getPreferencesResponse.data!)
        let profile = CoreData_Profile.mr_import(from: profileDictionary, in: context)
        profile.customer_id = PreferabliTools.getCustomerId()
        profile.user_id = PreferabliTools.getPreferabliUserId()
        
        var style_ids = Array<NSNumber>()
        var preferenceMap = [NSNumber : CoreData_ProfileStyle]()
        for preferenceStyle in profile.preference_styles.allObjects as! [CoreData_ProfileStyle] {
            if (force_refresh) {
                style_ids.append(preferenceStyle.style_id)
                preferenceMap[preferenceStyle.style_id] = preferenceStyle
            } else {
                let style = CoreData_Style.mr_findFirst(byAttribute: "id", withValue: preferenceStyle.style_id, in: context)
                if (style == nil) {
                    style_ids.append(preferenceStyle.style_id)
                    preferenceMap[preferenceStyle.style_id] = preferenceStyle
                }
            }
        }
        
        if (style_ids.count > 0) {
            var getStylesResponse = try Preferabli.api.getAlamo().get(APIEndpoints.styles, params: ["style_ids" : style_ids])
            getStylesResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getStylesResponse)
            let styleDictionaries = try PreferabliTools.continueOrThrowJSONException(data: getStylesResponse.data!) as! NSArray
            for styleDic in styleDictionaries {
                let style = CoreData_Style.mr_import(from: styleDic, in: context)
                preferenceMap[style.id]!.style = style
            }
        }
        
        PreferabliTools.getKeyStore().set(Date.init(), forKey: "lastCalledProfile")
        PreferabliTools.getKeyStore().setValue(true, forKey: "hasLoadedProfile")
        context.mr_saveToPersistentStoreAndWait()
    }
    
    /// Get a list of foods to choose from to be used in ``getRecs(product_category:product_type:price_min:price_max:collection_id:style_ids:food_ids:include_merchant_links:onCompletion:onFailure:)``.
    /// - Parameters:
    ///   - force_refresh: pass true if you want to force a refresh from the API and wait for the results to return. Otherwise, the call will load locally if available and run a background refresh only if one has not been initiated in the past 5 minutes. Defaults to *false*.
    ///   - onCompletion: returns an an array of ``Food`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func getFoods(force_refresh : Bool = false, onCompletion : @escaping ([Food]) -> () = {_ in }, onFailure : @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            self.getFoodsActual(force_refresh: force_refresh, onCompletion: onCompletion, onFailure: onFailure)
        })
    }
    
    private func getFoodsActual(force_refresh : Bool, onCompletion : @escaping ([Food]) -> (), onFailure : @escaping (PreferabliException) -> ()) {
        do {
            try canWeContinue(needsToBeLoggedIn: true)
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "get_foods"])
            
            let context = NSManagedObjectContext.mr_()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            if (force_refresh || !PreferabliTools.getKeyStore().bool(forKey: "hasLoadedFoods")) {
                try loadFoods(context: context)
            } else if (PreferabliTools.hasMinutesPassed(minutes: 5, startDate: PreferabliTools.getKeyStore().object(forKey: "lastCalledFoods") as? Date)) {
                PreferabliTools.startNewWorkThread(priority: .low) {
                    do {
                        let context = NSManagedObjectContext.mr_()
                        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                        try self.loadFoods(context: context)
                    } catch {
                        // catching any issues here so that we can still pull up our saved data
                        if (Preferabli.loggingEnabled) {
                            print(error)
                        }                    }
                }
            }
            
            var foodArray = Array<Food>()
            let foods = CoreData_Food.mr_findAll(in: context) as! [CoreData_Food]
            for food in foods {
                foodArray.append(Food.init(food: food))
            }
            foodArray = Food.sortFoodsAlpha(foods: foodArray)
            
            try canWeContinue(needsToBeLoggedIn: true)
            
            DispatchQueue.main.async {
                onCompletion(foodArray)
            }
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
    
    private func loadFoods(context : NSManagedObjectContext) throws {
        var getFoodsResponse = try Preferabli.api.getAlamo().get(APIEndpoints.foods)
        getFoodsResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getFoodsResponse)
        let foodDictionaries = try PreferabliTools.continueOrThrowJSONException(data: getFoodsResponse.data!) as! NSArray
        var foodArray = Array<Food>()
        for foodDictionary in foodDictionaries {
            let coreFood = CoreData_Food.mr_import(from: foodDictionary, in: context)
            foodArray.append(Food.init(food: coreFood))
        }
        
        context.mr_saveToPersistentStoreAndWait()
        
        PreferabliTools.getKeyStore().set(Date.init(), forKey: "lastCalledFoods")
        PreferabliTools.getKeyStore().setValue(true, forKey: "hasLoadedFoods")
    }
    
    /// Get a personalized, preference based recommendation for a customer / Preferabli user.
    /// - Parameters:
    ///   - product_category: pass a ``ProductCategory`` that you would like the results to conform to.
    ///   - product_type: pass a ``ProductType`` that you would like the results to conform to. Pass ``ProductType/OTHER`` if ``ProductCategory`` is not set  to ``ProductCategory/WINE``. If ``ProductCategory/WINE`` is passed, a type of wine *must* be passed here.
    ///   - price_min: pass if you want to lock results to a minimum price. Defaults to *nil*.
    ///   - price_max: pass if you want to lock results to a maximum price. Defaults to *nil*.
    ///   - collection_id: the id of a specific ``Collection`` that you want to draw results from. Defaults to ``PRIMARY_INVENTORY_ID``. Pass *nil* for results from anywhere.
    ///   - style_ids: an array of ``Style`` ids that you want to constrain results to. Get available styles from ``getProfile(force_refresh:onCompletion:onFailure:)``. Defaults to *nil*.
    ///   - food_ids: an array of ``Food`` ids that should pair with the recommendation. Get available foods from ``getFoods(force_refresh:onCompletion:onFailure:)`` Defaults to *nil*.
    ///   - include_merchant_links: pass true if you want the results to include an array of ``MerchantProductLink`` embedded in ``Variant``. These connect Preferabli products to your own. Passing true requires additional resources and therefore will take longer. Defaults to *true*.
    ///   - onCompletion: returns an optional message as a string along with an array of ``Product`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func getRecs(product_category : ProductCategory, product_type : ProductType, price_min : Int? = nil, price_max : Int? = nil, collection_id : NSNumber = Preferabli.getPrimaryInventoryId(), style_ids : [NSNumber]? = nil, food_ids : [NSNumber]? = nil, include_merchant_links: Bool = true, onCompletion: @escaping (String?, [Product]) -> () = {_,_  in }, onFailure: @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            self.getRecsActual(product_category: product_category, product_type: product_type, price_min: price_min, price_max: price_max, collection_id: collection_id, style_ids: style_ids, food_ids: food_ids, include_merchant_links: include_merchant_links, onCompletion: onCompletion, onFailure: onFailure)
        })
    }
    
    private func getRecsActual(product_category : ProductCategory, product_type : ProductType, price_min : Int?, price_max : Int?, collection_id : NSNumber, style_ids : [NSNumber]?, food_ids : [NSNumber]?, include_merchant_links: Bool, onCompletion : @escaping (String?, [Product]) -> (), onFailure : @escaping (PreferabliException) -> ()) {
        do {
            try canWeContinue(needsToBeLoggedIn: true)
            
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "get_recs"])
            
            let context = NSManagedObjectContext.mr_()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            var dictionaryArray = Array<[String : Any]>()
            let typeParam = ["type" : "types", "values" : [ product_type != .OTHER ? product_type.getTypeName() : product_category.getCategoryName()]] as! [String : Any]
            let categoryParam = ["type" : "product_categories", "values" : [product_category.getCategoryName()]] as! [String : Any]
            let precParam = ["type" : "precedence", "values" : false] as! [String : Any]
            if (Preferabli.isCustomerLoggedIn()) {
                let customerParam = ["type" : "channel_customer_ids", "values" : [PreferabliTools.getCustomerId()]] as! [String : Any]
                dictionaryArray.append(customerParam)
            } else {
                let usersParam = ["type" : "user_ids", "values" : [PreferabliTools.getPreferabliUserId()]] as! [String : Any]
                dictionaryArray.append(usersParam)
            }
            let oneStyleParam = ["type" : "single_style", "values" : false] as! [String : Any]
            let ratedParam = ["type" : "rated_wines", "values" : "ignore"] as! [String : Any]
            let newParam = ["type" : "collection_ids", "values" : [ collection_id ]] as [String : Any]
            dictionaryArray.append(newParam)
            dictionaryArray.append(typeParam)
            dictionaryArray.append(categoryParam)
            dictionaryArray.append(precParam)
            dictionaryArray.append(oneStyleParam)
            dictionaryArray.append(ratedParam)
            
            if (style_ids != nil && style_ids!.count > 0) {
                let newParam = ["type" : "style_ids", "values" : style_ids!] as [String : Any]
                dictionaryArray.append(newParam)
            }
            
            if (food_ids != nil && food_ids!.count > 0) {
                let newParam = ["type" : "food_ids", "values" : food_ids!] as [String : Any]
                dictionaryArray.append(newParam)
            }
            
            if (price_min != nil) {
                let min = ["type" : "price_min", "values" : price_min!] as! [String : Any]
                dictionaryArray.append(min)
            }
            if (price_max != nil) {
                let max = ["type" : "price_max", "values" : price_max!] as! [String : Any]
                dictionaryArray.append(max)
            }
            
            let dictionary = ["constraints" : dictionaryArray] as [String : Any]
            
            var recResponse = try Preferabli.api.getAlamo().post(APIEndpoints.getRec, json: dictionary)
            recResponse = try PreferabliTools.continueOrThrowPreferabliException(response: recResponse)
            let recDictionary = try PreferabliTools.continueOrThrowJSONException(data: recResponse.data!) as! [String : Any]
            let message = recDictionary["message"] as? String
            let results = recDictionary["results"] as! Array<[String : Any]>
            
            var variantIds = Array<NSNumber>()
            var predictRatings = Array<NSNumber>()
            var confidenceCodes = Array<NSNumber>()
            
            var primaryVariantIds = Array<NSNumber>()
            var secondaryVariantIds = Array<NSNumber>()
            var tertiaryVariantIds = Array<NSNumber>()
            
            var wines = Array<Product>()
            
            var primaryStyleId : NSNumber = 0
            var secondaryStyleId : NSNumber = 0
            var tertiaryStyleId : NSNumber = 0
            
            var x = 0
            for rec in results {
                variantIds.append(rec["variant_id"] as! NSNumber)
                predictRatings.append(rec["formatted_predict_rating"] as! NSNumber)
                confidenceCodes.append(rec["confidence_code"] as! NSNumber)
                
                if (x < 12) {
                    primaryStyleId = rec["style_id"] as! NSNumber
                    primaryVariantIds.append(rec["variant_id"] as! NSNumber)
                } else if (x < 24) {
                    secondaryStyleId = rec["style_id"] as! NSNumber
                    secondaryVariantIds.append(rec["variant_id"] as! NSNumber)
                } else {
                    tertiaryStyleId = rec["style_id"] as! NSNumber
                    tertiaryVariantIds.append(rec["variant_id"] as! NSNumber)
                }
                x = x + 1
            }
            
            if (primaryStyleId != 0 && primaryStyleId == secondaryStyleId) {
                primaryVariantIds.append(contentsOf: secondaryVariantIds)
                secondaryVariantIds.removeAll()
                secondaryStyleId = 0
            }
            
            if (primaryStyleId != 0 && primaryStyleId == tertiaryStyleId) {
                primaryVariantIds.append(contentsOf: tertiaryVariantIds)
                tertiaryVariantIds.removeAll()
                tertiaryStyleId = 0
            }
            
            if (secondaryStyleId != 0 && secondaryStyleId == tertiaryStyleId) {
                secondaryVariantIds.append(contentsOf: tertiaryVariantIds)
                tertiaryVariantIds.removeAll()
                tertiaryStyleId = 0
            }
            
            if (primaryStyleId != 0 && CoreData_Style.mr_findFirst(byAttribute: "id", withValue: primaryStyleId) == nil) {
                var getStyleResponse = try Preferabli.api.getAlamo().get(APIEndpoints.style(id: primaryStyleId))
                getStyleResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getStyleResponse)
                let styleDictionary = try PreferabliTools.continueOrThrowJSONException(data: getStyleResponse.data!)
                CoreData_Style.mr_import(from: styleDictionary, in: context)
            }
            
            if (secondaryStyleId != 0 && CoreData_Style.mr_findFirst(byAttribute: "id", withValue: secondaryStyleId) == nil) {
                var getStyleResponse = try Preferabli.api.getAlamo().get(APIEndpoints.style(id: secondaryStyleId))
                getStyleResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getStyleResponse)
                let styleDictionary = try PreferabliTools.continueOrThrowJSONException(data: getStyleResponse.data!)
                CoreData_Style.mr_import(from: styleDictionary, in: context)
            }
            
            if (tertiaryStyleId != 0 && CoreData_Style.mr_findFirst(byAttribute: "id", withValue: tertiaryStyleId) == nil) {
                var getStyleResponse = try Preferabli.api.getAlamo().get(APIEndpoints.style(id: tertiaryStyleId))
                getStyleResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getStyleResponse)
                let styleDictionary = try PreferabliTools.continueOrThrowJSONException(data: getStyleResponse.data!)
                CoreData_Style.mr_import(from: styleDictionary, in: context)
            }
            
            if (variantIds.count > 0) {
                var getProductsResponse = try Preferabli.api.getAlamo().get(APIEndpoints.products, params: ["variant_ids" : variantIds])
                getProductsResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getProductsResponse)
                let productDictionaries = try PreferabliTools.continueOrThrowJSONException(data: getProductsResponse.data!) as! NSArray
                for product in productDictionaries {
                    let productObject = CoreData_Product.mr_import(from: product, in: context)
                    
                    let product = Product.init(product: productObject)
                    var position = 0
                    for variant in variantIds {
                        let variantHere = product.getVariantWithId(id: variant)
                        if (variantHere != nil) {
                            let predictRating = predictRatings[position]
                            let code = confidenceCodes[position]
                            let prefData = PreferenceData.init(confidence_code: code.intValue, formatted_predict_rating: predictRating.intValue)
                            variantHere!.preference_data = prefData
                            break
                        }
                        
                        position = position + 1
                    }
                    
                    wines.append(product)
                }
            }
            
            context.mr_saveToPersistentStoreAndWait()
            
            if (include_merchant_links) {
                try addMerchantDataToProducts(products: wines)
            }
            
            try canWeContinue(needsToBeLoggedIn: true)
            
            DispatchQueue.main.async {
                onCompletion(message, wines)
            }
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
    
    private func addMerchantDataToProducts(products: [Product]) throws {
        if (products.count == 0) {
            return
        }
        
        var dictionaries = Array<[String : Any]>()
        for product in products {
            for variant in product.variants {
                var dictionary = [String : Any]()
                dictionary["number"] = variant.id
                dictionary["variant_ids"] = [variant.id]
                dictionaries.append(dictionary)
            }
        }
        
        var conversionResponse = try Preferabli.api.getAlamo().post(APIEndpoints.lookupConversion(id: Preferabli.INTEGRATION_ID), jsonObject: dictionaries)
        conversionResponse = try PreferabliTools.continueOrThrowPreferabliException(response: conversionResponse)
        let conversionDictionaries = try PreferabliTools.continueOrThrowJSONException(data: conversionResponse.data!) as! Array<[String : Any]>
        
        
    outerLoop:
        for dictionary in conversionDictionaries {
            let variant_id = dictionary["number"] as! NSNumber
            for product in products {
                for variant in product.variants {
                    if (variant.id == variant_id) {
                        let lookups = dictionary["lookups"] as! Array<[String : Any]>
                        var merchant_links = Array<MerchantProductLink>()
                        for lookup in lookups {
                            let merchantProductLink = MerchantProductLink.init(map: lookup)
                            merchant_links.append(merchantProductLink)
                        }
                        variant.merchant_links = merchant_links
                        continue outerLoop
                    }
                }
            }
        }
    }
    
    /// Rate a ``Product``. Creates a ``Tag`` of type ``TagType/RATING`` which is returned within the relevant product ``Variant``. Customer / user must be logged in to run this call.
    /// - Parameters:
    ///   - product_id: id of the starting ``Product``.  Only pass a Preferabli product id. If necessary, call ``Preferabli/getPreferabliProductId(merchant_product_id:merchant_variant_id:onCompletion:onFailure:)`` to convert your product id into a Preferabli product id.
    ///   - year: year of the ``Variant`` that you want to rate. Can use ``Variant/CURRENT_VARIANT_YEAR`` if you want to rate the latest variant, or ``Variant/NON_VARIANT`` if the product is not vintaged.
    ///   - rating: pass one of ``RatingType/LOVE``, ``RatingType/LIKE``, ``RatingType/SOSO``, ``RatingType/DISLIKE``.
    ///   - location: location where the rating occurred. Defaults to *nil*.
    ///   - notes: any notes to go along with the rating. Defaults to *nil*.
    ///   - price: price of the product rated. Defaults to *nil*.
    ///   - quantity: quantity purchased of the product rated. Defaults to *nil*.
    ///   - format_ml: size of the product rated. Defaults to *nil*.
    ///   - onCompletion: returns ``Product`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func rateProduct(product_id : NSNumber, year : NSNumber, rating : RatingType, location : String? = nil, notes : String? = nil, price : NSNumber? = nil, quantity : NSNumber? = nil, format_ml : NSNumber? = nil, onCompletion : @escaping (Product) -> () = {_ in }, onFailure : @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            do {
                try self.canWeContinue(needsToBeLoggedIn: true)
                SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "rate_product"])
                self.createTagActual(product_id: product_id, year: year, collection_id: NSNumber.init(value: PreferabliTools.getKeyStore().integer(forKey: "ratings_id")), value: rating.getValue(), tag_type: .RATING, location: location, notes: notes, price: price, quantity: quantity, format_ml: format_ml, onCompletion: onCompletion, onFailure: onFailure)
            } catch {
                self.handleError(error: error, onFailure: onFailure)
            }
        })
    }
    
    /// Wishlist a ``Product``. Creates a ``Tag`` of type ``TagType/WISHLIST`` which is returned within the relevant product ``Variant``. Customer / user must be logged in to run this call.
    /// - Parameters:
    ///   - product_id: id of the starting ``Product``.  Only pass a Preferabli product id. If necessary, call ``Preferabli/getPreferabliProductId(merchant_product_id:merchant_variant_id:onCompletion:onFailure:)`` to convert your product id into a Preferabli product id.
    ///   - year: year of the ``Variant`` that you want to wishlist. Can use ``Variant/CURRENT_VARIANT_YEAR`` if you want to wishlist the latest variant, or ``Variant/NON_VARIANT`` if the product is not vintaged.
    ///   - location: location where the wishlisted item exists. Defaults to *nil*.
    ///   - notes: any notes to go along with the wishlisting. Defaults to *nil*.
    ///   - price: price of the product wishlisted. Defaults to *nil*.
    ///   - format_ml: size of the product wishlisted. Defaults to *nil*.
    ///   - onCompletion: returns ``Product`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func wishlistProduct(product_id : NSNumber, year : NSNumber, location : String? = nil, notes : String? = nil, price : NSNumber? = nil, format_ml : NSNumber? = nil, onCompletion : @escaping (Product) -> () = {_ in }, onFailure : @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            do {
                try self.canWeContinue(needsToBeLoggedIn: true)
                SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "wishlist_product"])
                self.createTagActual(product_id: product_id, year: year, collection_id: NSNumber.init(value: PreferabliTools.getKeyStore().integer(forKey: "wishlist_id")), value: nil, tag_type: .WISHLIST, location: location, notes: notes, price: price, quantity: nil, format_ml: format_ml, onCompletion: onCompletion, onFailure: onFailure)
            } catch {
                self.handleError(error: error, onFailure: onFailure)
            }
        })
    }
    
    private func createTagActual(product_id : NSNumber, year : NSNumber, collection_id : NSNumber, value : String?, tag_type : TagType, location : String?, notes : String?, price : NSNumber?, quantity : NSNumber?, format_ml : NSNumber?, onCompletion : @escaping (Product) -> (), onFailure : @escaping (PreferabliException) -> ()) {
        do {
            try canWeContinue(needsToBeLoggedIn: true)
            
            let context = NSManagedObjectContext.mr_()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            let tagDictionary = ["type" : tag_type.getDatabaseName(), "location" : location ?? "", "comment" : notes ?? "", "value" : value ?? "", "year" : year, "product_id" : product_id, "price" : price ?? 0, "quantity" : quantity ?? 0, "format_ml" : format_ml ?? 0, "collection_id" : collection_id] as [String : Any]
            
            var tagResponseDictionary : Any?
            if (tag_type == .CELLAR) {
                var tagResponse = try Preferabli.api.getAlamo().post(APIEndpoints.tags(id: collection_id), json: tagDictionary)
                tagResponse = try PreferabliTools.continueOrThrowPreferabliException(response: tagResponse)
                PreferabliTools.saveCollectionEtag(response: tagResponse, collectionId: collection_id)
                tagResponseDictionary = try JSONSerialization.jsonObject(with: tagResponse.data!, options: [])
            } else if (Preferabli.isPreferabliUserLoggedIn()) {
                var tagResponse = try Preferabli.api.getAlamo().post(APIEndpoints.userTags(id: PreferabliTools.getPreferabliUserId()), json: tagDictionary)
                tagResponse = try PreferabliTools.continueOrThrowPreferabliException(response: tagResponse)
                tagResponseDictionary = try PreferabliTools.continueOrThrowJSONException(data: tagResponse.data!)
            } else if (Preferabli.isCustomerLoggedIn()) {
                var tagResponse = try Preferabli.api.getAlamo().post(APIEndpoints.customerTags(id: Preferabli.CHANNEL_ID, and: PreferabliTools.getCustomerId()), json: tagDictionary)
                tagResponse = try PreferabliTools.continueOrThrowPreferabliException(response: tagResponse)
                tagResponseDictionary = try PreferabliTools.continueOrThrowJSONException(data: tagResponse.data!)
            }
            
            let tag = CoreData_Tag.mr_import(from: tagResponseDictionary!, in: context)
            let variant_id = tag.variant_id
            
            var product = CoreData_Product.mr_findFirst(byAttribute: "id", withValue: product_id, in: context)
            var variant = CoreData_Variant.mr_findFirst(byAttribute: "id", withValue: variant_id, in: context)
            
            if (variant == nil) {
                var getProductsResponse = try Preferabli.api.getAlamo().get(APIEndpoints.products, params: ["variant_ids" : [ variant_id ]])
                getProductsResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getProductsResponse)
                let productDictionaries = try PreferabliTools.continueOrThrowJSONException(data: getProductsResponse.data!) as! NSArray
                for productDictionary in productDictionaries {
                    product = CoreData_Product.mr_import(from: productDictionary, in: context)
                    variant = product!.getVariantWithId(id: variant_id)
                }
            }
            
            tag.variant = variant!
            
            let productToReturn = Product.init(product: product!)
            
            try addMerchantDataToProducts(products: [ productToReturn ])
            
            try canWeContinue(needsToBeLoggedIn: true)
            
            DispatchQueue.main.async {
                onCompletion(productToReturn)
            }
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
    
    /// Delete the specified ``Tag``.
    /// - Parameters:
    ///   - tag_id: id of the ``Tag`` you want to delete.
    ///   - onCompletion: returns ``Product`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func deleteTag(tag_id : NSNumber, onCompletion : @escaping (Product) -> ()  = {_ in }, onFailure : @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            self.deleteTagActual(tag_id: tag_id, onCompletion: onCompletion, onFailure: onFailure)
        })
    }
    
    private func deleteTagActual(tag_id : NSNumber, onCompletion : @escaping (Product) -> (), onFailure : @escaping (PreferabliException) -> ()) {
        do {
            try self.canWeContinue(needsToBeLoggedIn: true)
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "delete_tag"])
            
            let context = NSManagedObjectContext.mr_()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            guard let tag = CoreData_Tag.mr_findFirst(byAttribute: "id", withValue: tag_id, in: context) else {
                throw PreferabliException(type: .DatabaseError)
            }
            
            if (PreferabliTools.isCustomerLoggedIn()) {
                var tagResponse = try Preferabli.api.getAlamo().delete(APIEndpoints.customerTag(id: Preferabli.CHANNEL_ID, customerId: PreferabliTools.getCustomerId(), tagId: tag_id))
                tagResponse = try PreferabliTools.continueOrThrowPreferabliException(response: tagResponse)
            } else {
                var tagResponse = try Preferabli.api.getAlamo().delete(APIEndpoints.userTag(id: PreferabliTools.getPreferabliUserId(), tagId: tag_id))
                tagResponse = try PreferabliTools.continueOrThrowPreferabliException(response: tagResponse)
            }
            
            tag.mr_deleteEntity(in: context)
            let product_id = tag.product_id
            context.mr_saveToPersistentStoreAndWait()
            
            let product = CoreData_Product.mr_findFirst(byAttribute: "id", withValue: product_id, in: context)
            let productToReturn = Product.init(product: product!)
            try addMerchantDataToProducts(products: [ productToReturn ])
            
            try canWeContinue(needsToBeLoggedIn: true)
            
            DispatchQueue.main.async {
                onCompletion(productToReturn)
            }
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
    
    
    /// Get a Preferabli user / customer's preference data for a given ``Product``.
    /// - Parameters:
    ///   - product_id: id of the starting ``Product``.
    ///   - year: year of the ``Variant`` that you want to get results on. Defaults to ``Variant/CURRENT_VARIANT_YEAR``.
    ///   - onCompletion: returns ``PreferenceData`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func getPreferabliScore(product_id : NSNumber, year : NSNumber = Variant.CURRENT_VARIANT_YEAR, onCompletion : @escaping (PreferenceData) -> ()  = {_ in }, onFailure : @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .low) {
            self.getPreferabliScoreActual(product_id: product_id, year: year, onCompletion: onCompletion, onFailure: onFailure)
        }
    }
    
    private func getPreferabliScoreActual(product_id : NSNumber, year : NSNumber, onCompletion : @escaping (PreferenceData) -> (), onFailure : @escaping (PreferabliException) -> ()) {
        do {
            try self.canWeContinue(needsToBeLoggedIn: true)
            
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "get_preferabli_score"])
            
            if (Preferabli.wiliDictionary[product_id] ?? false) {
                return
            }
            
            Preferabli.wiliDictionary[product_id] = true
            
            var wiliResponse : DataResponse<Data>
            if (PreferabliTools.isCustomerLoggedIn()) {
                let params = ["product_id" : product_id, "year" : year, "third_person_response" : 1, "channel_customer_id" : PreferabliTools.getCustomerId()] as [String : Any]
                wiliResponse = try Preferabli.api.getAlamo().get(APIEndpoints.wili(), params: params)
                wiliResponse = try PreferabliTools.continueOrThrowPreferabliException(response: wiliResponse)
            } else {
                let params = ["product_id" : product_id, "year" : year, "third_person_response" : 1, "user_id" : PreferabliTools.getPreferabliUserId()] as [String : Any]
                wiliResponse = try Preferabli.api.getAlamo().get(APIEndpoints.wili(), params: params)
                wiliResponse = try PreferabliTools.continueOrThrowPreferabliException(response: wiliResponse)
            }
            
            let wiliData = PreferenceData(map: try PreferabliTools.continueOrThrowJSONException(data: wiliResponse.data!) as! [String : Any])
            
            try canWeContinue(needsToBeLoggedIn: true)
            
            DispatchQueue.main.async {
                onCompletion(wiliData)
                Preferabli.wiliDictionary[product_id] = false
            }
        } catch {
            Preferabli.wiliDictionary[product_id] = false
            self.handleError(error: error, onFailure: onFailure)
        }
    }
    
    
    /// Edit an existing ``Tag``.
    /// - Parameters:
    ///   - tag_id: id of the ``Tag`` that needs to be edited.
    ///   - tag_type: type of the tag you wish to edit. This value is not editable. Can be either ``TagType/RATING``, ``TagType/CELLAR``, ``TagType/PURCHASE``, or ``TagType/WISHLIST``.
    ///   - year: year of the ``Variant``. Can use ``Variant/CURRENT_VARIANT_YEAR`` if you want the latest variant, or ``Variant/NON_VARIANT`` if the product is not vintaged.
    ///   - rating: pass one of ``RatingType/LOVE``, ``RatingType/LIKE``, ``RatingType/SOSO``, ``RatingType/DISLIKE``. Pass ``RatingType/NONE`` is not a rating. Defaults to ``RatingType/NONE``.
    ///   - location: location of the tag. Defaults to *nil*.
    ///   - notes: any notes to go along with the tag. Defaults to *nil*.
    ///   - price: price of the product tagged. Defaults to *nil*.
    ///   - quantity: quantity purchased of the product tagged. Defaults to *nil*.
    ///   - format_ml: size of the product tagged in milliliters. Defaults to *nil*.
    ///   - onCompletion: returns ``Product`` if the call was successful. *Returns on the main thread.*
    ///   - onFailure: returns ``PreferabliException``  if the call fails. *Returns on the main thread.*
    public func editTag(tag_id : NSNumber, tag_type : TagType, year : NSNumber, rating : RatingType = .NONE, location : String? = nil, notes : String? = nil, price : NSNumber? = nil, quantity : NSNumber? = nil, format_ml : NSNumber? = nil, onCompletion : @escaping (Product) -> () = {_ in }, onFailure : @escaping (PreferabliException) -> () = {_ in }) {
        PreferabliTools.startNewWorkThread(priority: .veryHigh, {
            self.editTagActual(tag_id: tag_id, tag_type: tag_type, year: year, value: rating.getValue(), location: location, notes: notes, price: price, quantity: quantity, format_ml: format_ml, onCompletion: onCompletion, onFailure: onFailure)
        })
    }
    
    private func editTagActual(tag_id : NSNumber, tag_type : TagType, year : NSNumber, value : String?, location : String?, notes : String?, price : NSNumber?, quantity : NSNumber?, format_ml : NSNumber?, onCompletion : @escaping (Product) -> (), onFailure : @escaping (PreferabliException) -> ()) {
        do {
            try canWeContinue(needsToBeLoggedIn: true)
            
            let context = NSManagedObjectContext.mr_()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            let tagDictionary = ["location" : location ?? "", "comment" : notes ?? "", "value" : value ?? "", "year" : year, "price" : price ?? 0, "quantity" : quantity ?? 0, "format_ml" : format_ml ?? 0 ] as [String : Any]
            
            var tagResponseDictionary : Any?
            if (Preferabli.isPreferabliUserLoggedIn()) {
                let collection_id : NSNumber
                if (tag_type == .RATING) {
                    collection_id = NSNumber.init(value: PreferabliTools.getKeyStore().integer(forKey: "ratings_id"))
                } else if (tag_type == .WISHLIST) {
                    collection_id = NSNumber.init(value: PreferabliTools.getKeyStore().integer(forKey: "wishlist_id"))
                } else {
                    return
                }
                var tagResponse = try Preferabli.api.getAlamo().put(APIEndpoints.tag(collectionId: collection_id, tagId: tag_id), json: tagDictionary)
                tagResponse = try PreferabliTools.continueOrThrowPreferabliException(response: tagResponse)
                tagResponseDictionary = try PreferabliTools.continueOrThrowJSONException(data: tagResponse.data!)
            } else {
                var tagResponse = try Preferabli.api.getAlamo().put(APIEndpoints.customerTag(id: Preferabli.CHANNEL_ID, customerId: PreferabliTools.getCustomerId(), tagId: tag_id), json: tagDictionary)
                tagResponse = try PreferabliTools.continueOrThrowPreferabliException(response: tagResponse)
                tagResponseDictionary = try PreferabliTools.continueOrThrowJSONException(data: tagResponse.data!)
            }
            
            let tag = CoreData_Tag.mr_import(from: tagResponseDictionary!, in: context)
            let variant_id = tag.variant_id
            
            var variant = CoreData_Variant.mr_findFirst(byAttribute: "id", withValue: variant_id, in: context)
            var product : CoreData_Product?
            
            if (variant == nil) {
                var getProductsResponse = try Preferabli.api.getAlamo().get(APIEndpoints.products, params: ["variant_ids" : [ variant_id ]])
                getProductsResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getProductsResponse)
                let productDictionaries = try PreferabliTools.continueOrThrowJSONException(data: getProductsResponse.data!) as! NSArray
                for productDictionary in productDictionaries {
                    product = CoreData_Product.mr_import(from: productDictionary, in: context)
                    variant = product!.getVariantWithId(id: variant_id)
                }
            } else {
                product = variant!.product
            }
            
            tag.variant = variant!
            
            let productToReturn = Product.init(product: product!)
            
            try addMerchantDataToProducts(products: [ productToReturn ])
            
            try canWeContinue(needsToBeLoggedIn: true)
            
            DispatchQueue.main.async {
                onCompletion(productToReturn)
            }
            
        } catch {
            handleError(error: error, onFailure: onFailure)
        }
    }
}
