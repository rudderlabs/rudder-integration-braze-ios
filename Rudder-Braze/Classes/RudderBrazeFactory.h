//
//  RudderBrazeFactory.h 
//
//  Created by Raj
//

#import <Foundation/Foundation.h>
#import <Rudder/Rudder.h>
#import "RudderBrazeIntegration.h"
NS_ASSUME_NONNULL_BEGIN

@interface RudderBrazeFactory : NSObject<RSIntegrationFactory>

extern NSString *const RSBrazeExternalIdKey;

@property NSDictionary *pushPayload;

+ (instancetype) instance;

@end

NS_ASSUME_NONNULL_END
