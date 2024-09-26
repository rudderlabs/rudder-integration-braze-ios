//
//  RudderBrazeFactory.h 
//
//  Created by Raj
//

#import <Foundation/Foundation.h>
#import "RudderBrazeIntegration.h"
@import Rudder;

NS_ASSUME_NONNULL_BEGIN

@interface RudderBrazeFactory : NSObject<RSIntegrationFactory>

extern NSString *const RSBrazeExternalIdKey;

@property NSDictionary *pushPayload;

+ (instancetype) instance;

@property RudderBrazeIntegration * __nullable integration;

@end

NS_ASSUME_NONNULL_END
