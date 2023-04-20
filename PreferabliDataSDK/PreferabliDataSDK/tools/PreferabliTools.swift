//
//  PreferabliTools.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 10/10/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import CoreData
import MagicalRecord
import SwiftEventBus
import CoreLocation
import SwiftEventBus
import AVFoundation
import Contacts
import Photos
import Mixpanel

/// Contains lots of helper methods for private use within Preferabli's projects.
internal class PreferabliTools {
    
    private static let logoutDispatchGroup = DispatchGroup()
    private static var loggingOut = false
    
    private static let operationQueue = OperationQueue()
    private static let apiOperationQueue = OperationQueue()
        
    internal class func isLoggedOutOrLoggingOut() -> Bool {
        return loggingOut || (!isPreferabliUserLoggedIn() && !isCustomerLoggedIn())
    }
    
    internal class func startNewWorkThread(_ block: @escaping @convention(block) () -> Void, priority : Operation.QueuePriority) {
        startNewWorkThread(priority: priority, block)
    }
    
    internal class func startNewWorkThread(_ block: @escaping @convention(block) () -> Void) {
        startNewWorkThread(priority: .high, block)
    }
    
    internal class func startNewWorkThread(priority : Operation.QueuePriority, _ block: @escaping @convention(block) () -> Void) {
        let operation = BlockOperation()
        operation.addExecutionBlock {
            block()
        }
        startNewWorkThread(priority : priority, operation: operation)
    }
    
    internal class func startNewWorkThread(operation : Operation) {
        startNewWorkThread(priority: .high, operation: operation)
    }
    
    internal class func startNewWorkThread(priority : Operation.QueuePriority, operation : Operation) {
        operation.queuePriority = priority
        operationQueue.maxConcurrentOperationCount = 30
        operationQueue.addOperation(operation)
    }
    
    internal class func startNewAPIWorkThread(priority : Operation.QueuePriority, operation : Operation) {
        operation.queuePriority = priority
        apiOperationQueue.maxConcurrentOperationCount = 10
        apiOperationQueue.addOperation(operation)
    }
    
    internal class func saveCollectionEtag(response : DataResponse<Data>, collectionId : NSNumber) {
        if (response.response != nil) {
            let headers = response.response!.allHeaderFields
            if (!isNullOrWhitespace(string: headers["collection_etag"] as? String)) {
                var collectionEtags = PreferabliTools.getKeyStore().stringArray(forKey: "collection_etags_" + collectionId.stringValue) ?? Array<String>()
                if (!collectionEtags.contains(headers["collection_etag"] as! String)) {
                    collectionEtags.append(headers["collection_etag"] as! String)
                    PreferabliTools.getKeyStore().set(collectionEtags, forKey: "collection_etags_" + collectionId.stringValue)
                }
            }
        }
    }
    
    internal class func hasBeenLoaded(response : DataResponse<Data>, collectionId : NSNumber) -> Bool {
        if (response.response != nil && PreferabliTools.getKeyStore().bool(forKey: "hasLoaded" + collectionId.stringValue)) {
            let headers = response.response!.allHeaderFields
            if (!isNullOrWhitespace(string: headers["collection_etag"] as? String)) {
                let collectionEtags = PreferabliTools.getKeyStore().stringArray(forKey: "collection_etags_" + collectionId.stringValue) ?? Array<String>()
                if (collectionEtags.contains(headers["collection_etag"] as! String)) {
                    return true
                }
            }
        }
        
        return false
    }
    
    internal class func getTimezoneWithOffset(identifier : String) -> String {
        let timezone = TimeZone.init(identifier: identifier)!
        let seconds = timezone.secondsFromGMT()
        let hours = seconds/3600
        let minutes = abs(seconds/60) % 60
        return "(GMT" + String(format: "%+.2d:%.2d", hours, minutes) + ") " + timezone.localizedName(for: NSTimeZone.NameStyle.standard, locale: Locale.current)!
    }
    
    internal class func sortTimezonesByOffset(timezones: [TimeZone]) -> Array<TimeZone> {
        return timezones.sorted {
            if ($0.secondsFromGMT() == $1.secondsFromGMT()) {
                return $0.localizedName(for: NSTimeZone.NameStyle.standard, locale: Locale.current)!.caseInsensitiveCompare($1.localizedName(for: NSTimeZone.NameStyle.standard, locale: Locale.current)!) == ComparisonResult.orderedAscending
            }
            return $0.secondsFromGMT() < $1.secondsFromGMT()
        }
    }
    
    internal class func isKeyPresentInKeyStore(key: String) -> Bool {
        return PreferabliTools.getKeyStore().object(forKey: key) != nil
    }
    
    internal class func getKeyStore() -> UserDefaults {
        return UserDefaults.init(suiteName: "Preferabli")!
    }
    
    internal class func continueOrThrowPreferabliException(response : DataResponse<Data>) throws -> DataResponse<Data> {
        if (response.error == nil && response.response != nil && response.response!.statusCode >= 200 && response.response!.statusCode < 300) {
            if (Preferabli.loggingEnabled) {
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)")
                }
            }
            return response
        } else if (response.response != nil && response.data != nil) {
            if (response.response!.statusCode == 401) {
                let parameters = ["user_id": getPreferabliUserId(), "token_refresh" : PreferabliTools.getKeyStore().string(forKey: "refresh_token") ?? ""] as [String : Any]
                do {
                    let sessionResponse = try Preferabli.api.getAlamo().post(APIEndpoints.postSession, jsonObject: parameters)
                    if (sessionResponse.error == nil && sessionResponse.response != nil && sessionResponse.response!.statusCode < 400) {
                        _ = SessionData(map: try continueOrThrowJSONException(data: sessionResponse.data!) as! [String : Any])
                        
                        if (response.request!.httpMethod!.lowercased() == "get" || response.request!.httpMethod!.lowercased() == "delete") {
                            return try Preferabli.api.getAlamo().syncRequest(url: response.request!.url!, method: HTTPMethod(rawValue: response.request!.httpMethod!)!, parameters: nil, encoding: URLEncoding.default, headers: response.request!.allHTTPHeaderFields)
                        } else if (response.request!.httpBody != nil) {
                            return try Preferabli.api.getAlamo().syncRequest(urlString: response.request!.url!.absoluteString, method: response.request!.httpMethod!, jsonObject: response.request!.httpBody!)
                        }
                    } else {
                        throw PreferabliException.init(type: .APIError, code: response.response!.statusCode)
                    }
                } catch {
                    logout()
                    throw PreferabliException.init(type: .APIError, code: response.response!.statusCode)
                }
            }
            let errorDictionary = try continueOrThrowJSONException(data: response.data!) as? [String : Any]
            if (errorDictionary == nil) {
                throw PreferabliException.init(type: .APIError, code: response.response!.statusCode)
            }
            let error = APIError(map: errorDictionary!)
            if (error.message != nil) {
                throw PreferabliException.init(error: error)
            } else {
                throw PreferabliException.init(type: .APIError, code: response.response!.statusCode)
            }
        } else {
            throw PreferabliException.init(type: .NetworkError)
        }
    }
    
    internal class func continueOrThrowJSONException(data : Data) throws -> Any {
        do {
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            // report malformed JSON
            SwiftEventBus.post("PreferabliDataSDKAnalytics", sender: ["event" : "error", "type" : "JSON", "data" : data.base64EncodedString()])
            throw PreferabliException.init(type: .JSONError)
        }
    }
    
    internal class func setupAnalyticsListeners() {
        SwiftEventBus.onMainThread(self, name: "PreferabliDataSDKAnalytics") { result in
            var dictionary = result?.object as! [String : Any]
            let event = dictionary["event"] as! String
            dictionary.removeValue(forKey: "event")
            Mixpanel.mainInstance().track(event: event, properties: convertDictionaryToMixpanelProperties(dictionary: dictionary))
        }
        
        SwiftEventBus.onMainThread(self, name: "PreferabliDataSDKAnalyticsSuper") { result in
            let dictionary = result?.object as! [String : Any]
            Mixpanel.mainInstance().registerSuperPropertiesOnce(convertDictionaryToMixpanelProperties(dictionary: dictionary))
        }
        
        SwiftEventBus.onMainThread(self, name: "PreferabliDataSDKAnalyticsPeople") { result in
            let dictionary = result?.object as! [String : Any]
            Mixpanel.mainInstance().people.set(properties: convertDictionaryToMixpanelProperties(dictionary: dictionary))
        }
        
        SwiftEventBus.onMainThread(self, name: "PreferabliDataSDKAnalyticsPeopleNumeric") { result in
            let dictionary = result?.object as! [String : Any]
            let property = dictionary["property"] as! String
            let doubleVal : Double
            if let value = dictionary["value"] as? Double {
                doubleVal = value
            } else {
                doubleVal = Double(dictionary["value"] as! Int)
            }
            
            Mixpanel.mainInstance().people.increment(property: property, by: doubleVal)
        }
    }
    
    internal class func convertDictionaryToMixpanelProperties(dictionary : [String : Any]) -> [String : MixpanelType] {
        var properties = [String : MixpanelType]()
        for (key, value) in dictionary {
            if let val = value as? String {
                properties[key] = val
            } else if let val = value as? Int {
                properties[key] = val
            } else if let val = value as? Bool {
                properties[key] = val
            } else if let val = value as? Double {
                properties[key] = val
            } else if let val = value as? Float {
                properties[key] = val
            } else if let val = value as? Date {
                properties[key] = val
            } else if let val = value as? URL {
                properties[key] = val
            } else if let val = value as? NSNull {
                properties[key] = val
            } else if let val = value as? [MixpanelType] {
                properties[key] = val
            }
        }
        return properties
    }
    
    internal class func addSDKProperties() {
        let id = PreferabliTools.isPreferabliUserLoggedIn() ? PreferabliTools.getPreferabliUserId() : PreferabliTools.getCustomerId()
        let email = PreferabliTools.getKeyStore().object(forKey: "email") as? String
        let phone = PreferabliTools.getKeyStore().object(forKey: "phone") as? String
        let display_name = PreferabliTools.getKeyStore().object(forKey: "displayName") as? String
        let isTeamRingIt = PreferabliTools.getKeyStore().bool(forKey: "isTeamRingIT")
        
        if (id.intValue != 0) {
            Mixpanel.mainInstance().identify(distinctId: id.stringValue)
            Mixpanel.mainInstance().people.set(properties: [(PreferabliTools.isPreferabliUserLoggedIn() ? "user_id" : "customer_id") : id, "is_team_ringit" : isTeamRingIt])
            
            if (!PreferabliTools.isNullOrWhitespace(string: email)) {
                Mixpanel.mainInstance().people.set(properties: ["$email": email!])
            }
            
            if (!PreferabliTools.isNullOrWhitespace(string: phone)) {
                Mixpanel.mainInstance().people.set(properties: ["phone": phone!])
            }
            
            if (!PreferabliTools.isNullOrWhitespace(string: display_name)) {
                Mixpanel.mainInstance().people.set(properties: ["display_name": display_name!])
            }
        }
    }
    
    internal class func calculateDistanceInMiles(lat1 : NSNumber?, lon1 : NSNumber?, lat2 : NSNumber?, lon2 : NSNumber?) -> Int? {
        if (lat1 == nil || lat1 == 0 || lat2 == nil || lat2 == 0 || lon1 == nil || lon1 == 0 || lon2 == nil || lon2 == 0) {
            return nil
        }
        let coordinate1 = CLLocation(latitude: lat1 as! CLLocationDegrees, longitude: lon1 as! CLLocationDegrees)
        let coordinate2 = CLLocation(latitude: lat2 as! CLLocationDegrees, longitude: lon2 as! CLLocationDegrees)
        
        let distanceInMeters = coordinate1.distance(from: coordinate2)
        let distanceInMiles = distanceInMeters / 1609.344
        return Int(distanceInMiles)
    }
    
    internal class func getPreferabliUserId() -> NSNumber {
        return NSNumber.init(value: PreferabliTools.getKeyStore().integer(forKey: "user_id"))
    }
    
    internal class func getCustomerId() -> NSNumber {
        return NSNumber.init(value: PreferabliTools.getKeyStore().integer(forKey: "customer_id"))
    }
    
    internal class func getUserImage() -> String {
        return PreferabliTools.getKeyStore().string(forKey: "avatar") ?? ""
    }
    
    internal class func isUserLocked() -> Bool {
        return PreferabliTools.getKeyStore().integer(forKey: "accountLevel") != 2
    }
    
    internal class func getAPIDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }
    
    internal class func setUserProperties(user : PreferabliUser) {
        // set user properties to defaults
        PreferabliTools.getKeyStore().set(user.id, forKey: "user_id")
        PreferabliTools.getKeyStore().set(user.fname, forKey: "firstName")
        PreferabliTools.getKeyStore().set(user.lname, forKey: "lastName")
        PreferabliTools.getKeyStore().set(user.display_name, forKey: "displayName")
        PreferabliTools.getKeyStore().set(user.account_level, forKey: "accountLevel")
        PreferabliTools.getKeyStore().set(user.birthyear, forKey: "birthYear")
        PreferabliTools.getKeyStore().set(user.country, forKey: "country")
        PreferabliTools.getKeyStore().set(user.avatar?.path, forKey: "avatar")
        PreferabliTools.getKeyStore().set(user.gender, forKey: "gender")
        PreferabliTools.getKeyStore().set(user.zip_code, forKey: "zipCode")
        PreferabliTools.getKeyStore().set(user.subscribed, forKey: "subscribed")
        PreferabliTools.getKeyStore().set(user.email, forKey: "email")
        PreferabliTools.getKeyStore().set(user.is_team_ringit, forKey: "isTeamRingIT")
        PreferabliTools.getKeyStore().set(user.rating_collection_id, forKey: "ratings_id")
        PreferabliTools.getKeyStore().set(user.wishlist_collection_id, forKey: "wishlist_id")
        PreferabliTools.getKeyStore().set(user.claim_code, forKey: "claim_code")
        PreferabliTools.getKeyStore().set(user.admin == 1, forKey: "isAdmin")
        PreferabliTools.getKeyStore().set(user.provided_feedback_at, forKey: "feedbackDate")
        PreferabliTools.getKeyStore().set(user.intercom_hmac, forKey: "intercom_hmac")
    }
    
    internal class func logout() {
        if (loggingOut) {
            return
        }
        loggingOut = true
        logoutDispatchGroup.wait()
        logoutDispatchGroup.enter()
        
        operationQueue.cancelAllOperations()
        apiOperationQueue.cancelAllOperations()
        
        clearAllData()
        
        logoutDispatchGroup.leave()
        loggingOut = false
    }
    
    internal class func createUserFromUserDefaults(context : NSManagedObjectContext) -> CoreData_PreferabliUser {
        let context = NSManagedObjectContext.mr_()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        let user = CoreData_PreferabliUser.mr_createEntity(in: context)!
        if (PreferabliTools.getKeyStore().object(forKey: "user_id") == nil) {
            return user
        }
        user.id = PreferabliTools.getKeyStore().object(forKey: "user_id") as! NSNumber
        user.fname = PreferabliTools.getKeyStore().object(forKey: "firstName") as? String
        user.lname = PreferabliTools.getKeyStore().object(forKey: "lastName") as? String
        user.display_name = PreferabliTools.getKeyStore().object(forKey: "displayName") as? String
        user.account_level = PreferabliTools.getKeyStore().object(forKey: "accountLevel") as? NSNumber
        user.birthyear = PreferabliTools.getKeyStore().object(forKey: "birthYear") as? NSNumber
        user.country = PreferabliTools.getKeyStore().object(forKey: "country") as? String
        user.gender = PreferabliTools.getKeyStore().object(forKey: "gender") as? String
        user.zip_code = PreferabliTools.getKeyStore().object(forKey: "zipCode") as? String
        user.subscribed = PreferabliTools.getKeyStore().bool(forKey: "subscribed")
        user.isNotHideable = PreferabliTools.getKeyStore().bool(forKey: "isNotHideable")
        user.isHidden = PreferabliTools.getKeyStore().bool(forKey: "isHidden")
        user.email = PreferabliTools.getKeyStore().object(forKey: "email") as? String
        user.claim_code = PreferabliTools.getKeyStore().object(forKey: "claim_code") as? String
        user.rating_collection_id = PreferabliTools.getKeyStore().object(forKey: "ratings_id") as? NSNumber
        user.wishlist_collection_id = PreferabliTools.getKeyStore().object(forKey: "wishlist_id") as? NSNumber
        
        if let avatarPath = PreferabliTools.getKeyStore().object(forKey: "avatar") as? String {
            let avatar = CoreData_Media.mr_createEntity(in: context)!
            avatar.path = avatarPath
            user.avatar = avatar
        }
        
        return user
    }

    internal class func clearAllData() {
        // delete all from core data
        clearDatabase()
        
        // clear HTTP cache
        Preferabli.api.clearUrlCache()
        Preferabli.api.refreshDefaults()
        
        let integration_id = PreferabliTools.getKeyStore().integer(forKey: "INTEGRATION_ID")
        let client_interface = PreferabliTools.getKeyStore().string(forKey: "CLIENT_INTERFACE")
        
        UserDefaults.standard.removePersistentDomain(forName: "Preferabli")
        
        PreferabliTools.getKeyStore().set(integration_id, forKey: "INTEGRATION_ID")
        PreferabliTools.getKeyStore().set(client_interface, forKey: "CLIENT_INTERFACE")
    }
    
    internal class func clearDatabase() {
        MagicalRecord.cleanUp()
        
        var removeError: NSError?
        let deleteSuccess: Bool
        do {
            guard let url = NSPersistentStore.mr_url(forStoreName: "PreferabliSDK.sqlite") else {
                return
            }
            let walUrl = url.deletingPathExtension().appendingPathExtension("sqlite-wal")
            let shmUrl = url.deletingPathExtension().appendingPathExtension("sqlite-shm")
            
            try FileManager.default.removeItem(at: url)
            try FileManager.default.removeItem(at: walUrl)
            try FileManager.default.removeItem(at: shmUrl)
            
            deleteSuccess = true
        } catch let error as NSError {
            removeError = error
            deleteSuccess = false
        }
        
        if deleteSuccess {
            setupCoreDataStack()
        } else {
            if (Preferabli.loggingEnabled) {
                print("An error has occured while deleting the database")
                print("Error description: \(removeError.debugDescription)")
            }
        }
    }
    
    internal class func getSymbolForCurrencyCode(currencyCode: String?) -> String {
        if (PreferabliTools.isNullOrWhitespace(string: currencyCode)) {
            return "$"
        }
        
        let code = currencyCode!
        var candidates: [String] = []
        let locales: [String] = NSLocale.availableLocaleIdentifiers
        for localeID in locales {
            guard let symbol = findMatchingSymbol(localeID: localeID, currencyCode: code) else {
                continue
            }
            if symbol.count == 1 {
                return symbol
            }
            candidates.append(symbol)
        }
        let sorted = sortStringsByLength(list: candidates)
        if sorted.count < 1 {
            return ""
        }
        return sorted[0]
    }
    
    internal class func getLocaleForCurrencyCode(currencyCode: String?) -> Locale {
        if (PreferabliTools.isNullOrWhitespace(string: currencyCode)) {
            return Locale.current
        }
        
        let code = currencyCode!
        var candidates: [String] = []
        let locales: [String] = NSLocale.availableLocaleIdentifiers
        for localeID in locales {
            guard let symbol = findMatchingSymbol(localeID: localeID, currencyCode: code) else {
                continue
            }
            if symbol.count == 1 {
                return  Locale(identifier: localeID as String)
            }
            candidates.append(localeID)
        }
        let sorted = sortStringsByLength(list: candidates)
        if sorted.count < 1 {
            return Locale.current
        }
        return Locale(identifier: sorted[0] as String)
    }
    
    internal class func findMatchingSymbol(localeID: String, currencyCode: String) -> String? {
        let locale = Locale(identifier: localeID as String)
        guard let code = locale.currencyCode else {
            return nil
        }
        if code != currencyCode {
            return nil
        }
        guard let symbol = locale.currencySymbol else {
            return nil
        }
        return symbol
    }
    
    internal class func isPreferabliUserLoggedIn() -> Bool {
        let accessToken = PreferabliTools.getKeyStore().string(forKey: "access_token")
        let userId = getPreferabliUserId()
        return accessToken != nil && userId != 0
    }
    
    internal class func isCustomerLoggedIn() -> Bool {
        let accessToken = PreferabliTools.getKeyStore().string(forKey: "access_token")
        let customerId = getCustomerId()
        return accessToken != nil && customerId != 0
    }
    
    internal class func resizeImage(image: UIImage, newDimension: CGFloat) -> UIImage? {
        var newHeight : CGFloat
        var newWidth : CGFloat
        
        if (image.size.width <= newDimension && image.size.height <= newDimension) {
            return image
        } else if (image.size.width > image.size.height) {
            newWidth = newDimension
            let scale = newWidth / image.size.width
            newHeight = image.size.height * scale
        } else {
            newHeight = newDimension
            let scale = newHeight / image.size.height
            newWidth = image.size.width * scale
        }
        
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    internal class func isNullOrWhitespace(string : String?) -> Bool {
        if (string == nil) {
            return true
        }
        
        return string!.isEmptyOrWhitespace()
    }
    
    internal class func isNullOrWhitespace(string : NSAttributedString?) -> Bool {
        if (string == nil) {
            return true
        }
        
        return string!.isEmptyOrWhitespace()
    }
    
    internal class func generateRandomLongId() -> Int32 {
        return -Int32(arc4random() % 28147497)
    }
    
    internal class func hasDaysPassed(days: Int, startDate: Date?) -> Bool {
        if let startDate = startDate {
            let calendar = NSCalendar.current
            let components = calendar.dateComponents([Calendar.Component.day], from: startDate, to: Date.init())
            return components.day! > (days - 1)
        } else {
            // never called API before!
            return true
        }
    }
    
    internal class func hasMinutesPassed(minutes: Int, startDate: Date?) -> Bool {
        if let startDate = startDate {
            let calendar = NSCalendar.current
            let components = calendar.dateComponents([Calendar.Component.minute], from: startDate, to: Date.init())
            return components.minute! > (minutes - 1)
        } else {
            // never called API before!
            return true
        }
    }
    
    internal class func alphaSortIgnoreThe(x : String, y : String) -> Bool {
        return alphaSortIgnoreThe(x: x, y: y, comparisonResult: ComparisonResult.orderedAscending)
    }
    
    internal class func alphaSortIgnoreThe(x : String, y : String, comparisonResult: ComparisonResult) -> Bool {
        var x = x
        var y = y
        if (isNullOrWhitespace(string: x)) {
            return false
        } else if (isNullOrWhitespace(string: y)) {
            return true
        }
        if (x.hasPrefix("The ")) {
            x = String(x[x.index(x.startIndex, offsetBy: 4)...])
        }
        if (y.hasPrefix("The ")) {
            y = String(y[y.index(x.startIndex, offsetBy: 4)...])
        }
        
        return x.caseInsensitiveCompare(y) == comparisonResult
    }
    
    internal class func setupCoreDataStack() {
        // initialize core data stack
        MagicalRecord.setShouldDeleteStoreOnModelMismatch(true)
        MagicalRecord.setShouldAutoCreateManagedObjectModel(false)
        MagicalRecord.setLoggingLevel(Preferabli.loggingEnabled ? .warn : .off)
        let frameworkBundle = Bundle.init(for: Preferabli.self)
        NSManagedObjectModel.mr_setDefaultManagedObjectModel(NSManagedObjectModel.mergedModel(from: [frameworkBundle,Bundle.main]))
        MagicalRecord.setupCoreDataStack(withAutoMigratingSqliteStoreNamed: "PreferabliSDK.sqlite")
    }
    
    internal class func databaseUpgraded() {
        clearDatabase()
                
        // going to do this on the main thread since it shouldn't take long
        if (isPreferabliUserLoggedIn()) {
            let context = NSManagedObjectContext.mr_default()
            _ = createUserFromUserDefaults(context: context)
            context.mr_saveToPersistentStoreAndWait()
        }
        
        for key in PreferabliTools.getKeyStore().dictionaryRepresentation().keys {
            if key.starts(with: "hasLoaded") {
                PreferabliTools.getKeyStore().set(false, forKey: key)
            }
            if key.starts(with: "collection_etags") || key.starts(with: "lastCalled") {
                PreferabliTools.getKeyStore().set(nil, forKey: key)
            }
        }
    }
    
    internal class func handleUpgrade() {
        let versionCode = Preferabli.versionCode
        let savedVersionCode = PreferabliTools.getKeyStore().integer(forKey: "versionCode")
        
        if (savedVersionCode != versionCode) {
            if (savedVersionCode == 0) {
                // new user do nothing for now
            } else {
                // user has upgraded the app always pull new data
                databaseUpgraded()
            }
            // we handled either possible situation so update the version code to current version
            PreferabliTools.getKeyStore().set(versionCode, forKey: "versionCode")
        }
    }
    
    internal class func sortStringsByLength(list: [String]) -> [String] {
        return list.sorted(by: { $0.count < $1.count })
    }
    
    internal class func getImageUrl(image : String?, width : CGFloat, height : CGFloat, quality : Int) -> URL? {
        if (isNullOrWhitespace(string: image)) {
            return nil
        }
        
        var image = image!
        if (image.contains("placeholder")) {
            return nil
        } else if (image.contains("winering.com") || image.contains("preferabli.com")) {
            return URL.init(string: image)
        } else if (image.contains("s3.amazonaws.com/winering-production")) {
            let index = image.range(of: "/", options: .backwards, range: nil, locale: nil)!.upperBound
            if (image.containsIgnoreCase("/avatars")) {
                image = "avatars/" + image.substring(from: index)
            } else {
                image = image.substring(from: index)
            }
        } else {
            return URL.init(string: image)
        }
        
        let cloudfrontAppId = "ios_sdk/fit-in/"
        let sizeString = String(Int(width * UIScreen.main.scale)) + "x" + String(Int(height * UIScreen.main.scale)) + "/"
        let qualityString = "filters:quality(" + String(quality) + ")/"
        let pngString = image.containsIgnoreCase("png") ? "filters:format(png)/"  : ""
        var cloudFrontURL = "https://dxlu3le4zp2pd.cloudfront.net/wineringlabel/" + cloudfrontAppId + sizeString + qualityString + pngString + image
        return URL.init(string: cloudFrontURL)
    }
}
