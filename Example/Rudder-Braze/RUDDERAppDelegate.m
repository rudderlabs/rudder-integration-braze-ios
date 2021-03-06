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


@implementation RUDDERAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    NSString *WRITE_KEY = @"1UsY362jONW4EOwaZX5MA6FX5Zt";
    NSString *DATA_PLANE_URL = @"https://8e50d3caecbe.ngrok.io";
    
    RSConfigBuilder *configBuilder = [[RSConfigBuilder alloc] init];
    [configBuilder withDataPlaneUrl:DATA_PLANE_URL];
    [configBuilder withLoglevel:RSLogLevelDebug];
    [configBuilder withFactory:[RudderBrazeFactory instance]];
    [RSClient getInstance:WRITE_KEY config:[configBuilder build]];

//    RSOption *identifyOptions = [[RSOption alloc] init];
//                 [identifyOptions putExternalId:@"brazeExternalId" withId:@"sampleNEW123_braze_external_id_1"];
//                 [identifyOptions putExternalId:@"braze_id" withId:@"some_braze_id_3_1"];
//
//    [[RSClient sharedInstance] identify:@"test_user_id_ios_1"
//                                 traits:@{@"foo": @"bar",
//                                       @"foo1": @"bar1",
//                                       @"email": @"test_1@gmail.com"}
//                                options:identifyOptions
//    ];
//
//    [[RSClient sharedInstance] track:@"simple_track_event_1"];
//
//    [[RSClient sharedInstance] track:@"simple_track_with_props_1" properties:@{
//         @"key_1" : @"value_1",
//         @"key_2" : @"value_2"
//    }];
//
//    [[RSClient sharedInstance] screen:@"Main_1" properties:@{@"prop_key" : @"prop_value"}];

    [[RSClient sharedInstance] reset];
    [[RSClient sharedInstance] identify: @"test_user_id_ios_2"
                                 traits: @{
                                     @"foo": @"bar",
                                     @"foo1": @"bar1",
                                     @"email": @"test_2@gmail.com"
                                 }
    ];
    [[RSClient sharedInstance] track:@"simple_track_event_after_reset_2"];
    
    return YES;
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

@end
