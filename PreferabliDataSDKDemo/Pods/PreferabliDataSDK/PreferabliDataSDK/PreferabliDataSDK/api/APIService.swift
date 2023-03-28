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

internal class APIService {
    
    private var alamo : SessionManager?
    private var urlCache : URLCache?
        
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

internal struct APIEndpoints {
    internal static let baseUrl = "https://api.preferabli.com/api/6.1/staging/"
    internal static let postSession = baseUrl + "sessions"
    internal static let texts = baseUrl + "texts"
    internal static let getRec = baseUrl + "recs"
    internal static let personalRec = baseUrl + "query"
    internal static let getNearbyVenues = baseUrl + "venues"
    internal static let qrCode = "https://api.qr-code-generator.com/v1/create?access-token=" + (Bundle.main.object(forInfoDictionaryKey: "qrKey") as! String)
    internal static let getStyles = baseUrl + "styles"
    internal static let getGroupStyle = baseUrl + "groupprofile"
    internal static let predictOrder = baseUrl + "predictorder"
    internal static let postMedia = baseUrl + "media"
    internal static let resetPassword = baseUrl + "resetpassword"
    internal static let createUser = baseUrl + "users"
    internal static let getConfig = baseUrl + "config"
    internal static let userParents = baseUrl + "userparents"
    internal static let products = baseUrl + "products"
    internal static let search = baseUrl + "search"
    internal static let imageRec = baseUrl + "imagerec"
    internal static let searchBrands = baseUrl + "search/brands"
    internal static let searchGeographies = baseUrl + "search/geographies"
    internal static let searchGrapes = baseUrl + "search/grapes"
    internal static let postCollection = baseUrl + "collections"
    internal static let venues = baseUrl + "venues"
    internal static let sksSignup = baseUrl + "signaturekitchensuites"
    internal static let predictpromote = baseUrl + "predictpromote"
    internal static let predictorder = baseUrl + "predictorder"
    internal static let conditions = baseUrl + "conditions"
    internal static let lttt = baseUrl + "lttt"
    internal static let foodInstantRec = baseUrl + "flttt"
    internal static let foods = baseUrl + "foods"
    internal static let avatars = baseUrl + "avatar-options"
    internal static let wheretobuy = baseUrl + "wheretobuy"
    internal static let homeConnectOAuth = baseUrl + "homeconnect/new.html"

    internal static func getAllImports(id : NSNumber) -> String {
        return baseUrl + "channels/\(id)/imports?limit=100"
    }
    
    internal static func pinChannel(id : NSNumber) -> String {
        return baseUrl + "channels/\(id)/pin"
    }
    
    internal static func getIntegration(id : NSNumber) -> String {
        return baseUrl + "integrations/\(id)"
    }
    
    internal static func lookupConversion(id : NSNumber) -> String {
        return baseUrl + "integrations/\(id)/lookups"
    }
    
    internal static func getCustomers(id : Int) -> String {
        return baseUrl + "channels/\(id)/customers"
    }
    
    internal static func lttt(id : Int) -> String {
        return baseUrl + "integration/\(id)/lttt"
    }
    
    internal static func getCustomer(id : Int, customerId : Int) -> String {
        return baseUrl + "channels/\(id)/customers/\(customerId)"
    }
    
    static func getChannels() -> String {
        if (PreferabliTools.getKeyStore().bool(forKey: "MerchantWineRingApp")) {
            return baseUrl + "channels?filter_to_editable_by_user_id=\(PreferabliTools.getUserId())&limit=9999&skip=0"
        }
        
        return baseUrl + "channels"
    }
    
    internal static func getLookups(id : Int) -> String {
        return baseUrl + "channels/\(id)/lookups"
    }
    
    internal static func getGuidedRec(id : Int) -> String {
        return baseUrl + "questionnaire/\(id)"
    }
    
    internal static func editVenue(channelId : Int, venueId : Int) -> String {
        return baseUrl + "channels/\(channelId)/venues/\(venueId)"
    }
    
    internal static func getGuidedRecResults() -> String {
        return baseUrl + "query"
    }
    
    internal static func getGuidedRecResults(id : Int) -> String {
        return baseUrl + "query?override_collection_ids[]=\(id)"
    }
    
    internal static func getStyleToTryRecs(id : Int, type : String) -> String {
        return baseUrl + "styles-to-try?collection_id=1&user_id=\(PreferabliTools.getUserId())&style_ids[]=\(id)&type=\(type)"
    }
    
    internal static func lookup(id : Int, lookupId : Int) -> String {
        return baseUrl + "channels/\(id)/lookups/\(lookupId)"
    }
    
    internal static func refreshLookup(id : Int, lookupId : Int) -> String {
        return baseUrl + "channels/\(id)/lookups/\(lookupId)/refreshmerchantdata"
    }
    
    internal static func getCampaignCustomers(id : Int, campaignId : Int) -> String {
        return baseUrl + "channels/\(id)/campaigns/\(campaignId)/customers?limit=1000"
    }
    
    internal static func campaignCustomers(id : Int, campaignId : Int) -> String {
        return baseUrl + "channels/\(id)/campaigns/\(campaignId)/customers"
    }
    
    internal static func deleteCampaignCustomers(id : Int, campaignId : Int) -> String {
        return baseUrl + "channels/\(id)/campaigns/\(campaignId)/customers/delete-all"
    }
    
    internal static func searchCustomers(id : Int) -> String {
        return baseUrl + "channels/\(id)/customers"
    }
    
    internal static func conditionCall(id : NSNumber) -> String {
        return baseUrl + "conditions/\(id)"
    }

    internal static func getImports(id : NSNumber) -> String {
        return baseUrl + "collections/\(id)/imports"
    }
    
    internal static func createImport(id : NSNumber) -> String {
        return baseUrl + "collections/\(id)/imports"
    }
    
    internal static func getImportColumns(id : NSNumber) -> String {
        return baseUrl + "imports/\(id)/columns"
    }
    
    internal static func editImportColumn(id : NSNumber, and columnId : NSNumber) -> String {
        return baseUrl + "imports/\(id)/columns/\(columnId)"
    }
    
    internal static func getImportColumnMappingOptions(id : NSNumber) -> String {
        return baseUrl + "imports/\(id)/columnmappingoptions"
    }
    
    internal static func importCall(id : NSNumber) -> String {
        return baseUrl + "imports/\(id)"
    }
    
    internal static func campaignCall(id : Int, campaignId : Int) -> String {
        return baseUrl + "channels/\(id)/campaigns/\(campaignId)"
    }
    
    internal static func stageCampaign(id : Int, campgaignId : Int) -> String {
        return baseUrl + "channels/\(id)/campaigns/\(campgaignId)/stage"
    }
    
    internal static func testCampaign(id : Int, campgaignId : Int) -> String {
        return baseUrl + "channels/\(id)/campaigns/\(campgaignId)/sendtestemails"
    }
    
    internal static func downloadCampaign(id : Int, campgaignId : Int) -> String {
        return baseUrl + "channels/\(id)/campaigns/\(campgaignId)/xlsx"
    }
    
    internal static func campaignListsCall(id : Int, campgaignId : Int) -> String {
        return baseUrl + "channels/\(id)/campaigns/\(campgaignId)/list_options"
    }
    
    internal static func campaigns(id : Int) -> String {
         return baseUrl + "channels/\(id)/campaigns"
    }
    
    internal static func availableOperands(id : Int) -> String {
         return baseUrl + "conditions/\(id)/availableoperands"
    }
    
    internal static func campaignTemplates(id : Int) -> String {
         return baseUrl + "channels/\(id)/campaigntemplates"
    }
    
    internal static func publishImport(id : NSNumber) -> String {
        return baseUrl + "imports/\(id)/publish"
    }
    
    internal static func getImportRows(id : NSNumber) -> String {
        return baseUrl + "imports/\(id)/rows"
    }
    
    internal static func getCustomerTags(id : Int, offset : Int, limit : Int) -> String {
        return baseUrl + "channels/\(id)/customerparameterkeys?offset=\(offset)&limit=\(limit)"
    }
    
    internal static func getProductCustomerTags(id : Int, product_id : Int, offset : Int, limit : Int) -> String {
        return baseUrl + "channels/\(id)/customer-tags?product_id=\(product_id)&offset=\(offset)&limit=\(limit)"
    }
    
    internal static func searchCustomerTags(id : Int) -> String {
        return baseUrl + "channels/\(id)/customerparameterkeys"
    }
    
    internal static func customerTag(id : Int, tagId : Int) -> String {
        return baseUrl + "channels/\(id)/customerparameterkeys/\(tagId)"
    }
    
    internal static func customerTagCount(id : Int, tagId : Int) -> String {
        return baseUrl + "channels/\(id)/customerparameterkeys/\(tagId)/count"
    }
    
    internal static func getCustomerParameters(id : Int, and customerId : NSNumber, offset : Int, limit : Int) -> String {
        return baseUrl + "channels/\(id)/customers/\(customerId)/parameters?offset=\(offset)&limit=\(limit)"
    }
    
    internal static func newCustomerParameter(id : Int, and customerId : NSNumber) -> String {
        return baseUrl + "channels/\(id)/customers/\(customerId)/parameters"
    }
    
    internal static func customers(id : Int) -> String {
        return baseUrl + "channels/\(id)/customers"
    }
    
    internal static func customer(id : Int, and customerId : NSNumber) -> String {
        return baseUrl + "channels/\(id)/customers/\(customerId)"
    }
    
    internal static func editCustomerParameter(id : Int, customerId : NSNumber, parameterId : NSNumber) -> String {
        return baseUrl + "channels/\(id)/customers/\(customerId)/parameters/\(parameterId)"
    }
    
    internal static func customerTags(id : NSNumber, and customerId : NSNumber) -> String {
        return baseUrl + "channels/\(id)/customers/\(customerId)/tags"
    }
    
    internal static func getPurchaseHistoryCount(id : NSNumber, and customerId : NSNumber) -> String {
        return baseUrl + "channels/\(id)/customers/\(customerId)/tags/count"
    }
    
    internal static func getCustomerProfile(id : NSNumber, and customerId : NSNumber) -> String {
        return baseUrl + "channels/\(id)/customers/\(customerId)/profile?include_styles=false"
    }
    
    internal static func importRowCall(id : NSNumber, and rowId : NSNumber) -> String {
        return baseUrl + "imports/\(id)/rows/\(rowId)"
    }
    
    internal static func importRowParameters(id : NSNumber, and rowId : NSNumber) -> String {
        return baseUrl + "imports/\(id)/rows/\(rowId)/parameters"
    }
    
    internal static func importRowParameter(id : NSNumber, and rowId : NSNumber, and parameterId : NSNumber) -> String {
        return baseUrl + "imports/\(id)/rows/\(rowId)/parameters/\(parameterId)"
    }
    
    internal static func getSuggestedRowMatches(id : NSNumber, and rowId : NSNumber) -> String {
        return baseUrl + "imports/\(id)/rows/\(rowId)/suggestedproductmatches?limit=21"
    }
    
    internal static func getProducts(id : Int) -> String {
        return baseUrl + "collections/\(id)/products?limit=9999&skip=0"
    }
    
    internal static func getProduct(id : NSNumber) -> String {
        return baseUrl + "products/\(id)"
    }
    
    internal static func collection(with id : NSNumber) -> String {
        return baseUrl + "collections/\(id)"
    }
    
    internal static func addVenue(with channelId : NSNumber) -> String {
        return baseUrl + "channels/\(channelId)/channel-venues"
    }
    
    internal static func deleteVenue(with channelId : NSNumber, and id : NSNumber) -> String {
        return baseUrl + "channels/\(channelId)/venues/\(id)"
    }
    
    internal static func updateVenueHours(with channelId : NSNumber, and id : NSNumber) -> String {
        return baseUrl + "channels/\(channelId)/venues/\(id)/bulk-hours"
    }
    
    internal static func addVenueMedia(with channelId : NSNumber, and id : NSNumber) -> String {
        return baseUrl + "channels/\(channelId)/venues/\(id)/media"
    }
    
    internal static func removeVenueMedia(with channelId : NSNumber, and venueId : NSNumber, and id : NSNumber) -> String {
        return baseUrl + "channels/\(channelId)/venues/\(venueId)/media/\(id)"
    }
    
    internal static func removeLocation(with channelId : NSNumber, and venueId : NSNumber) -> String {
        return baseUrl + "channels/\(channelId)/channel-venues/\(venueId)"
    }
    
    internal static func updateMedia(id : NSNumber) -> String {
        return baseUrl + "media/\(id)"
    }
    
    internal static func csv(with id : NSNumber) -> String {
        return baseUrl + "collections/\(id)/csv"
    }
    
    internal static func xlsx(with id : NSNumber) -> String {
        return baseUrl + "collections/\(id)/xlsx"
    }
    
    internal static func pdf(with id : NSNumber) -> String {
        return baseUrl + "collections/\(id)/pdfhtmls"
    }
    
    internal static func downloadPDF(with id : NSNumber, pdfID : NSNumber) -> String {
        return baseUrl + "collections/\(id)/pdfhtmls/\(pdfID)/download"
    }
    
    internal static func product(with id : NSNumber) -> String {
        return baseUrl + "products/\(id)"
    }

    internal static func getUser(id : NSNumber) -> String {
        return baseUrl + "users/\(id)"
    }
    
    internal static func willThey() -> String {
        return baseUrl + "wili"
    }
    
    internal static func getOrderings(collectionId : NSNumber, versionId : NSNumber, groupId : NSNumber) -> String {
        return baseUrl + "collections/\(collectionId)/versions/\(versionId)/groups/\(groupId)/orderings"
    }
    
    internal static func getTags(id : Int) -> String {
        return baseUrl + "collections/\(id)/tags"
    }

    internal static func getAccounts() -> String {
        return baseUrl + "accounts?limit=9999"
    }
    
    internal static func account(id : Int) -> String {
        return baseUrl + "accounts/\(id)"
    }
    
    internal static func accountPermissions(id : Int) -> String {
        return baseUrl + "accounts/\(id)/permissions"
    }
    
    internal static func accountPermissions() -> String {
        return baseUrl + "users/\(PreferabliTools.getUserId())/accountpermissions"
    }
    
    internal static func pinnedChannels() -> String {
        return baseUrl + "users/\(PreferabliTools.getUserId())/pinned-channels"
    }
    
    internal static func myChannelPermissions(id : Int) -> String {
        return baseUrl + "channels/\(id)/my_permissions"
    }
    
    internal static func myAccountPermissions(id : Int) -> String {
        return baseUrl + "accounts/\(id)/my_permissions"
    }
    
    internal static func myCollectionPermissions(id : Int) -> String {
        return baseUrl + "collections/\(id)/my_permissions"
    }
    
    internal static func channelPermissions(id : Int) -> String {
        return baseUrl + "channels/\(id)/permissions"
    }
    
    internal static func channelPermission(id : Int, permissionId : Int) -> String {
        return baseUrl + "channels/\(id)/permissions/\(permissionId)"
    }
    
    internal static func collectionPermissions(collectionId : Int) -> String {
        return baseUrl + "collections/\(collectionId)/permissions"
    }
    
    internal static func collectionPermission(id : Int, collectionId : Int, permissionId : Int) -> String {
        return baseUrl + "channels/\(id)/collections/\(collectionId)/permissions/\(permissionId)"
    }
    
    internal static func metrics(id : Int) -> String {
        return baseUrl + "accounts/\(id)/metrics"
    }
    
    internal static func invoices(id : Int) -> String {
        return baseUrl + "accounts/\(id)/invoices"
    }
    
    internal static func invoicePDF(id : Int, invoiceId : Int) -> String {
        return baseUrl + "accounts/\(id)/invoices/\(invoiceId)/pdf"
    }
    
    internal static func subscriptions(id : Int) -> String {
        return baseUrl + "accounts/\(id)/subscriptions"
    }
    
    internal static func permission(id : NSNumber, permissionId : NSNumber) -> String {
        return baseUrl + "accounts/\(id)/permissions/\(permissionId)"
    }
    
    internal static func getCollection(id : NSNumber) -> String {
        return baseUrl + "collections/\(id)"
    }
    
    internal static func createTag(collectionId : NSNumber) -> String {
        return baseUrl + "collections/\(collectionId)/tags"
    }
    
    internal static func createVariant(product_id : NSNumber) -> String {
        return baseUrl + "products/\(product_id)/variants"
    }
    
    internal static func getStyle(id : NSNumber) -> String {
        return baseUrl + "styles/\(id)"
    }
    
    internal static func getChannel(id : NSNumber) -> String {
        return baseUrl + "channels/\(id)"
    }
    
    internal static func getCollections(id : NSNumber) -> String {
        if (PreferabliTools.getKeyStore().bool(forKey: "MerchantWineRingApp")) {
        return baseUrl + "channels/\(id)/collections?hide_expired=false&hide_private=false&hide_unpublished=false&filter_to_managed_by_user_id=\(PreferabliTools.getUserId())"
        }
        
        return baseUrl + "channels/\(id)/collections?hide_expired=false&hide_private=true&hide_unpublished=true"
    }
        
    internal static func editTag(collectionId : NSNumber, tagId : NSNumber) -> String {
        return baseUrl + "collections/\(collectionId)/tags/\(tagId)"
    }
    
    internal static func groups(collectionId : NSNumber, versionId : NSNumber) -> String {
        return baseUrl + "collections/\(collectionId)/versions/\(versionId)/groups"
    }
    
    internal static func reorder(collectionId : NSNumber, versionId : NSNumber) -> String {
        return baseUrl + "collections/\(collectionId)/versions/\(versionId)/reorder"
    }
    
    internal static func groupsReorder(collectionId : NSNumber, versionId : NSNumber) -> String {
        return baseUrl + "collections/\(collectionId)/versions/\(versionId)/groupsreorder"
    }
    
    internal static func editGroup(collectionId : NSNumber, versionId : NSNumber, groupId : NSNumber) -> String {
        return baseUrl + "collections/\(collectionId)/versions/\(versionId)/groups/\(groupId)"
    }
    
    internal static func orderings(collectionId : NSNumber, versionId : NSNumber, groupId : NSNumber) -> String {
        return baseUrl + "collections/\(collectionId)/versions/\(versionId)/groups/\(groupId)/orderings"
    }
    
    internal static func editOrderings(collectionId : NSNumber, versionId : NSNumber, groupId : NSNumber, orderingId : NSNumber) -> String {
        return baseUrl + "collections/\(collectionId)/versions/\(versionId)/groups/\(groupId)/orderings/\(orderingId)"
    }
    
    internal static func addTagParameters(collectionId : NSNumber, tagId : NSNumber) -> String {
        return baseUrl + "collections/\(collectionId)/tags/\(tagId)/parameters"
    }
    
    internal static func editChannel(id : NSNumber) -> String {
        return baseUrl + "channels/\(id)"
    }
    
    internal static func addCollection(id : NSNumber) -> String {
        return baseUrl + "channels/\(id)/collections"
    }
    
    internal static func parties(id : Int) -> String {
        return baseUrl + "channels/\(id)/parties"
    }
    
    internal static func getParties(id : Int) -> String {
        return baseUrl + "channels/\(id)/parties?limit=1000"
    }
    
    internal static func party(id : Int, partyId : Int) -> String {
        return baseUrl + "channels/\(id)/parties/\(partyId)"
    }
    
    internal static func partyCustomers(id : Int, partyId : Int) -> String {
        return baseUrl + "channels/\(id)/parties/\(partyId)/customers"
    }
    
    internal static func removeCollection(id : NSNumber, collectionId : NSNumber) -> String {
        return baseUrl + "channels/\(id)/collections/\(collectionId)"
    }
    
    internal static func updateUser() -> String {
        return baseUrl + "users/\(PreferabliTools.getUserId())"
    }
    
    internal static func getVariant(product_id : NSNumber, variant_id : NSNumber) -> String {
        return baseUrl + "products/\(product_id)/variants/\(variant_id)"
    }
    
    internal static func customerTag(id : NSNumber, customerId : NSNumber, tagId : NSNumber) -> String {
        return baseUrl + "channels/\(id)/customers/\(customerId)/tags/\(tagId)"
    }
    
    internal static func customerRatings(id : Int, customerId : NSNumber) -> String {
           return baseUrl + "channels/\(id)/customers/\(customerId)/tags"
    }
    
    internal static func sendCustomerCode(id : Int, customerId : NSNumber) -> String {
        return baseUrl + "channels/\(id)/customers/\(customerId)/sendcodes"
    }

    internal static func getSuggestions() -> String {
        return baseUrl + "suggest"
    }
    
    internal static func userCollections() -> String {
        return baseUrl + "users/\(PreferabliTools.getUserId())/usercollections"
    }
    
    internal static func userCollection(id : NSNumber) -> String {
        return baseUrl + "users/\(PreferabliTools.getUserId())/usercollections/\(id)"
    }
    
    internal static func sendUserCode(id : NSNumber) -> String {
        return baseUrl + "users/\(id)/sendcodes"
    }

    internal static func getKiosks() -> String {
        return baseUrl + "users/\(PreferabliTools.getUserId())/kiosks"
    }

    internal static func getKiosk(id : NSNumber) -> String {
        return baseUrl + "kiosks/\(id)"
    }
    
    internal static func getFoodCategories(id : NSNumber) -> String {
        return baseUrl + "food-categories?style_id=\(id)&limit=9999"
    }
 
    internal static func getLists() -> String {
        return baseUrl + "users/\(PreferabliTools.getUserId())/lists"
    }
 
    internal static func followConnection() -> String {
        return baseUrl + "users/\(PreferabliTools.getUserId())/connections"
    }
    
    internal static func getFeedMessages() -> String {
        return baseUrl + "users/\(PreferabliTools.getUserId())/messages"
    }
    
    internal static func updateFeedMessage(id : NSNumber) -> String {
        return baseUrl + "users/\(PreferabliTools.getUserId())/messages/\(id)"
    }
    
    internal static func bulkEditMessages() -> String {
        return baseUrl + "users/\(PreferabliTools.getUserId())/bulk-edit-messages"
    }

    internal static func unfollowConnection(id : NSNumber) -> String {
        return baseUrl + "users/\(PreferabliTools.getUserId())/connections/\(id)"
    }

    internal static func createTag(id : NSNumber) -> String {
        return baseUrl + "users/\(id)/tags"
    }

    internal static func getPreferences() -> String {
        return baseUrl + "users/\(PreferabliTools.getUserId())/profile?include_styles=false"
    }
    
    internal static func getConnections() -> String {
        return baseUrl + "users/\(PreferabliTools.getUserId())/connections?limit=9999&skip=0"
    }
    
    internal static func getStylesToTry() -> String {
        return baseUrl + "styles-to-try-styles?collection_id=1&user_id=\(PreferabliTools.getUserId())"
    }

    internal static func getUserLists(id : NSNumber) -> String {
        return baseUrl + "users/\(id)/lists"
    }
    
    internal static func updateUser(id : Int) -> String {
        return baseUrl + "users/\(id)"
    }

    internal static func updateLocation() -> String {
        return baseUrl + "users/\(PreferabliTools.getUserId())/locations"
    }
    
    internal static func getWili(id : NSNumber, year : NSNumber) -> String {
        return baseUrl + "wili?product_id=\(id)&year=\(year)&user_id=\(PreferabliTools.getUserId())"
    }
    
    internal static func updateTag(id : NSNumber, tagId : NSNumber) -> String {
        return baseUrl + "users/\(id)/tags/\(tagId)"
    }
    
    internal static func addTagParameters(id : NSNumber) -> String {
        return baseUrl + "users/\(PreferabliTools.getUserId())/tags/\(id)/parameters"
    }
    
    internal static func deleteTag(id : NSNumber, tagId : NSNumber) -> String {
        return baseUrl + "users/\(id)/tags/\(tagId)"
    }
}
