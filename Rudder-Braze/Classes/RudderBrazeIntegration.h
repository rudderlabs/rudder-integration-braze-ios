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

-(void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
// Following the guidance provided in the Braze documentation at https://www.braze.com/docs/developer_guide/platform_integration_guides/swift/push_notifications/integration/#step-3-enable-push-handling, it is recommended to invoke the push integration code within the main thread of the application.
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
// Following the guidance provided in the Braze documentation at https://www.braze.com/docs/developer_guide/platform_integration_guides/swift/push_notifications/integration/#step-3-enable-push-handling, it is recommended to invoke the push integration code within the main thread of the application.
- (void)didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler;
@end

NS_ASSUME_NONNULL_END
