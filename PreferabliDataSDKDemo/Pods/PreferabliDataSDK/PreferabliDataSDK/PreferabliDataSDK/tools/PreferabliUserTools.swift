//
//  PreferabliUserTools.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 10/10/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import MagicalRecord
import SwiftEventBus

internal class PreferabliUserTools {
    
    internal static var sharedInstance = PreferabliUserTools()
    private let tagSemaphore = DispatchSemaphore(value: 1)
    private let purchasesObject = NSObject()
    private let collectionsObject = NSObject()
    
    internal func getPurchaseHistory(forceRefresh : Bool, lock_to_integration : Bool) throws -> Array<Product> {
        objc_sync_enter(purchasesObject)
        defer { objc_sync_exit(purchasesObject) }
        
        let context = NSManagedObjectContext.mr_()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        if (forceRefresh || !PreferabliTools.getKeyStore().bool(forKey: "hasLoadedPurchaseHistory")) {
            try getPurchaseHistoryFromAPI(context: context, priority: .normal, forceRefresh: forceRefresh)
        } else if (PreferabliTools.has5MinutesPassed(startDate: PreferabliTools.getKeyStore().object(forKey: "lastCalledPurchaseHistory") as? Date)) {
            PreferabliTools.startNewWorkThread(priority: .low) {
                do {
                    let context = NSManagedObjectContext.mr_()
                    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                    
                    try self.getPurchaseHistoryFromAPI(context: context, priority: .low, forceRefresh: false)
                } catch {
                    // catching here so that we can still pull up our saved data
                }
            }
        }
        
        let purchaseCollections = (CoreData_UserCollection.mr_find(byAttribute: "relationship_type", withValue: "purchase", in: context) as! [CoreData_UserCollection]).map() { $0.collection! }
        var predicates = Array<NSPredicate>()
        for collection in purchaseCollections {
            if (!lock_to_integration || (lock_to_integration && collection.channel_id?.intValue == PreferabliTools.getKeyStore().integer(forKey: "CHANNEL_ID"))) {
                predicates.append(NSPredicate(format: "SUBQUERY(variants, $v, ANY $v.tags.collection_id == %d).@count != 0", collection.id))
            }
        }
        
        let predicate = NSCompoundPredicate.init(orPredicateWithSubpredicates: predicates)
        let products = CoreData_Product.mr_findAll(with: predicate, in: context) as! [CoreData_Product]
        
        var productsToReturn = Array<Product>()
        for product in products {
            productsToReturn.append(Product.init(product: product))
        }
        
        return productsToReturn
    }
    
    private func getPurchaseHistoryFromAPI(context : NSManagedObjectContext, priority : Operation.QueuePriority, forceRefresh : Bool) throws {
        
        let purchaseCollections = try getUserCollections(context: context, forceRefresh: forceRefresh, relationship_type: "purchase").map() { $0.collection }
        
        let dispatchGroup = DispatchGroup()
        var noErrors = true
        
        for collection in purchaseCollections {
            if (PreferabliTools.isLoggedOutOrLoggingOut()) {
                return
            }
            
            if (collection == nil) {
                continue
            }
            
            let groupOperation = BlockOperation()
            groupOperation.addExecutionBlock { () -> Void in
                defer { dispatchGroup.leave() }
                do {
                    let context = NSManagedObjectContext.mr_()
                    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                    try LoadCollectionTools.sharedInstance.loadCollectionViaTags(in: context, priority: priority, with: collection!.id)
                } catch {
                    // failed
                    noErrors = false
                }
            }
            dispatchGroup.enter()
            
            if (PreferabliTools.isLoggedOutOrLoggingOut()) {
                return
            }
            
            PreferabliTools.startNewWorkThread(priority: priority, operation: groupOperation)
        }
        
        dispatchGroup.wait()
        
        if (!noErrors) {
            throw PreferabliException.init(type: .NetworkError)
        }
        
        
        if (PreferabliTools.isLoggedOutOrLoggingOut()) {
            return
        }
        
        PreferabliTools.getKeyStore().set(Date.init(), forKey: "lastCalledPurchaseHistory")
        PreferabliTools.getKeyStore().set(true, forKey: "hasLoadedPurchaseHistory")
    }
    
    internal func getUserCollections(context : NSManagedObjectContext, forceRefresh : Bool, relationship_type : String) throws -> Array<CoreData_UserCollection> {
        objc_sync_enter(collectionsObject)
        defer { objc_sync_exit(collectionsObject) }
        
        if (forceRefresh || !PreferabliTools.getKeyStore().bool(forKey: "hasLoadedUserCollections")) {
            try getUserCollections(in: context)
        } else if (PreferabliTools.has5MinutesPassed(startDate: PreferabliTools.getKeyStore().object(forKey: "lastCalledUserCollections") as? Date)) {
            PreferabliTools.startNewWorkThread(priority: .low, {
                do {
                    let context = NSManagedObjectContext.mr_()
                    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                    try self.getUserCollections(in: context)
                } catch {
                    // catching here so that we can still pull up our saved data
                }
            })
        }
        
        let userCollections = CoreData_UserCollection.mr_find(byAttribute: "relationship_type", withValue: relationship_type, in: context) as! [CoreData_UserCollection]
        return userCollections
    }
    
    private func getUserCollections(in context : NSManagedObjectContext) throws {
        let userCollections = CoreData_UserCollection.mr_findAll(in: context) as! [CoreData_UserCollection]
        
        var noErrorsForRefreshOperation = true
        var hasNotReachedEndForRefreshOperation = true
        var offset = 0
        let limit = 50
        let dispatchGroup = DispatchGroup()
        var userCollectionIds = Array<NSManagedObjectID>()
        
        while (hasNotReachedEndForRefreshOperation) {
            if (PreferabliTools.isLoggedOutOrLoggingOut()) {
                return
            }
            let (noErrors, newids) = getUserCollectionsFromAPI(dispatchGroup: dispatchGroup, offset: &offset, limit: limit)
            noErrorsForRefreshOperation = noErrors
            userCollectionIds.append(contentsOf: newids)
            if (newids.count != (limit * 5)) {
                hasNotReachedEndForRefreshOperation = false
            }
            
            dispatchGroup.wait()
            
            if (!noErrorsForRefreshOperation) {
                throw PreferabliException.init(type: .NetworkError)
            }
        }
        
        // Delete old User Collections.
        for userCollection in userCollections {
            if (!userCollectionIds.contains(userCollection.objectID)) {
                userCollection.mr_deleteEntity(in: context)
            }
        }
        
        if (PreferabliTools.isLoggedOutOrLoggingOut()) {
            return
        }
        
        context.mr_saveToPersistentStoreAndWait()
        
        PreferabliTools.getKeyStore().set(Date.init(), forKey: "lastCalledUserCollections")
        PreferabliTools.getKeyStore().set(true, forKey: "hasLoadedUserCollections")
    }
    
    private func getUserCollectionsFromAPI(dispatchGroup : DispatchGroup, offset : inout Int, limit : Int) -> (Bool, Array<NSManagedObjectID>) {
        let offsetNotEdited = offset
        var userCollectionIds = Array<NSManagedObjectID>()
        var noErrorsForRefreshOperation = true
        while (offset <= (offsetNotEdited * 5)) {
            let refreshOperation = BlockOperation()
            let offsetInside = offset
            
            refreshOperation.addExecutionBlock { () -> Void in
                do {
                    defer { dispatchGroup.leave() }
                    
                    if (refreshOperation.isCancelled || PreferabliTools.isLoggedOutOrLoggingOut()) {
                        return
                    }
                    
                    let context = NSManagedObjectContext.mr_()
                    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                    
                    let params = ["offset" : offsetInside, "limit" : limit]
                    var getUserCollectionsResponse = try Preferabli.api.getAlamo().get(APIEndpoints.userCollections(), params: params)
                    getUserCollectionsResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getUserCollectionsResponse)
                    let userCollectionDictionaries = try PreferabliTools.continueOrThrowJSONException(data: getUserCollectionsResponse.data!) as! NSArray
                    var channelIds = Array<NSNumber>()
                    var channelMap = [NSNumber : CoreData_UserCollection]()
                    var userCollections = Array<CoreData_UserCollection>()
                    for userCollection in userCollectionDictionaries {
                        let userCollection = CoreData_UserCollection.mr_import(from: userCollection, in: context)
                        userCollections.append(userCollection)
                        if (userCollection.collection!.channel_id != nil) {
                            channelIds.append(userCollection.collection!.channel_id!)
                            channelMap[userCollection.collection!.channel_id!] = userCollection
                        }
                    }
                    
                    if (refreshOperation.isCancelled || PreferabliTools.isLoggedOutOrLoggingOut()) {
                        return
                    }
                    
                    context.mr_saveToPersistentStoreAndWait()
                    
                    userCollectionIds.append(contentsOf: userCollections.map { $0.objectID })
                    
                } catch {
                    noErrorsForRefreshOperation = false
                }
            }
            
            
            dispatchGroup.enter()
            PreferabliTools.startNewWorkThread(operation: refreshOperation)
            offset = offset + limit
        }
        
        return (noErrorsForRefreshOperation, userCollectionIds)
    }
}
