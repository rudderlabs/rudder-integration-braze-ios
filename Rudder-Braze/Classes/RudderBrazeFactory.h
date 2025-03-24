//
//  RudderBrazeFactory.h 
//
//  Created by Raj
//

#import <Foundation/Foundation.h>
#import "RudderBrazeIntegration.h"
#if defined(__has_include) && __has_include(<Rudder/Rudder.h>)
#import <Rudder/Rudder.h>
#else
#import "Rudder.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface RudderBrazeFactory : NSObject<RSIntegrationFactory>

extern NSString *const RSBrazeExternalIdKey;

@property NSDictionary *pushPayload;

+ (instancetype) instance;

@property RudderBrazeIntegration * __nullable integration;

@end

NS_ASSUME_NONNULL_END
