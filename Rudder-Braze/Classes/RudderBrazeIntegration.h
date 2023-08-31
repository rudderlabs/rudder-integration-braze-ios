//
//  RudderBrazeIntegration.h
//
//  Created by Raj
//

#import <Foundation/Foundation.h>

@import BrazeKit;
#import <Rudder/Rudder.h>
 
NS_ASSUME_NONNULL_BEGIN

@interface BrazePurchase : NSObject

@property NSString *productId;
@property int quantity;
@property NSDecimalNumber *price;
@property NSMutableDictionary *properties;
@property NSString *currency;

@end

typedef enum {
    ConnectionModeHybrid,
    ConnectionModeCloud,
    ConnectionModeDevice
} ConnectionMode;

@interface RudderBrazeIntegration : NSObject<RSIntegration> {
    ConnectionMode connectionMode;
    Braze *braze;
}

@property (nonatomic, strong) NSDictionary *config;
@property (nonatomic, strong) RSClient *client;
@property (nonatomic) BOOL supportDedup;
@property (nonatomic, strong) RSMessage *previousIdentifyElement;

- (instancetype)initWithConfig:(NSDictionary *)config withAnalytics:(RSClient *)client rudderConfig:(nonnull RSConfig *)rudderConfig ;

@end

NS_ASSUME_NONNULL_END
