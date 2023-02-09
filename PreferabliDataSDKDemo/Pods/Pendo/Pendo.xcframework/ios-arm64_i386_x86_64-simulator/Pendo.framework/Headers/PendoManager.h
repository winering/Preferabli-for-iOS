//
//  PendoManager.h
//  Pendo
//

#import <Foundation/Foundation.h>

@class PendoInitParams, PendoOptions;

NS_ASSUME_NONNULL_BEGIN

/**
 * For additional info about our SDK APIs use the Pendo API documentation:
 * https://support.pendo.io/hc/en-us/articles/360055603992-IOS-Developer-API-Documentation
 */

/**
 *  The SDK will post the following notification when a new session has completed initialization and the session is in progress.
 *  The notifications are posted to the main thread
 *  This notification is sent out after the SDK session has successfully initialized
 */
extern NSString *const kPNDDidSuccessfullyInitializeSDKNotification;

/**
 *  This notification is sent out when an error occurs during initialization of the SDK session.
 */
extern NSString *const kPNDErrorInitializeSDKNotification;

/**
 *  PendoManager. Handles initialization of the Pendo Mobile SDK.
 */
@interface PendoManager : NSObject

/**
 * The app key used when initializing the SDK.
 */
@property (nonatomic, readonly, nonnull) NSString *appKey;

/**
 *  Provide a visitor id to the Pendo Mobile SDK.
 */
@property (nonatomic, strong, readonly, nullable) NSString *visitorId;

/**
 *  Provide an account id to the Pendo Mobile SDK.
 */
@property (nonatomic, strong, nullable) NSString *accountId;

#pragma mark - Initializer

/**
 *  Use [PendoManager sharedManager] instead
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 *  The shared instance of the PendoManager
 */
+ (instancetype)sharedManager;

/**
 *  Call this method on the sharedManger with your application key.
 *  Use this API in case the account and visitor data are not yet known, and they will be known at a later point of the app's lifecycle. In order to update the account and visitor data, call the API: [PendoManager switchVisitor:accountId:visitorData:accountData];
 *
 *  @warning This API is NOT an anonymous API. this should only be used if visitor data will be known at a later point.
 *  @param appKey The app key for your account
 */
- (void)initSDKWithoutVisitor:(NSString *_Nonnull)appKey DEPRECATED_MSG_ATTRIBUTE("Please use the new setup:(NSString*) API");

/**
 *  Call this method on the sharedManger with your application key.
 *  Use this API in case the account and visitor data are not yet known, and they will be known at a later point of the app's lifecycle. In order to update the account and visitor data, call the API: [PendoManager switchVisitor:accountId:visitorData:accountData];
 *
 *  @warning This API is NOT an anonymous API. this should only be used if visitor data will be known at a later point.
 *  @param appKey The app key for your account
 *  @param options additional options for internal use only, default nil
 */
- (void)initSDKWithoutVisitor:(NSString *)appKey withOptions:(PendoOptions *_Nullable)options DEPRECATED_MSG_ATTRIBUTE("Please use the setup:(NSString*):withOptions:(PendoOptions*) API");

/**
 *  Call this method on the sharedManger with your application key.
 *
 *  @param appKey The app key for your account
 *  @param initParams (nullable) Extra initialize parameters (e.g. account id, visitor id...).
 */
- (void)initSDK:(NSString *_Nonnull)appKey initParams:(PendoInitParams *_Nullable)initParams DEPRECATED_MSG_ATTRIBUTE("Please use the setup:(NSString*) API with your app key and and then the  startSession:(NSString*)accountId:(NSString*)visitorData:(NSDictionary*)accountData:(NSDictionary*) API with the relevant initialization parameters");

/**
 *  Call this method on the sharedManger with your application key.
 *  Setup the Pendo SDK. [PendoManager startSession:accountId:visitorData:accountData]; when you would like to start the session (anonymous or identified)
 *
 *  @param appKey The app key for your account
 */
- (void)setup:(NSString *_Nonnull)appKey;

/**
 *  Call this method on the sharedManger with your application key.
 *  Setup the Pendo SDK. [PendoManager startSession:accountId:visitorData:accountData]; when you would like to start the session (anonymous or identified)
 *
 *  @param appKey The app key for your account
 *  @param options additional options for internal use only, default nil
 */
- (void)setup:(NSString *)appKey withOptions:(PendoOptions *_Nullable)options;

/**
 *  Called from your app delegate when launched from a deep link containing an Pendo Mobile pairing URL
 *  @warning Must be called <b>after</b> the SDK was initialized.
 *  @param url The pairing URL
 */
- (void)initWithUrl:(NSURL *_Nonnull)url;

/**
 *  Call this method on the sharedManger to end current session and stop gathering analytics.
 *  @warning Must be called <b>after</b> the SDK was initialized.
 */
- (void)endSession;

#pragma mark - Visitor

/**
 * Must be called <b>after</b> the SDK was initialized.
 *
 * @brief Switch to a new visitor and restart the session.
 *
 * @param visitorId The visitor's ID.
 * @param accountId The account's ID.
 * @param visitorData The visitor's data.
 * @param accountData The account's data.
 */
- (void)switchVisitor:(NSString *_Nullable)visitorId
            accountId:(NSString *_Nullable)accountId
          visitorData:(NSDictionary *_Nullable)visitorData
          accountData:(NSDictionary *_Nullable)accountData DEPRECATED_MSG_ATTRIBUTE("Please use the startSession:(NSString*)accountId:(NSString*)visitorData:(NSDictionary*)accountData:(NSDictionary*) API");

/**
 * Must be called <b>after</b> the SDK was initialized.
 * @brief Clears the current visitor.
 */
- (void)clearVisitor DEPRECATED_MSG_ATTRIBUTE("Please use the startSession:(NSString*)accountId:(NSString*)visitorData:(NSDictionary*)accountData:(NSDictionary*) API with all arguments set to nil");

/**
 * Must be called <b>after</b> the SDK was initialized.
 *
 * @brief start a session with a new visitor.
 * In case a session was already started before, end the previous one and start a new one.
 * To start as session with an anonymous visitor pass nil as the visitorId.
 *
 * @param visitorId The visitor's ID.
 * @param accountId The account's ID.
 * @param visitorData The visitor's data.
 * @param accountData The account's data.
 */
- (void)startSession:(NSString *_Nullable)visitorId
            accountId:(NSString *_Nullable)accountId
          visitorData:(NSDictionary *_Nullable)visitorData
          accountData:(NSDictionary *_Nullable)accountData;

/**
 * Set a visitor data value.
 * This data is used by Pendo Mobile for creating audiences or reporting analytics.
 * For instance you might want to provide data on the visitor's age or if the visitor is logged into a service.
 * The data is accumulated and maintained between sessions.
 *
 *  @param visitorData additional visitor data.
 */
- (void)setVisitorData:(NSDictionary *_Nonnull)visitorData;

/**
 * Set account data value for a given data name.
 * This data is used by Pendo Mobile for creating audiences or reporting analytics.
 * For instance you might want to provide data on the account's subscription or if the account is active or not.
 * The data is accumulated and maintained between sessions.
 *
 * @param accountData the account data.
*/
- (void)setAccountData:(NSDictionary *_Nonnull)accountData;

- (void)setAccountId:(NSString *_Nullable)accountId DEPRECATED_MSG_ATTRIBUTE("Please use the startSession:(NSString*)accountId:(NSString*)visitorData:(NSDictionary*)accountData:(NSDictionary*) API with the desired accountId value");

#pragma mark - Visitor using JWT

/**
 * Must be called <b>after</b> the SDK was initialized.
 *
 * @brief start a session with a new visitor. Pass a JWT generated by your server-side and signed using the shared private.
 *  In case a session was already started before, end the previous one and start a new one.
 *  The expected JWT body format: (visitor properties are optional)
 *
 *  Identified visitor:
 *
 *  {
 *    "visitor" : {
 *       "id" : "visitor name",
 *       "visitorProperty1" : "visitorValue1",
 *       "visitorProperty2" : "visitorValue2"
 *    },
 *    "account" : {
 *       "id" : "account name",
 *       "accountProperty1" : "accountValue1",
 *       "accountProperty2" : "accountValue2"
 *    }
 *  }
 *
 *  Anonymous visitor:
 *
 *  {
 *    "visitor" : {
 *       "id" : "",
 *       "visitorProperty1" : "visitorValue1",
 *       "visitorProperty2" : "visitorValue2"
 *    },
 *    "account" : {
 *       "id" : ""
 *    }
 *  }
 *
 * @param jwt The jwt including the session visitor and account data.
 * @param signingKeyName The key name used to sign the jwt.
 */
- (void)startSession:(NSString *)jwt signingKeyName:(NSString *)signingKeyName;

/**
 * Set a visitor data value.
 * This data is used by Pendo Mobile for creating audiences or reporting analytics.
 * For instance you might want to provide data on the visitor's age or if the visitor is logged into a service.
 * The data is accumulated and maintained between sessions.
 * The expected JWT body format:
 *
 *  {
 *    "visitor" : {
 *       "id" : "visitor name",
 *       "visitorProperty1" : "visitorValue1",
 *       "visitorProperty2" : "visitorValue2"
 *    }
 *  }
 *
 * @param jwt The jwt including the session visitor data.
 * @param signingKeyName The key name used to sign the jwt.
 */
- (void)setVisitorData:(NSString *)jwt signingKeyName:(NSString *)signingKeyName;

/**
 * Set account data value for a given data name.
 * This data is used by Pendo Mobile for creating audiences or reporting analytics.
 * For instance you might want to provide data on the account's subscription or if the account is active or not.
 * The data is accumulated and maintained between sessions.
 * The expected JWT body format:
 *
 *  {
 *    "account" : {
 *       "id" : "account name",
 *       "accountProperty1" : "accountValue1",
 *       "accountProperty2" : "accountValue2"
 *    }
 *  }
 *
 * @param jwt The jwt including the session visitor data.
 * @param signingKeyName The key name used to sign the jwt.
 */
- (void)setAccountData:(NSString *)jwt signingKeyName:(NSString *)signingKeyName;

#pragma mark - Track

/**
 * When your application needs to send additional events about actions your users perform.
 *
 * @param event The event name describing the user’s action.
 * @param properties dictionary event properties (optional).
 * @brief Queue of track events for transmission, optionally including properties as the payload of the event.
 */
- (void)track:(NSString *_Nonnull)event properties:(NSDictionary *_Nullable)properties;

/**
 @brief this method makes the object passed in to act as a taggable/clickable object by Pendo SDK.
 @param view passed in object, should be of type UIVIew.
 @discussion this method will treat passed in object to be counted as a taggable/clickable object by the Pendo SDK.
 this method will stop treating an object as taggable/clickable object once its stopped being visible on screen.
 */
- (void)enableClickAnalytics:(id)view;

/**
 @brief call this method after a change / update to a UIViewController's content has been made. This method rescans the page elements allowing our SDK to display tooltip guides on the new / modified elements on the page. Examples of scenarios after which this method should be called include: a network response updating the screen content, a subview is added to the screen programmatically, a UIView's isHidden property is updated or a UIView's alpha changes such that it becomes visible.
 @note there is no need to call this method for content offset changes that occur as part of elements that inherit from UIScrollView. The method is automatically called after scrolling, allowing tooltips to be displayed on content below the fold.
 @warning if multiple page captures were used in order to tag features that only exist in some state of the page, make sure that all page captures of the screen use identical page rules & page identifiers for correct analytics and guide behavior.
 */
- (void)screenContentChanged;

#pragma mark - Guides

/**
 * Call in order to stop showing guides.
 */
- (void)pauseGuides DEPRECATED_MSG_ATTRIBUTE("Please use pauseGuides:(BOOL)dismissGuides");

/**
 * Call in order to stop showing guides.
 */
- (void)pauseGuides:(BOOL)dismissGuides;

/**
 * Call in order to resume showing guides.
 */
- (void)resumeGuides;

/**
 * Get Pendo SDK unique device id. Used for anonymous visitor id.
 * This id is unique per application. 
 */
- (NSString *)getDeviceId;

/**
 * Dismiss any visible guides
 */
- (void)dismissVisibleGuides;

#pragma mark - Debug

/**
 * @param isDebugEnabled - if true will enables debug logs, if false will disable debug logs
 */
- (void)setDebugMode:(BOOL)isDebugEnabled;

@end

NS_ASSUME_NONNULL_END


