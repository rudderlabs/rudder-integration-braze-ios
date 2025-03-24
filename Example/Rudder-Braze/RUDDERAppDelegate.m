//
//  RUDDERAppDelegate.m
//  Rudder-Braze
//
//  Created by arnab on 10/29/2019.
//  Copyright (c) 2019 arnab. All rights reserved.
//

#import "RUDDERAppDelegate.h"
#import <Rudder/Rudder.h>
#import "RudderBrazeFactory.h"
#import "Rudder_Braze_Example-Swift.h"
#import "RudderBrazeIntegration.h"
#import <UserNotifications/UserNotifications.h>
@import BrazeUI;

@implementation RUDDERAppDelegate

// Refer here: https://www.braze.com/docs/developer_guide/platform_integration_guides/swift/initial_sdk_setup/completing_integration/#update-your-app-delegate
static Braze *braze;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    /// Copy the `SampleRudderConfig.plist` and rename it to`RudderConfig.plist` on the same directory.
    /// Update the values as per your need.
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"RudderConfig" ofType:@"plist"];
    if (path != nil) {
        NSURL *url = [NSURL fileURLWithPath:path];
        RudderConfig *rudderConfig = [RudderConfig createFrom:url];
        if (rudderConfig != nil) {
            id<RSIntegrationFactory> brazeFactoryInstance = [RudderBrazeFactory instance];
            
            RSConfigBuilder *configBuilder = [[RSConfigBuilder alloc] init];
            [configBuilder withDataPlaneUrl:rudderConfig.DEV_DATA_PLANE_URL];
            [configBuilder withLoglevel:RSLogLevelVerbose];
            [configBuilder withFactory:brazeFactoryInstance];
            [configBuilder withTrackLifecycleEvens:NO];
            [configBuilder withSleepTimeOut:3];
            [RSClient getInstance:rudderConfig.WRITE_KEY config:[configBuilder build]];
            
            // Braze In-App Message
            [[RSClient getInstance] onIntegrationReady:brazeFactoryInstance withCallback:^(NSObject *brazeInstance) {
                if (brazeInstance && [brazeInstance isKindOfClass:[Braze class]]) {
                    braze = (Braze *)brazeInstance;
                    [self configureIAM];
                } else {
                    NSLog(@"Error getting Braze instance.");
                }
            }];
            
            [self registerForPushNotifications:application];
        }
    }
    return YES;
}

-(void) configureIAM {
    // Refer here: https://www.braze.com/docs/developer_guide/platform_integration_guides/swift/in-app_messaging/customization/setting_delegates/#setting-the-in-app-message-delegate
    BrazeInAppMessageUI *inAppMessageUI = [[BrazeInAppMessageUI alloc] init];
    braze.inAppMessagePresenter = inAppMessageUI;
    // Make Identify event so that Braze could identify the device and send the IAM.
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Push Notification support

- (void)registerForPushNotifications:(UIApplication *)application {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        
        UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
        [center setNotificationCategories:BRZNotifications.categories];
        center.delegate = self;
        UNAuthorizationOptions options = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
        if (@available(iOS 12.0, *)) {
            options = options | UNAuthorizationOptionProvisional;
        }
        [center requestAuthorizationWithOptions:options
                              completionHandler:^(BOOL granted, NSError *_Nullable error) {
            NSLog(@"Notification authorization, granted: %d, "
                  @"error: %@)",
                  granted, error);
        }];
    });
}

// - Register the device token with Braze

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [self waitForBrazeSDKToInit:10.f];
    if ([RudderBrazeFactory instance].integration) {
        [[RudderBrazeFactory instance].integration didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

-(void)waitForBrazeSDKToInit:(NSTimeInterval)timeInterval {
    if ([RudderBrazeFactory instance].integration == nil) {
        [NSThread sleepForTimeInterval:timeInterval];
    }
}


// - Add support for silent notification

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler: (void (^)(UIBackgroundFetchResult))completionHandler {
    if ([RudderBrazeFactory instance].integration) {
        [[RudderBrazeFactory instance].integration didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    }
}

// - Add support for push notifications

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    if ([RudderBrazeFactory instance].integration) {
        [[RudderBrazeFactory instance].integration didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
    }
}

// - Add support for displaying push notification when the app is currently running in the foreground

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler: (void (^)(UNNotificationPresentationOptions))completionHandler {
    if (@available(iOS 14, *)) {
        completionHandler(UNNotificationPresentationOptionList |
                          UNNotificationPresentationOptionBanner);
    } else {
        completionHandler(UNNotificationPresentationOptionAlert);
    }
}

@end
