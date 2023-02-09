//
//  PendoManagerReactNative.h
//  PendoSDK
//
//  Created by Maxim Shnirman on 29/05/2022.
//  Copyright © 2022 Pendo.io. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const PNDRequiresJSHierarchyScan;

@interface PendoManagerReactNative : NSObject
+ (id)uiManager;
+ (void)setUiManager:(id)uiManager;
+ (dispatch_queue_t)reactPendoQueue;
+ (void)sendFailureInfo:(NSDictionary *)userInfo shouldSendErrorToBE:(BOOL)shouldSendErrorToBE scanReason:(NSInteger)scanReason;
+ (void)screenChanged:(NSString *)screenName rootTags:(NSArray *)rootTags nodes:(NSArray *)clickableNodes info:(NSDictionary *)info;
+ (void)logMessage:(NSString *)message;
@end

NS_ASSUME_NONNULL_END
