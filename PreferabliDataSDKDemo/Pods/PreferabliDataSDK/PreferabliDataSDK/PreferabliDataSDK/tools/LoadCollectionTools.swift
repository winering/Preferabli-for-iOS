//
//  LoadCollectionTools.swift
//  Preferabli
//
//  Created by Nicholas Bortolussi on 10/10/16.
//  Copyright © 2023 RingIT, Inc. All rights reserved.
//

import Foundation
import MagicalRecord
import SwiftEventBus

/// Contains methods that help load ``Collection``s.
internal class LoadCollectionTools {
    
    internal static var sharedInstance = LoadCollectionTools()
    
    internal func loadCollectionViaTags(in context : NSManagedObjectContext, priority : Operation.QueuePriority, force_refresh : Bool, with collection_id : NSNumber)  throws {
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
    }
    
    private func loadCollectionViaTags(in context : NSManagedObjectContext, priority : Operation.QueuePriority, with collectionId : NSNumber) throws {
        var tagIds = Array<NSNumber>()

        let predicate1 = NSPredicate(format: "collection_id == %d", collectionId.intValue)
        let predicate2 = NSPredicate(format: "dirty = %d || dirty == nil", false)
        let predicateCompound = NSCompoundPredicate.init(type: .and, subpredicates: [predicate1,predicate2])
        let oldTags = CoreData_Tag.mr_findAll(with: predicateCompound, in: context) as! [Tag]
        let collection = try getCollection(forceRefresh: false, collectionId: collectionId, context: context)

        if (PreferabliTools.isLoggedOutOrLoggingOut()) {
            return
        }

        tagIds.append(contentsOf: try getTagsAndProducts(collection: collection, priority: priority))

        for tag in oldTags {
            if (!tagIds.contains(tag.id)) {
                tag.collection_id = NSNumber.init(value: 0)
            }
        }

        PreferabliTools.getKeyStore().set(Date.init(), forKey: "lastCalled" + collectionId.stringValue)
        PreferabliTools.getKeyStore().set(true, forKey: "hasLoaded" + collectionId.stringValue)
        context.mr_saveToPersistentStoreAndWait()
    }

    internal func getCollection(forceRefresh : Bool, collectionId : NSNumber, context : NSManagedObjectContext) throws -> CoreData_Collection {
        var collection = CoreData_Collection.mr_findFirst(byAttribute: "id", withValue: collectionId, in: context)
        if (forceRefresh || collection == nil) {
            var getCollectionResponse = try Preferabli.api.getAlamo().get(APIEndpoints.collection(id: collectionId))
            getCollectionResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getCollectionResponse)
            PreferabliTools.saveCollectionEtag(response: getCollectionResponse, collectionId: collectionId)
            let collectionDictionary = try PreferabliTools.continueOrThrowJSONException(data: getCollectionResponse.data!)
            collection = CoreData_Collection.mr_import(from: collectionDictionary, in: context)
        }
        return collection!
    }
    
    internal func getTagsAndProducts(collection : CoreData_Collection, priority : Operation.QueuePriority) throws -> [NSNumber] {
        let collectionId = collection.id
        let dispatchGroup = DispatchGroup()
        let tagSemaphore = DispatchSemaphore(value: 1)

        var offset = 0
        let limit = 50
        var noErrors = true
        var tagIds = Array<NSNumber>()
        var errors = Array<PreferabliException>()

        while (offset <= collection.product_count.intValue) {

            let tagOperation = BlockOperation()
            let offsetForTagOperation = offset

            tagOperation.addExecutionBlock { () -> Void in
                do {
                    if (tagOperation.isCancelled || PreferabliTools.isLoggedOutOrLoggingOut()) {
                        return
                    }

                    let context = NSManagedObjectContext.mr_()
                    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

                    let collection = CoreData_Collection.mr_findFirst(byAttribute: "id", withValue: collectionId, in: context)

                    var getTagsResponse = try Preferabli.api.getAlamo().get(APIEndpoints.tags(id: collectionId), params: ["offset" : offsetForTagOperation, "limit" : limit])
                    getTagsResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getTagsResponse)

                    if (tagOperation.isCancelled || PreferabliTools.isLoggedOutOrLoggingOut()) {
                        return
                    }

                    let tagDictionaries = try PreferabliTools.continueOrThrowJSONException(data: getTagsResponse.data!) as! NSArray
                    var tags = Array<CoreData_Tag>()
                    var tagMap = [NSNumber : Array<CoreData_Tag>]()
                    for tag in tagDictionaries {
                        let tagObject = CoreData_Tag.mr_import(from: tag, in: context)
                        if (!tagObject.isRating()) {
                            tagObject.location = collection?.name
                        }
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

                    if (tagOperation.isCancelled || PreferabliTools.isLoggedOutOrLoggingOut()) {
                        return
                    }

                    if (tags.count != 0) {
                        let variantIds = tags.map { $0.variant_id }
                        var getProductsResponse = try Preferabli.api.getAlamo().get(APIEndpoints.products, params: ["variant_ids" : variantIds])
                        getProductsResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getProductsResponse)
                        let productDictionaries = try PreferabliTools.continueOrThrowJSONException(data: getProductsResponse.data!) as! NSArray
                        for product in productDictionaries {
                            let wineObject = CoreData_Product.mr_import(from: product, in: context)
                            for variant in wineObject.variants.allObjects as! [CoreData_Variant] {
                                if let tagArray = tagMap[variant.id] {
                                    for tag in tagArray {
                                        tag.variant = variant
                                    }
                                }
                            }
                        }

                        if (tagOperation.isCancelled || PreferabliTools.isLoggedOutOrLoggingOut()) {
                            return
                        }

                        let tagIdsHere = tags.map { $0.id }
                        dispatchGroup.enter()
                        tagSemaphore.wait()
                        tagIds.append(contentsOf: tagIdsHere)
                        tagSemaphore.signal()
                        dispatchGroup.leave()
                    }

                    if (tagOperation.isCancelled || PreferabliTools.isLoggedOutOrLoggingOut()) {
                        return
                    }

                    context.mr_saveToPersistentStoreAndWait()
                    dispatchGroup.leave()

                } catch {
                    errors.append(error as! PreferabliException)
                    noErrors = false
                    dispatchGroup.leave()
                }
            }


            dispatchGroup.enter()
            PreferabliTools.startNewAPIWorkThread(priority: priority, operation: tagOperation)
            offset = offset + limit
        }

        // wait until all operation queues are done executing before moving on
        dispatchGroup.wait()

        if (!noErrors) {
            if (errors.count > 0) {
                throw errors[0]
            } else {
                throw PreferabliException.init(type: .NetworkError)
            }
        }

        return tagIds
    }

    internal func loadCollectionViaOrderings(context : NSManagedObjectContext, priority : Operation.QueuePriority, collection : CoreData_Collection) throws {
        var tagIds = Array<NSNumber>()

        let collectionId = collection.id
        let predicate1 = NSPredicate(format: "collection_id == %d", collectionId)
        let predicate2 = NSPredicate(format: "dirty = %d || dirty == nil", false)
        let predicateCompound = NSCompoundPredicate.init(type: .and, subpredicates: [predicate1,predicate2])
        let oldTags = CoreData_Tag.mr_findAll(with: predicateCompound, in: context) as! [CoreData_Tag]

        let version = collection.getFirstVersion(context: context)

        let collectionGroups = version.groups.allObjects as! [CoreData_CollectionGroup]
        let limit = 50
        var noErrors = true
        var errors = Array<PreferabliException>()

        let dispatchGroup = DispatchGroup()
        outerLoop: for group in collectionGroups {
            var offset = 0
            while offset <= group.orderings_count.intValue {

                if (PreferabliTools.isLoggedOutOrLoggingOut()) {
                    return
                }

                let groupOperation = BlockOperation()
                let offsetForGroupOperation = offset
                let versionId = version.id
                let groupId = group.id
                groupOperation.addExecutionBlock { () -> Void in
                    do {
                        let context = NSManagedObjectContext.mr_()
                        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                        if (PreferabliTools.isLoggedOutOrLoggingOut()) {
                            return
                        }
                        let collection = CoreData_Collection.mr_findFirst(byAttribute: "id", withValue: collectionId, in: context)!
                        let group = CoreData_CollectionGroup.mr_findFirst(byAttribute: "id", withValue: groupId, in: context)!
                        try self.getGroupItems(context: context, operation: groupOperation, collection: collection, versionId: versionId, group: group, limit: limit, offset: offsetForGroupOperation, failCount: 0, dispatchGroup : dispatchGroup, tagIds: &tagIds)
                        dispatchGroup.leave()
                    } catch {
                        errors.append(error as! PreferabliException)
                        noErrors = false
                        dispatchGroup.leave()
                    }
                }
                dispatchGroup.enter()
                if (PreferabliTools.isLoggedOutOrLoggingOut()) {
                    return
                }
                PreferabliTools.startNewAPIWorkThread(priority: priority, operation: groupOperation)
                offset = offset + limit
            }
        }

        // wait until all operation queues are done executing before moving on
        dispatchGroup.wait()

        if (!noErrors) {
            if (errors.count > 0) {
                throw errors[0]
            } else {
                throw PreferabliException.init(type: .NetworkError)
            }
        }

        for tag in oldTags {
            if (!tagIds.contains(tag.id)) {
                tag.mr_deleteEntity(in: context)
            }
        }
        
        context.mr_saveToPersistentStoreAndWait()

        PreferabliTools.getKeyStore().set(Date.init(), forKey: "lastCalled" + collectionId.stringValue)
        PreferabliTools.getKeyStore().set(true, forKey: "hasLoaded" + collectionId.stringValue)
    }

    private func getGroupItems(context : NSManagedObjectContext, operation : BlockOperation, collection : CoreData_Collection, versionId : NSNumber, group : CoreData_CollectionGroup, limit : Int, offset : Int, failCount : Int, dispatchGroup : DispatchGroup, tagIds : inout Array<NSNumber>) throws {
        do {
            let collectionId = collection.id
            let tagSemaphore = DispatchSemaphore(value: 1)


            var getOrderingsResponse = try Preferabli.api.getAlamo().get(APIEndpoints.orderings(collectionId: collectionId, versionId: versionId, groupId: group.id), params: ["limit" : limit, "offset" : offset])
            getOrderingsResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getOrderingsResponse)
            PreferabliTools.saveCollectionEtag(response: getOrderingsResponse, collectionId: collectionId)
            let orderingDictionaries = try PreferabliTools.continueOrThrowJSONException(data: getOrderingsResponse.data!) as! Array<[String : Any]>
            var orderings = Array<CoreData_CollectionOrder>()
            for order in orderingDictionaries {
                let collectionOrder = CoreData_CollectionOrder.mr_import(from: order, in: context)
                orderings.append(collectionOrder)
                collectionOrder.group = group
            }

            if (operation.isCancelled || PreferabliTools.isLoggedOutOrLoggingOut()) {
                return
            }

            let tagIdsHere = orderingDictionaries.map { $0["tag_id"] }
            if (tagIdsHere.count != 0) {
                var getTagsResponse = try Preferabli.api.getAlamo().get(APIEndpoints.tags(id: collectionId), params: ["tag_ids" : tagIdsHere])
                getTagsResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getTagsResponse)
                PreferabliTools.saveCollectionEtag(response: getTagsResponse, collectionId: collectionId)
                let tagDictionaries = try PreferabliTools.continueOrThrowJSONException(data: getTagsResponse.data!) as! Array<[String : Any]>
                var tags = Array<CoreData_Tag>()
                for tag in tagDictionaries {
                    let tagObject = CoreData_Tag.mr_import(from: tag, in: context)
                    
                    // do this so we have collection name easily accesible for all tags. does not apply for ratings.
                    if (!tagObject.isRating()) {
                        tagObject.location = collection.name
                    }
                    tags.append(tagObject)
                }

                if (operation.isCancelled || PreferabliTools.isLoggedOutOrLoggingOut()) {
                    return
                }

                let variantIds = tagDictionaries.map { $0["variant_id"] }
                var getProductsResponse = try Preferabli.api.getAlamo().get(APIEndpoints.products, params: ["variant_ids" : variantIds])
                getProductsResponse = try PreferabliTools.continueOrThrowPreferabliException(response: getProductsResponse)
                let productDictionaries = try PreferabliTools.continueOrThrowJSONException(data: getProductsResponse.data!) as! NSArray
                for product in productDictionaries {
                    CoreData_Product.mr_import(from: product, in: context)
                }

                if (operation.isCancelled || PreferabliTools.isLoggedOutOrLoggingOut()) {
                    return
                }

                for order in orderings {
                    try order.setTag(in: context)
                }

                if (operation.isCancelled || PreferabliTools.isLoggedOutOrLoggingOut()) {
                    return
                }

                let tagObjectIds = tags.map { $0.id }
                dispatchGroup.enter()
                tagSemaphore.wait()
                tagIds.append(contentsOf: tagObjectIds)
                tagSemaphore.signal()
                dispatchGroup.leave()
            }

            if (operation.isCancelled || PreferabliTools.isLoggedOutOrLoggingOut()) {
                return
            }

            context.mr_saveToPersistentStoreAndWait()

        } catch let error as NSError {
            if (failCount > 1) {
                throw error
            } else {
                return try self.getGroupItems(context: context, operation: operation, collection: collection, versionId: versionId, group: group, limit: limit, offset: offset, failCount: failCount + 1, dispatchGroup: dispatchGroup, tagIds: &tagIds)
            }
        }
    }
}
