//
//  RudderBrazeFactory.h 
//
//  Created by Raj
//

#import <Foundation/Foundation.h>
@import Rudder;
#import "RudderBrazeIntegration.h"
NS_ASSUME_NONNULL_BEGIN

@interface RudderBrazeFactory : NSObject<RSIntegrationFactory>

extern NSString *const RSBrazeExternalIdKey;

@property NSDictionary *pushPayload;

+ (instancetype) instance;

- (void) putLaunchOptions:(NSDictionary *)launchOpts;
- (void) putRemoteNotification:(NSDictionary *)remoteNotif;
- (void) resetRemoteNotification;
- (NSDictionary *) getPushPayload ;

@end

NS_ASSUME_NONNULL_END
