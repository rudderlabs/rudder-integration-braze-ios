//
//  RudderBrazeFactory.m 
//
//  Created by Raj.
//

#import "RudderBrazeFactory.h"

@implementation RudderBrazeFactory

static RudderBrazeFactory *sharedInstance;

NSString *const RSBrazeExternalIdKey = @"brazeExternalId";
NSString *const RSBrazeKey = @"Braze";

+ (instancetype)instance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (nonnull NSString *)key {
    return RSBrazeKey;
}

- (id <RSIntegration>) initiate: (NSDictionary*) config client:(RSClient*) client rudderConfig:(nonnull RSConfig *)rudderConfig{
    self.integration = [[RudderBrazeIntegration alloc] initWithConfig:config withAnalytics:client rudderConfig: rudderConfig];
    return self.integration;
}

@end
