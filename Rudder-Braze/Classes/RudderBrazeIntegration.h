//
//  RudderBrazeIntegration.h
//
//  Created by Raj
//

#import <Foundation/Foundation.h>

@import AppboyKit;
@import Rudder;
 
NS_ASSUME_NONNULL_BEGIN

@interface RudderBrazeIntegration : NSObject<RSIntegration>

@property (nonatomic, strong) NSDictionary *config;
@property (nonatomic, strong) RSClient *client;

- (instancetype)initWithConfig:(NSDictionary *)config withAnalytics:(RSClient *)client rudderConfig:(nonnull RSConfig *)rudderConfig ;

@end

NS_ASSUME_NONNULL_END
