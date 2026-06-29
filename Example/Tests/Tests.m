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

@end
