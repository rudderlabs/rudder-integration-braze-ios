//
//  RudderBrazeIntegration.m
//
//  Created by Raj
//

#import "RudderBrazeIntegration.h"

#import "RudderBrazeFactory.h"
@implementation RudderBrazeIntegration

#pragma mark - Initialization

- (instancetype)initWithConfig:(NSDictionary *)config withAnalytics:(nonnull RSClient *)client rudderConfig:(nonnull RSConfig *)rudderConfig {
    if (self = [super init]) {
        self.config = config;
        self.client = client;
        self.supportDedup = [[config objectForKey:@"supportDedup"] boolValue] ? YES : NO;
        NSString *apiToken = [config objectForKey:@"appKey"];
        if ( [apiToken length] == 0) {
            return nil;
        }
        
        NSMutableDictionary *appboyOptions = [[NSMutableDictionary alloc] init];
        NSString *dataCenter = [config objectForKey:@"dataCenter"];
        if ((dataCenter && [dataCenter length] != 0)) {
            NSString *customEndpoint = [dataCenter stringByTrimmingCharactersInSet:
                                        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if([@"US-01" isEqualToString:customEndpoint]) {
                appboyOptions[ABKEndpointKey] = @"sdk.iad-01.braze.com";
            } else if([@"US-02" isEqualToString:customEndpoint]) {
                appboyOptions[ABKEndpointKey] = @"sdk.iad-02.braze.com";
            } else if([@"US-03" isEqualToString:customEndpoint]) {
                appboyOptions[ABKEndpointKey] = @"sdk.iad-03.braze.com";
            } else if([@"US-04" isEqualToString:customEndpoint]) {
                appboyOptions[ABKEndpointKey] = @"sdk.iad-04.braze.com";
            } else if([@"US-05" isEqualToString:customEndpoint]) {
                appboyOptions[ABKEndpointKey] = @"sdk.iad-05.braze.com";
            } else if([@"US-06" isEqualToString:customEndpoint]) {
                appboyOptions[ABKEndpointKey] = @"sdk.iad-06.braze.com";
            } else if([@"US-08" isEqualToString:customEndpoint]) {
                appboyOptions[ABKEndpointKey] = @"sdk.iad-08.braze.com";
            } else if([@"EU-01" isEqualToString:customEndpoint]) {
                appboyOptions[ABKEndpointKey] = @"sdk.fra-01.braze.eu";
            } else if([@"EU-02" isEqualToString:customEndpoint]) {
                appboyOptions[ABKEndpointKey] = @"sdk.fra-02.braze.eu";
            }
        }
        
        // For more details on Braze log level -> https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/initial_sdk_setup/other_sdk_customizations/#braze-log-level
        switch (rudderConfig.logLevel) {
            case 5: //RSLogLevelVerbose
                appboyOptions[ABKLogLevelKey] = @0;
                break;
            case 4: //RSLogLevelDebug
                appboyOptions[ABKLogLevelKey] = @1;
                break;
            case 2: //RSLogLevelWarning
                appboyOptions[ABKLogLevelKey] = @2;
                break;
            case 1: //RSLogLevelError
                appboyOptions[ABKLogLevelKey] = @4;
                break;
            case 3: //RSLogLevelInfo
                appboyOptions[ABKLogLevelKey] = @8;
                break;
            default:
                break;
        }
        
        if ([NSThread isMainThread]) {
            [Appboy startWithApiKey:apiToken
                      inApplication:[UIApplication sharedApplication]
                  withLaunchOptions:nil
                  withAppboyOptions:appboyOptions];
            [RSLogger logInfo:@"[Braze startWithApiKey:inApplication:withLaunchOptions:withAppboyOptions:]"];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [Appboy startWithApiKey:apiToken
                          inApplication:[UIApplication sharedApplication]
                      withLaunchOptions:nil
                      withAppboyOptions:appboyOptions];
                [RSLogger logInfo:@"[Braze startWithApiKey:inApplication:withLaunchOptions:withAppboyOptions:]"];
            });
        }
    }
    
    if ([Appboy sharedInstance] != nil) {
        return self;
    } else {
        return nil;
    }
}

- (NSString *) getExternalId: (RSMessage *) message {
    NSArray* externalIds = message.context.externalIds;
    NSString *externalId = nil;
    for (NSDictionary* externalIdDict in externalIds) {
        NSString *typeKey = externalIdDict[@"type"];
        if (typeKey && [typeKey isEqualToString:RSBrazeExternalIdKey]) {
            externalId = externalIdDict[@"id"];
            break;
        }
    }
    return externalId;
}

- (void)dump:(nonnull RSMessage *)message {
    if([message.type isEqualToString:@"identify"]) {
        if (![NSThread isMainThread]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dump:message];
            });
            return;
        }
        
        if ([message.context.traits[@"lastname"] isKindOfClass:[NSString class]]) {
            NSString *lastName = [self needUpdate:@"lastname" withMessage:message];
            if (lastName != nil) {
                [Appboy sharedInstance].user.lastName = lastName;
                [RSLogger logInfo:@"Identify: Braze user lastname"];
            }
        }
        
        // look for externalIds first
        NSString *prevExternalId = [self getExternalId:self.previousIdentifyElement];
        NSString *currExternalId = [self getExternalId:message];
        
        NSString *prevUserId = self.previousIdentifyElement.userId;
        NSString *currUserId = message.userId;
        
        if ((prevExternalId == nil && currExternalId != nil) || (![currExternalId isEqual:prevExternalId])) {
            [[Appboy sharedInstance] changeUser:currExternalId];
            [RSLogger logInfo:@"Identify: Braze changeUser with externalId"];
        } else if ((prevUserId == nil && currUserId != nil) || (![currUserId isEqual:prevUserId])) {
            [[Appboy sharedInstance] changeUser:currUserId];
            [RSLogger logInfo:@"Identify: Braze changeUser with userId"];
        }
        
        if ([message.context.traits[@"email"] isKindOfClass:[NSString class]]) {
            NSString *email = [self needUpdate:@"email" withMessage:message];
            if (email != nil) {
                [Appboy sharedInstance].user.email = email;
                [RSLogger logInfo:@"Identify: Braze email"];
            }
        }
        
        if ([message.context.traits[@"firstname"] isKindOfClass:[NSString class]]) {
            NSString *firstName = [self needUpdate:@"firstname" withMessage:message];
            if (firstName != nil) {
                [Appboy sharedInstance].user.firstName = firstName;
                [RSLogger logInfo: @"Identify: Braze firstname"];
            }
        }
        
        if ([message.context.traits[@"birthday"] isKindOfClass:[NSDate class]]) {
            NSDate *birthday =[self needUpdate:@"birthday" withMessage:message];
            if (birthday != nil) {
                [Appboy sharedInstance].user.dateOfBirth = birthday;
                [RSLogger logInfo: @"Identify: Braze  date of birth"];
            }
        }
        
        if ([message.context.traits[@"gender"] isKindOfClass:[NSString class]]) {
            NSString *gender = [self needUpdate:@"gender" withMessage:message];
            if (gender != nil) {
                if ([gender.lowercaseString isEqualToString:@"m"] || [gender.lowercaseString isEqualToString:@"male"]) {
                    [[Appboy sharedInstance].user setGender:ABKUserGenderMale];
                    [RSLogger logInfo:@"Identify: Braze  gender"];
                } else if ([gender.lowercaseString isEqualToString:@"f"] || [gender.lowercaseString isEqualToString:@"female"]) {
                    [[Appboy sharedInstance].user setGender:ABKUserGenderFemale];
                    [RSLogger logInfo:@"Identify: Braze  gender"];
                }
            }
        }
        
        if ([message.context.traits[@"phone"] isKindOfClass:[NSString class]]) {
            NSString *phone = [self needUpdate:@"phone" withMessage:message];
            if (phone != nil) {
                [Appboy sharedInstance].user.phone = phone;
                [RSLogger logInfo:@"Identify: Braze  phone"];
            }
        }
        
        if ([message.context.traits[@"address"] isKindOfClass:[NSDictionary class]]) {
            NSDictionary *address = [self needUpdate:@"address" withMessage:message];
            if (address != nil) {
                if ([address[@"city"] isKindOfClass:[NSString class]]) {
                    [Appboy sharedInstance].user.homeCity = address[@"city"];
                    [RSLogger logInfo:@"Identify: Braze  homecity"];
                }
                
                if ([address[@"country"] isKindOfClass:[NSString class]]) {
                    [Appboy sharedInstance].user.country = address[@"country"];
                    [RSLogger logInfo:@"Identify: Braze  country"];
                }
            }
        }
        
        NSArray *appboyTraits = @[@"birthday", @"anonymousId", @"gender", @"phone", @"address", @"firstname", @"lastname", @"email"  ];
        
        
        //ignore above traits and get others - free key value pairs
        for (NSString *key in message.context.traits.allKeys) {
            if (![appboyTraits containsObject:key]) {
                id traitValue = [self needUpdate:key withMessage:message];
                if (traitValue != nil) {
                    if ([traitValue isKindOfClass:[NSString class]]) {
                        [[Appboy sharedInstance].user setCustomAttributeWithKey:key andStringValue:traitValue];
                        [RSLogger logInfo:@"Braze setCustomAttributeWithKey: andStringValue: "];
                    } else if ([traitValue isKindOfClass:[NSDate class]]) {
                        [[Appboy sharedInstance].user setCustomAttributeWithKey:key andDateValue:traitValue];
                        [RSLogger logInfo: @"Braze setCustomAttributeWithKey: andDateValue: "];
                    } else if ([traitValue isKindOfClass:[NSNumber class]]) {
                        if (strcmp([traitValue objCType], [@(YES) objCType]) == 0) {
                            [[Appboy sharedInstance].user setCustomAttributeWithKey:key andBOOLValue:[(NSNumber *)traitValue boolValue]];
                            [RSLogger logInfo:@"Braze setCustomAttributeWithKey: andBOOLValue:"];
                        } else if (strcmp([traitValue objCType], @encode(short)) == 0 ||
                                   strcmp([traitValue objCType], @encode(int)) == 0 ||
                                   strcmp([traitValue objCType], @encode(long)) == 0) {
                            [[Appboy sharedInstance].user setCustomAttributeWithKey:key andIntegerValue:[(NSNumber *)traitValue integerValue]];
                            [RSLogger logInfo:@"Braze setCustomAttributeWithKey: andIntegerValue:"];
                        } else if (strcmp([traitValue objCType], @encode(float)) == 0 ||
                                   strcmp([traitValue objCType], @encode(double)) == 0) {
                            [[Appboy sharedInstance].user setCustomAttributeWithKey:key andDoubleValue:[(NSNumber *)traitValue doubleValue]];
                            [RSLogger logInfo:@"Braze setCustomAttributeWithKey: andDoubleValue:"];
                        } else {
                            [RSLogger logInfo:@"NSNumber could not be mapped to customAttribute"];
                        }
                    } else if ([traitValue isKindOfClass:[NSArray class]]) {
                        [[Appboy sharedInstance].user setCustomAttributeArrayWithKey:key array:traitValue];
                        [RSLogger logInfo:@"Braze setCustomAttributeArrayWithKey: array:"];
                    }
                }
            }
        }
        self.previousIdentifyElement = message;
    } else {
        if ([message.event isEqualToString:@"Install Attributed"]) {
            if ([message.properties[@"campaign"] isKindOfClass:[NSDictionary class]]) {
                NSDictionary *attributionDataDictionary = (NSDictionary *)message.properties[@"campaign"];
                ABKAttributionData *attributionData = [[ABKAttributionData alloc]
                                                       initWithNetwork:attributionDataDictionary[@"source"]
                                                       campaign:attributionDataDictionary[@"name"]
                                                       adGroup:attributionDataDictionary[@"ad_group"]
                                                       creative:attributionDataDictionary[@"ad_creative"]];
                [[Appboy sharedInstance].user setAttributionData:attributionData];
                [RSLogger logInfo:@"Braze setAttributionData:"];
            } else {
                [[Appboy sharedInstance] logCustomEvent:message.event withProperties:message.properties];
                [RSLogger logInfo:@"Braze logCustomEvent: withProperties:"];
            }
        } else if ([message.event isEqualToString:@"Order Completed"]) {
            if (message.properties != nil) {
                NSArray <BrazePurchase *>*brazePurchaseList = [self getPurchaseList:message.properties];
                if (brazePurchaseList != nil) {
                    for (BrazePurchase *brazePurchase in brazePurchaseList) {
                        [[Appboy sharedInstance] logPurchase:brazePurchase.productId inCurrency:brazePurchase.currency atPrice:brazePurchase.price withQuantity:brazePurchase.quantity andProperties:brazePurchase.properties];
                        [RSLogger logInfo:@"Braze logPurchase: inCurrency: atPrice: withQuantity: andProperties:"];
                    }
                }
            }
        } else {
            [[Appboy sharedInstance] logCustomEvent:message.event withProperties:message.properties];
            [RSLogger logInfo:@"Braze logCustomEvent: withProperties:"];
        }
    }
}

- (NSMutableArray <BrazePurchase *>* _Nullable)getPurchaseList:(NSDictionary *)properties {
    NSArray <NSDictionary *>*productList = properties[@"products"];
    if (productList == nil || productList.count == 0) {
        return nil;
    }
    NSString *currency = @"USD";
    if ([properties[@"currency"] isKindOfClass:[NSString class]] && [(NSString *)properties[@"currency"] length] == 3) {
        currency = (NSString *)properties[@"currency"];
    }
    
    NSArray <NSString *>*ignoredKeys = @[@"product_id", @"quantity", @"price", @"products", @"time", @"event_name", @"currency"];
    NSMutableDictionary *otherProperties = [[NSMutableDictionary alloc] init];
    [properties enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![ignoredKeys containsObject:key]) {
            [otherProperties setObject:obj forKey:key];
        }
    }];
    
    NSMutableArray <BrazePurchase *>*purchaseList = [[NSMutableArray alloc] init];
    for (NSDictionary <NSString *, NSObject *>*product in productList) {
        __block BrazePurchase *brazePurchase = [[BrazePurchase alloc] init];
        NSMutableDictionary *appboyProperties = [[NSMutableDictionary alloc] initWithDictionary:otherProperties];
        
        [product enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSObject * _Nonnull obj, BOOL * _Nonnull stop) {
            if ([key isEqualToString:@"product_id"]) {
                brazePurchase.productId = [NSString stringWithFormat:@"%@", obj];
            } else if ([key isEqualToString:@"quantity"]) {
                brazePurchase.quantity = [[NSString stringWithFormat:@"%@", obj] intValue];
            } else if ([key isEqualToString:@"price"]) {
                brazePurchase.price = [RudderBrazeIntegration revenueDecimal:obj];
            } else {
                [appboyProperties setObject:obj forKey:key];
            }
        }];
        brazePurchase.currency = currency;
        brazePurchase.properties = appboyProperties;
        if (brazePurchase.productId == nil || brazePurchase.price == nil) {
            continue;
        }
        [purchaseList addObject:brazePurchase];
    }
    return purchaseList.count > 0 ? purchaseList : nil;
}

+ (NSDecimalNumber *)revenueDecimal:(id)revenueProp {
    if (revenueProp ) {
        if ([revenueProp  isKindOfClass:[NSString class]]) {
            return [NSDecimalNumber decimalNumberWithString:revenueProp];
        } else if ([revenueProp  isKindOfClass:[NSDecimalNumber class]]) {
            return revenueProp;
        } else if ([revenueProp  isKindOfClass:[NSNumber class]]) {
            return [NSDecimalNumber decimalNumberWithDecimal:[revenueProp  decimalValue]];
        }
    }
    return nil;
}

- (void)flush {
    [[Appboy sharedInstance] requestImmediateDataFlush];
    [RSLogger logInfo: @"Braze flushDataAndProcessRequestQueue]"];
}

- (void)reset {
    //[self flush];
    //NO BRAZE EQUIVALENT
    //[Adjust resetSessionPartnerParameters];
}

// Forward device token to Braze
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[Appboy sharedInstance] registerDeviceToken:deviceToken];
    [RSLogger logInfo:@"Braze registerDeviceToken:"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![[UIApplication sharedApplication].delegate respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)]) {
            [self logPushIfComesInBeforeBrazeInitializedWithIdentifier:nil];
        }
    });
}

- (void)receivedRemoteNotification:(NSDictionary *)userInfo {
    if (![self logPushIfComesInBeforeBrazeInitializedWithIdentifier:nil]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[Appboy sharedInstance] registerApplication:[UIApplication sharedApplication] didReceiveRemoteNotification:userInfo];
        });
    }
    [RSLogger logInfo:@"Braze registerApplication: didReceiveRemoteNotification:"];
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
    if (![self logPushIfComesInBeforeBrazeInitializedWithIdentifier:identifier]) {
        [[Appboy sharedInstance] getActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:nil];
    }
    [RSLogger logInfo:@"Braze getActionWithIdentifier: forRemoteNotification: completionHandler:"];
}

- (BOOL) logPushIfComesInBeforeBrazeInitializedWithIdentifier:(NSString *)identifier {
    NSDictionary *pushDictionary = [[RudderBrazeFactory instance] getPushPayload];
    if (pushDictionary != nil && pushDictionary.count > 0) {
        /*
         MIRATE TO USERNOTIFICATIONS - WHOLE OF THIS IS DEPRECATED
         //handle push before braze is initalised
         if ([[Appboy sharedInstance] respondsToSelector:@selector(handleRemotePushNotification:withIdentifier:completionHandler:applicationState:)]) {
         
         [[Appboy sharedInstance]  handleRemotePushNotification:pushDictionary
         withIdentifier:identifier
         completionHandler:nil
         applicationState:UIApplicationStateInactive];
         }
         */
        [[RudderBrazeFactory instance] resetRemoteNotification];
        
        
        return YES;
    }
    return NO;
}

- (BOOL) compareAddress: (NSDictionary *) curr withPrevAddress:(NSDictionary *)prev {
    if (prev != nil && curr != nil) {
        NSString *prevCity = [prev objectForKey:@"city"];
        NSString *currCity = [curr objectForKey:@"city"];
        
        NSString *prevCountry = [prev objectForKey:@"country"];
        NSString *currCountry = [curr objectForKey:@"country"];
        
        return [prevCity isEqualToString:currCity] && [prevCountry isEqualToString:currCountry];
    }
    return NO;
}

- (id) needUpdate: (NSString *) key withMessage:(RSMessage *) element {
    id currValue = [element.context.traits objectForKey:key];
    
    if (currValue == nil) { return nil; }
    
    if (self.supportDedup) {
        id prevValue = [self.previousIdentifyElement.context.traits objectForKey:key];
        
        if (prevValue == nil) { return currValue; }
        
        if ([key isEqualToString:@"address"] && [currValue isKindOfClass:[NSDictionary class]] && [prevValue isKindOfClass:[NSDictionary class]]) {
            if ([self compareAddress:(NSDictionary *)currValue withPrevAddress:(NSDictionary *)prevValue]) {
                return nil;
            } else {
                return currValue;
            }
        } else if ([key isEqualToString:@"birthday"] && [currValue isKindOfClass:[NSDate class]] && [prevValue isKindOfClass:[NSDate class]]) {
            if ([(NSDate *)currValue compare:(NSDate *)prevValue] == NSOrderedSame) {
                return nil;
            }
            return currValue;
        } else if (currValue != nil && [currValue isEqual:prevValue]) {
            return nil;
        } else {
            return currValue;
        }
    }
    
    return currValue;
}

@end

@implementation BrazePurchase

- (instancetype)init {
    self = [super init];
    if (self) {
        _quantity = 1;
        _properties = [[NSMutableDictionary alloc] init];
        _currency = @"USD";
    }
    return self;
}

@end
