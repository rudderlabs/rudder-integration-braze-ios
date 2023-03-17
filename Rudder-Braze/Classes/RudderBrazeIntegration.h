//
//  RudderBrazeIntegration.h
//
//  Created by Raj
//

#import <Foundation/Foundation.h>

#if defined(__has_include) && __has_include(<Appboy_iOS_SDK/AppboyKit.h>)
#import <Appboy_iOS_SDK/AppboyKit.h>
#import <Appboy_iOS_SDK/ABKUser.h>
#import <Appboy_iOS_SDK/ABKAttributionData.h>
#else
#import "Appboy-iOS-SDK/AppboyKit.h"
#import "Appboy-iOS-SDK/ABKUser.h"
#import "Appboy-iOS-SDK/ABKAttributionData.h"
#endif
#import <Rudder/Rudder.h>
 
NS_ASSUME_NONNULL_BEGIN

@interface BrazePurchase : NSObject

@property NSString *productId;
@property int quantity;
@property NSDecimalNumber *price;
@property NSMutableDictionary *properties;
@property NSString *currency;

@end

@interface RudderBrazeIntegration : NSObject<RSIntegration>

@property (nonatomic, strong) NSDictionary *config;
@property (nonatomic, strong) RSClient *client;
@property (nonatomic) BOOL supportDedup;
@property (nonatomic, strong) RSMessage *previousIdentifyElement;

- (instancetype)initWithConfig:(NSDictionary *)config withAnalytics:(RSClient *)client rudderConfig:(nonnull RSConfig *)rudderConfig ;

@end

NS_ASSUME_NONNULL_END
