
#import <Foundation/Foundation.h>

@interface PendoOptions : NSObject <NSCopying>

/** @brief react native version that is used by hosting app. */
@property (nonatomic, nullable) NSString *platformVersion;

/** @brief react plugin number that is used by hosting app. */
@property (nonatomic) NSUInteger reactPlugin;

/** @brief indicates communication with xamarin forms plugin */
@property (nonatomic) BOOL isXamarinForms;

/** @brief indicates communication with MAUI plugin */
@property (nonatomic) BOOL isMAUI;

/** @brief disable analytics collection. */
@property (nonatomic) BOOL disableAnalytics;

/** @brief internal configuration. */
@property (nonatomic, nullable) NSMutableDictionary *configs;

/** @brief environment type. */
@property (nonatomic, nullable) NSString *environmentName;

/** @brief return all guides content in initModel. */
@property (nonatomic) BOOL withGuideContent;

/** @brief when comparing two screen scans decides if to compare the full screen data or only the screen ids. Warning: May effect ability to use text page identifiers in dynamically loaded pages  */
@property (nonatomic) BOOL isComparingScreenIdsOnly;

/** @brief when evaluating screen scan, if a scan missing info and child controllers - do no evaluate. */
@property (nonatomic) BOOL shouldIgnoreEmptyScanData;

/** @brief time interval for debouncer used to scan the page upon page changed events. */
@property (nonatomic) NSNumber * _Nullable screenScanDebouncerDelay;

/** @brief page events and screen ids will ignore view controllers imbedded inside scrollViews / collectionViews / tableViews. */
@property (nonatomic) BOOL isIgnoringViewControllersInScrollView;

/** @brief a list of class names inheriting from UIViewController that should not trigger a page changed event . */
@property (nonatomic) NSArray<NSString *> * _Nullable listOfUIViewControllersToIgnorePageScan;

/** @brief screen content scans entire screen data and not just text changes  . */
@property (nonatomic) BOOL isContentChangeTriggeringFullPageScan DEPRECATED_MSG_ATTRIBUTE("The behavior controlled by this flag has been updated to be the default logic by the SDK. Setting this flag has no effect from SDK v2.18.0");;

/** @brief when new content is loaded on the screen,  a screen scan will not be triggered  . */
@property (nonatomic) BOOL shouldIgnoreDynamicContentRN;

/** @brief time interval for debouncer used to scan the page upon content changed event. */
@property (nonatomic) NSNumber * _Nullable dynamicScreenScanDebouncerDelayRN;

/** @brief if enabled, the isHidden by another view controllers will be disabled */
@property (nonatomic) BOOL isScanVisibleViewControllersDisabled;

- (instancetype _Nonnull)init NS_DESIGNATED_INITIALIZER;

@end

