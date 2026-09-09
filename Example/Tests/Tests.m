//
//  Tests.m
//  Rudder-Braze
//
//  Unit tests for the recommended-ecommerce mapping in RudderBrazeEcommerceUtils. The array
//  assertions (products / discounts / type come back as NSArrays) guard the contract that the
//  dictionary handed to Braze's logCustomEvent:properties: keeps its arrays intact.
//

@import XCTest;
@import Rudder_Braze;

@interface RSTestClient : NSObject
@property (nonatomic, copy) NSString *anonymousId;
- (NSString *)getAnonymousId;
@end

@implementation RSTestClient
- (NSString *)getAnonymousId { return self.anonymousId; }
@end

@interface RSTestBrazeUser : NSObject
@property (nonatomic, strong) NSMutableArray<NSString *> *calls;
@end


@implementation RSTestBrazeUser
- (instancetype)init {
    if (self = [super init]) {
        _calls = [NSMutableArray array];
    }
    return self;
}
- (void)addAlias:(NSString *)alias label:(NSString *)label {
    [self.calls addObject:[NSString stringWithFormat:@"alias:%@:%@", alias, label]];
}
- (void)setLastName:(NSString *)lastName { [self.calls addObject:[@"lastName:" stringByAppendingString:lastName]]; }
- (void)setEmail:(NSString *)email { [self.calls addObject:[@"email:" stringByAppendingString:email]]; }
@end

@interface RSTestBraze : NSObject
@property (nonatomic, strong) RSTestBrazeUser *user;
@property (nonatomic, strong) NSMutableArray<NSString *> *calls;
@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, strong) NSDictionary *eventProperties;
@property (nonatomic, copy) NSString *purchaseProductId;
@property (nonatomic, copy) NSString *purchaseCurrency;
@property (nonatomic) double purchasePrice;
@property (nonatomic) NSInteger purchaseQuantity;
@property (nonatomic) BOOL flushed;
@end

@implementation RSTestBraze
- (instancetype)init {
    if (self = [super init]) {
        _calls = [NSMutableArray array];
        _user = [RSTestBrazeUser new];
        _user.calls = _calls;
    }
    return self;
}
- (void)changeUser:(NSString *)userId { [self.calls addObject:[@"changeUser:" stringByAppendingString:userId]]; }
- (void)logCustomEvent:(NSString *)name properties:(NSDictionary *)properties {
    self.eventName = name;
    self.eventProperties = properties;
}
- (void)logPurchase:(NSString *)productId
            currency:(NSString *)currency
               price:(double)price
            quantity:(NSInteger)quantity
          properties:(NSDictionary *)properties {
    self.purchaseProductId = productId;
    self.purchaseCurrency = currency;
    self.purchasePrice = price;
    self.purchaseQuantity = quantity;
}
- (void)requestImmediateDataFlush { self.flushed = YES; }
@end

@interface RSTestableBrazeIntegration : RudderBrazeIntegration
@property (nonatomic, strong) RSTestBraze *testBraze;
@property (nonatomic, strong) BRZConfiguration *capturedConfiguration;
@end

@implementation RSTestableBrazeIntegration
- (id)createBrazeWithConfiguration:(BRZConfiguration *)configuration {
    self.capturedConfiguration = configuration;
    self.testBraze = [RSTestBraze new];
    return self.testBraze;
}
@end

@interface Tests : XCTestCase
@end

@implementation Tests

#pragma mark - helpers

- (NSDictionary *)buildForEvent:(NSString *)eventName properties:(NSDictionary *)props {
    RudderBrazeEcommerceEvent *event = [RudderBrazeEcommerceUtils resolveEcommerceEvent:eventName];
    XCTAssertNotNil(event, @"expected a mapped event for %@", eventName);
    return [RudderBrazeEcommerceUtils buildEcommerceProperties:event properties:props];
}

- (NSDictionary *)buildOrderCompleted:(NSDictionary *)props {
    return [self buildForEvent:@"Order Completed" properties:props];
}

- (NSDictionary *)firstProduct:(NSDictionary *)out {
    NSArray *products = out[@"products"];
    XCTAssertTrue([products isKindOfClass:[NSArray class]]);
    XCTAssertGreaterThan(products.count, 0u);
    return products[0];
}

- (RSTestableBrazeIntegration *)integrationWithMode:(ConnectionMode)mode
                            recommendedEcommerce:(BOOL)recommendedEcommerce {
    NSString *modeName = mode == ConnectionModeDevice ? @"device" :
        (mode == ConnectionModeHybrid ? @"hybrid" : @"cloud");
    RSTestClient *client = [RSTestClient new];
    client.anonymousId = @"anonymous-test";
    RSTestableBrazeIntegration *integration = [[RSTestableBrazeIntegration alloc]
        initWithConfig:@{
            @"appKey": @"api-key",
            @"connectionMode": modeName,
            @"useEcommerceRecommendedEvents": @(recommendedEcommerce),
        }
        withAnalytics:(RSClient *)client
        rudderConfig:[RSConfig new]];
    [integration.testBraze.calls removeAllObjects];
    return integration;
}

- (RSMessage *)messageWithType:(NSString *)type {
    RSMessage *message = [RSMessage new];
    message.type = type;
    message.context = [[RSContext alloc] initWithDict:@{}];
    message.context.traits = [NSMutableDictionary dictionary];
    message.context.externalIds = [NSMutableArray array];
    return message;
}

#pragma mark - Braze 18 integration behavior

- (void)testInitializationUsesConfiguredEndpointAndSetsAnonymousAlias {
    RSTestClient *client = [RSTestClient new];
    client.anonymousId = @"anonymous-123";
    RSConfig *rudderConfig = [RSConfig new];
    RSTestableBrazeIntegration *integration = [[RSTestableBrazeIntegration alloc]
        initWithConfig:@{
            @"appKey": @"api-key",
            @"dataCenter": @"EU-01",
            @"connectionMode": @"device",
        }
        withAnalytics:(RSClient *)client
        rudderConfig:rudderConfig];

    XCTAssertNotNil(integration);
    XCTAssertEqualObjects(integration.capturedConfiguration.api.key, @"api-key");
    XCTAssertEqualObjects(integration.capturedConfiguration.api.endpoint, @"sdk.fra-01.braze.eu");
    XCTAssertEqualObjects(integration.testBraze.user.calls, (@[@"alias:anonymous-123:rudder_id"]));
    XCTAssertEqual([integration getUnderlyingInstance], integration.testBraze);
}

- (void)testIdentifyChangesUserBeforeUpdatingAttributes {
    RSTestableBrazeIntegration *integration = [self integrationWithMode:ConnectionModeDevice recommendedEcommerce:NO];
    RSMessage *message = [self messageWithType:@"identify"];
    message.userId = @"user-123";
    message.context.traits = [@{@"lastname": @"Doe", @"email": @"user@example.com"} mutableCopy];

    [integration dump:message];

    XCTAssertEqualObjects(integration.testBraze.calls,
                          (@[@"changeUser:user-123", @"lastName:Doe", @"email:user@example.com"]));
}

- (void)testIdentifyPreservesOrderingWhenSwitchingUsers {
    RSTestableBrazeIntegration *integration = [self integrationWithMode:ConnectionModeDevice recommendedEcommerce:NO];
    RSMessage *first = [self messageWithType:@"identify"];
    first.userId = @"user-1";
    first.context.traits = [@{@"email": @"first@example.com"} mutableCopy];
    RSMessage *second = [self messageWithType:@"identify"];
    second.userId = @"user-2";
    second.context.traits = [@{@"lastname": @"Second"} mutableCopy];

    [integration dump:first];
    [integration dump:second];

    XCTAssertEqualObjects(integration.testBraze.calls,
                          (@[@"changeUser:user-1", @"email:first@example.com",
                             @"changeUser:user-2", @"lastName:Second"]));
}

- (void)testExternalIdTakesPriorityOverRudderUserId {
    RSTestableBrazeIntegration *integration = [self integrationWithMode:ConnectionModeDevice recommendedEcommerce:NO];
    RSMessage *message = [self messageWithType:@"identify"];
    message.userId = @"rudder-user";
    message.context.externalIds = [@[@{@"type": RSBrazeExternalIdKey, @"id": @"braze-user"}] mutableCopy];

    [integration dump:message];

    XCTAssertEqualObjects(integration.testBraze.calls, (@[@"changeUser:braze-user"]));
}

- (void)testRecommendedEcommerceFlagUsesBrazeEcommerceEvent {
    RSTestableBrazeIntegration *integration = [self integrationWithMode:ConnectionModeDevice recommendedEcommerce:YES];
    RSMessage *message = [self messageWithType:@"track"];
    message.event = @"Product Viewed";
    message.properties = @{@"product_id": @"product-1", @"name": @"Shoe", @"price": @10, @"currency": @"USD"};

    [integration dump:message];

    XCTAssertEqualObjects(integration.testBraze.eventName, @"ecommerce.product_viewed");
    XCTAssertEqualObjects(integration.testBraze.eventProperties[@"product_id"], @"product-1");
}

- (void)testLegacyOrderCompletedLogsPurchase {
    RSTestableBrazeIntegration *integration = [self integrationWithMode:ConnectionModeDevice recommendedEcommerce:NO];
    RSMessage *message = [self messageWithType:@"track"];
    message.event = @"Order Completed";
    message.properties = @{
        @"currency": @"EUR",
        @"products": @[@{@"product_id": @"product-1", @"price": @12.5, @"quantity": @2}],
    };

    [integration dump:message];

    XCTAssertEqualObjects(integration.testBraze.purchaseProductId, @"product-1");
    XCTAssertEqualObjects(integration.testBraze.purchaseCurrency, @"EUR");
    XCTAssertEqualWithAccuracy(integration.testBraze.purchasePrice, 12.5, 0.0001);
    XCTAssertEqual(integration.testBraze.purchaseQuantity, 2);
}

- (void)testHybridModeDoesNotSendDeviceModeEvents {
    RSTestableBrazeIntegration *integration = [self integrationWithMode:ConnectionModeHybrid recommendedEcommerce:NO];
    RSMessage *message = [self messageWithType:@"track"];
    message.event = @"Test Event";
    message.properties = @{};

    [integration dump:message];

    XCTAssertNil(integration.testBraze.eventName);
}

- (void)testFlushRequestsImmediateDataFlush {
    RSTestableBrazeIntegration *integration = [self integrationWithMode:ConnectionModeDevice recommendedEcommerce:NO];
    [integration flush];
    XCTAssertTrue(integration.testBraze.flushed);
}

#pragma mark - resolveEcommerceEvent

- (void)testResolveEcommerceEventCaseInsensitive {
    XCTAssertEqualObjects([RudderBrazeEcommerceUtils resolveEcommerceEvent:@"Order Completed"].brazeEvent, @"ecommerce.order_placed");
    XCTAssertEqualObjects([RudderBrazeEcommerceUtils resolveEcommerceEvent:@"order completed"].brazeEvent, @"ecommerce.order_placed");
    XCTAssertEqualObjects([RudderBrazeEcommerceUtils resolveEcommerceEvent:@"  Order Completed  "].brazeEvent, @"ecommerce.order_placed");
    XCTAssertEqualObjects([RudderBrazeEcommerceUtils resolveEcommerceEvent:@"Product Viewed"].brazeEvent, @"ecommerce.product_viewed");

    RudderBrazeEcommerceEvent *added = [RudderBrazeEcommerceUtils resolveEcommerceEvent:@"Product Added"];
    XCTAssertEqualObjects(added.brazeEvent, @"ecommerce.cart_updated");
    XCTAssertEqualObjects(added.action, @"add");
    XCTAssertEqualObjects([RudderBrazeEcommerceUtils resolveEcommerceEvent:@"Product Removed"].action, @"remove");
}

- (void)testResolveEcommerceEventReturnsNilForUnmapped {
    // Product Clicked and Cart Viewed intentionally stay generic custom events.
    XCTAssertNil([RudderBrazeEcommerceUtils resolveEcommerceEvent:@"Product Clicked"]);
    XCTAssertNil([RudderBrazeEcommerceUtils resolveEcommerceEvent:@"Cart Viewed"]);
    XCTAssertNil([RudderBrazeEcommerceUtils resolveEcommerceEvent:@"Some Random Event"]);
    XCTAssertNil([RudderBrazeEcommerceUtils resolveEcommerceEvent:nil]);
}

#pragma mark - Order Completed -> ecommerce.order_placed

- (void)testOrderCompletedMapsCoreFieldsAndProducts {
    NSDictionary *out = [self buildOrderCompleted:@{
        @"order_id": @"O-100",
        @"total": @200,
        @"currency": @"USD",
        @"products": @[@{
            @"product_id": @"P1",
            @"name": @"Mug",
            @"price": @12.5,
            @"quantity": @3,
        }],
    }];

    XCTAssertEqualObjects(out[@"order_id"], @"O-100");
    XCTAssertEqualObjects(out[@"currency"], @"USD");
    XCTAssertEqual([out[@"total_value"] intValue], 200);
    XCTAssertEqualObjects(out[@"source"], @"ios");

    NSDictionary *product = [self firstProduct:out];
    XCTAssertEqualObjects(product[@"product_id"], @"P1");
    XCTAssertEqualObjects(product[@"product_name"], @"Mug");
    // variant_id falls back to sku -> product_id when absent.
    XCTAssertEqualObjects(product[@"variant_id"], @"P1");
    XCTAssertEqualWithAccuracy([product[@"price"] doubleValue], 12.5, 0.0001);
    XCTAssertEqual([product[@"quantity"] intValue], 3);
}

- (void)testOrderCompletedTotalValueFallback {
    // Dictionaries are bound to locals first: commas inside an inline @{...} literal would be parsed
    // as extra XCTAssert macro arguments.
    NSDictionary *all = @{@"total": @200, @"revenue": @1, @"value": @2};
    NSDictionary *revenueValue = @{@"revenue": @50, @"value": @2};
    NSDictionary *valueOnly = @{@"value": @30};
    XCTAssertEqual([[self buildOrderCompleted:all][@"total_value"] intValue], 200);
    XCTAssertEqual([[self buildOrderCompleted:revenueValue][@"total_value"] intValue], 50);
    XCTAssertEqual([[self buildOrderCompleted:valueOnly][@"total_value"] intValue], 30);
}

#pragma mark - metadata pass-through

- (void)testMetadataRoutesUnmappedKeysAndSkipsNull {
    NSDictionary *out = [self buildOrderCompleted:@{
        @"order_id": @"O-100",
        @"affiliation": @"web-store",        // unmapped top-level -> metadata
        @"ignored_null": [NSNull null],      // NSNull must be filtered, not copied
        @"products": @[@{
            @"product_id": @"P1",
            @"color": @"blue",               // unmapped product key -> products[].metadata
        }],
    }];

    XCTAssertNil(out[@"affiliation"]);
    NSDictionary *metadata = out[@"metadata"];
    XCTAssertEqualObjects(metadata[@"affiliation"], @"web-store");
    XCTAssertNil(metadata[@"ignored_null"]);

    NSDictionary *product = [self firstProduct:out];
    XCTAssertNil(product[@"color"]);
    XCTAssertEqualObjects(product[@"metadata"][@"color"], @"blue");
}

#pragma mark - coercion

- (void)testCoercionNumericStringsAndNumbers {
    NSDictionary *out = [self buildOrderCompleted:@{
        @"total": @"199.99",                 // FLOAT, numeric string -> number
        @"products": @[@{
            @"product_id": @1001,            // STRING, number -> string
            @"price": @"12.5",               // FLOAT, numeric string -> number
            @"quantity": @"3",               // INTEGER, numeric string -> number
        }],
    }];

    XCTAssertEqualWithAccuracy([out[@"total_value"] doubleValue], 199.99, 0.0001);

    NSDictionary *product = [self firstProduct:out];
    XCTAssertTrue([product[@"product_id"] isKindOfClass:[NSString class]]);
    XCTAssertEqualObjects(product[@"product_id"], @"1001");
    XCTAssertEqualWithAccuracy([product[@"price"] doubleValue], 12.5, 0.0001);
    XCTAssertEqual([product[@"quantity"] intValue], 3);
}

- (void)testCoercionUnparsableLeftAsIs {
    // "free" cannot be coerced to a FLOAT price; it is sent verbatim (warned, never dropped).
    NSDictionary *product = [self firstProduct:[self buildOrderCompleted:@{
        @"order_id": @"O-100",
        @"products": @[@{@"product_id": @"P1", @"price": @"free"}],
    }]];
    XCTAssertEqualObjects(product[@"price"], @"free");
}

#pragma mark - empty products

- (void)testEmptyProductsAreOmitted {
    // An all-empty products array must be treated as "no products" (key omitted).
    NSDictionary *out = [self buildOrderCompleted:@{@"order_id": @"O-100", @"products": @[@{}]}];
    XCTAssertNil(out[@"products"]);

    // A mix keeps only the non-empty product.
    NSDictionary *mixed = [self buildOrderCompleted:@{@"order_id": @"O-100", @"products": @[@{}, @{@"product_id": @"P1"}]}];
    NSArray *products = mixed[@"products"];
    XCTAssertEqual(products.count, 1u);
    XCTAssertEqualObjects(products[0][@"product_id"], @"P1");
}

#pragma mark - arrays preserved (the #1 guard)

- (void)testProductsAndDiscountsStayArrays {
    NSDictionary *out = [self buildOrderCompleted:@{
        @"order_id": @"O-100",
        @"total": @200,
        @"currency": @"USD",
        @"discounts": @[@{@"code": @"WELCOME", @"amount": @15}],
        @"products": @[
            @{@"product_id": @"P1", @"name": @"Mug"},
            @{@"product_id": @"P2", @"name": @"Saucer"},
        ],
    }];

    XCTAssertTrue([out[@"products"] isKindOfClass:[NSArray class]]);
    NSArray *products = out[@"products"];
    XCTAssertEqual(products.count, 2u);
    XCTAssertTrue([products[0] isKindOfClass:[NSDictionary class]]);
    XCTAssertEqualObjects(products[0][@"product_id"], @"P1");

    XCTAssertTrue([out[@"discounts"] isKindOfClass:[NSArray class]]);
    XCTAssertEqual([out[@"discounts"] count], 1u);
}

- (void)testTypeStringArrayStaysArray {
    // product_viewed's "type" is a STRING_ARRAY; it must stay an NSArray.
    NSDictionary *out = [self buildForEvent:@"Product Viewed" properties:@{
        @"product_id": @"PV1",
        @"type": @[@"shoe", @"running"],
    }];

    XCTAssertTrue([out[@"type"] isKindOfClass:[NSArray class]]);
    NSArray *type = out[@"type"];
    XCTAssertEqual(type.count, 2u);
    XCTAssertEqualObjects(type[0], @"shoe");
    XCTAssertEqualObjects(type[1], @"running");
}

#pragma mark - malformed products -> metadata (never dropped)

- (void)testMalformedProductsValueFlowsToMetadata {
    // A non-array `products` must not be silently dropped; it is preserved under metadata.
    NSDictionary *out = [self buildOrderCompleted:@{
        @"order_id": @"O-100",
        @"products": @"not-an-array",
    }];
    XCTAssertNil(out[@"products"]);
    XCTAssertEqualObjects(out[@"metadata"][@"products"], @"not-an-array");
}

- (void)testMixedProductsArrayFlowsToMetadata {
    // An array containing a non-object element is treated as malformed (all-or-nothing) and preserved
    // under metadata rather than partially mapped.
    NSArray *mixed = @[@{@"product_id": @"P1"}, @"junk"];
    NSDictionary *props = @{@"order_id": @"O-100", @"products": mixed};
    NSDictionary *out = [self buildOrderCompleted:props];
    XCTAssertNil(out[@"products"]);
    XCTAssertEqualObjects(out[@"metadata"][@"products"], mixed);
}

#pragma mark - cart_updated products[]

- (void)testCartUpdatedMapsExplicitProductsArray {
    // An explicit products[] on Product Added is mapped item-by-item (not folded from top-level fields).
    NSDictionary *props = @{
        @"cart_id": @"C-1",
        @"products": @[
            @{@"product_id": @"P1", @"name": @"Mug"},
            @{@"product_id": @"P2", @"name": @"Saucer"},
        ],
    };
    NSDictionary *out = [self buildForEvent:@"Product Added" properties:props];

    XCTAssertEqualObjects(out[@"action"], @"add");
    NSArray *products = out[@"products"];
    XCTAssertTrue([products isKindOfClass:[NSArray class]]);
    XCTAssertEqual(products.count, 2u);
    XCTAssertEqualObjects(products[0][@"product_id"], @"P1");
    XCTAssertEqualObjects(products[0][@"product_name"], @"Mug");
    XCTAssertEqualObjects(products[1][@"product_id"], @"P2");
    // products[] is consumed, so it is not duplicated into metadata.
    XCTAssertNil(out[@"metadata"][@"products"]);
}

- (void)testCartUpdatedFallsBackToTopLevelProduct {
    // Without products[], top-level product fields fold into a single-element products array.
    NSDictionary *props = @{
        @"cart_id": @"C-1",
        @"product_id": @"P1",
        @"name": @"Mug",
        @"price": @9.99,
    };
    NSDictionary *out = [self buildForEvent:@"Product Removed" properties:props];

    XCTAssertEqualObjects(out[@"action"], @"remove");
    NSArray *products = out[@"products"];
    XCTAssertEqual(products.count, 1u);
    XCTAssertEqualObjects(products[0][@"product_id"], @"P1");
    XCTAssertEqualObjects(products[0][@"product_name"], @"Mug");
}

@end
