//
//  RudderBrazeEcommerceUtils.m
//

#import "RudderBrazeEcommerceUtils.h"

#if defined(__has_include) && __has_include(<Rudder/Rudder.h>)
#import <Rudder/Rudder.h>
#else
#import "Rudder.h"
#endif

#pragma mark - Event type

typedef NS_ENUM(NSInteger, RudderBrazeEcommerceEventType) {
    RudderBrazeEcommerceEventTypeProductViewed,
    RudderBrazeEcommerceEventTypeProductAdded,
    RudderBrazeEcommerceEventTypeProductRemoved,
    RudderBrazeEcommerceEventTypeCheckoutStarted,
    RudderBrazeEcommerceEventTypeOrderCompleted,
    RudderBrazeEcommerceEventTypeOrderRefunded,
    RudderBrazeEcommerceEventTypeOrderCancelled
};

@interface RudderBrazeEcommerceEvent ()
@property (nonatomic, assign) RudderBrazeEcommerceEventType type;
@property (nonatomic, copy) NSString *brazeEvent;
@property (nonatomic, copy, nullable) NSString *action;
+ (instancetype)eventWithType:(RudderBrazeEcommerceEventType)type brazeEvent:(NSString *)brazeEvent action:(nullable NSString *)action;
@end

@implementation RudderBrazeEcommerceEvent

+ (instancetype)eventWithType:(RudderBrazeEcommerceEventType)type brazeEvent:(NSString *)brazeEvent action:(NSString *)action {
    RudderBrazeEcommerceEvent *event = [[RudderBrazeEcommerceEvent alloc] init];
    event.type = type;
    event.brazeEvent = brazeEvent;
    event.action = action;
    return event;
}

@end

#pragma mark - Constants

static NSString *const BRAZE_EVENT_PRODUCT_VIEWED = @"ecommerce.product_viewed";
static NSString *const BRAZE_EVENT_CART_UPDATED = @"ecommerce.cart_updated";
static NSString *const BRAZE_EVENT_CHECKOUT_STARTED = @"ecommerce.checkout_started";
static NSString *const BRAZE_EVENT_ORDER_PLACED = @"ecommerce.order_placed";
static NSString *const BRAZE_EVENT_ORDER_REFUNDED = @"ecommerce.order_refunded";
static NSString *const BRAZE_EVENT_ORDER_CANCELLED = @"ecommerce.order_cancelled";

static NSString *const ACTION_ADD = @"add";
static NSString *const ACTION_REMOVE = @"remove";

static NSString *const SOURCE_KEY = @"source";
static NSString *const SOURCE = @"ios";

// RudderStack ecommerce source keys. Keys the SDK exposes come from RSECommerceParamNames
// (imported via Rudder.h); the rest have no SDK constant and use the RS spec field name.
#define EC_PRODUCT_ID  KeyProductId
#define EC_QUANTITY    KeyQuantity
#define EC_PRICE       KeyPrice
#define EC_CURRENCY    KeyCurrency
#define EC_PRODUCTS    KeyProducts
#define EC_CART_ID     KeyCartId
#define EC_CHECKOUT_ID KeyCheckoutId
#define EC_ORDER_ID    KeyOrderId
#define EC_TOTAL       KeyTotal
#define EC_REVENUE     KeyRevenue
#define EC_DISCOUNT    KeyDiscount
#define EC_REASON      KeyReason

static NSString *const EC_SKU = @"sku";
static NSString *const EC_NAME = @"name";
static NSString *const EC_VARIANT = @"variant";
static NSString *const EC_IMAGE_URL = @"image_url";
static NSString *const EC_URL = @"url";
static NSString *const EC_VALUE = @"value";
static NSString *const EC_TAX = @"tax";
static NSString *const EC_SHIPPING = @"shipping";
static NSString *const EC_TYPE = @"type";
static NSString *const EC_SUBTOTAL_VALUE = @"subtotal_value";
static NSString *const EC_DISCOUNTS = @"discounts";
static NSString *const EC_TOTAL_DISCOUNTS = @"total_discounts";
static NSString *const EC_CANCEL_REASON = @"cancel_reason";

// Braze recommended-event field names.
static NSString *const BRAZE_PRODUCT_ID = @"product_id";
static NSString *const BRAZE_PRODUCT_NAME = @"product_name";
static NSString *const BRAZE_VARIANT_ID = @"variant_id";
static NSString *const BRAZE_QUANTITY = @"quantity";
static NSString *const BRAZE_PRICE = @"price";
static NSString *const BRAZE_IMAGE_URL = @"image_url";
static NSString *const BRAZE_PRODUCT_URL = @"product_url";
static NSString *const BRAZE_CART_ID = @"cart_id";
static NSString *const BRAZE_ACTION = @"action";
static NSString *const BRAZE_ORDER_ID = @"order_id";
static NSString *const BRAZE_CHECKOUT_ID = @"checkout_id";
static NSString *const BRAZE_TOTAL_VALUE = @"total_value";
static NSString *const BRAZE_CURRENCY = @"currency";
static NSString *const BRAZE_PRODUCTS = @"products";
static NSString *const BRAZE_TAX = @"tax";
static NSString *const BRAZE_SHIPPING = @"shipping";
static NSString *const BRAZE_TOTAL_DISCOUNTS = @"total_discounts";
static NSString *const BRAZE_CANCEL_REASON = @"cancel_reason";
static NSString *const BRAZE_TYPE = @"type";
static NSString *const BRAZE_SUBTOTAL_VALUE = @"subtotal_value";
static NSString *const BRAZE_DISCOUNTS = @"discounts";
static NSString *const BRAZE_METADATA = @"metadata";

#pragma mark - Type coercion

// The type Braze expects for a recommended-event field. Resolved values are coerced toward this type
// where possible; an un-coercible value is sent verbatim and surfaced via a single warning per event.
typedef NS_ENUM(NSInteger, RudderBrazeFieldType) {
    RudderBrazeFieldTypeString,
    RudderBrazeFieldTypeInteger,
    RudderBrazeFieldTypeFloat,
    RudderBrazeFieldTypeStringArray,
    RudderBrazeFieldTypeArray
};

static NSArray<NSArray *> *fieldTypeTable(void);
static void coerceAndWarnTypes(NSString *brazeEvent, NSMutableDictionary *out);
static id coerceValue(id value, RudderBrazeFieldType type);
static BOOL valueMatchesType(id value, RudderBrazeFieldType type);
static BOOL isIntegralNumber(NSNumber *number);
static BOOL isStringArray(id value);
static BOOL isBooleanNumber(NSNumber *number);
static NSString *numberToBrazeString(NSNumber *number);
static NSString *fieldTypeName(RudderBrazeFieldType type);
static NSNumber *parseDoubleOrNil(NSString *string);
static NSNumber *parseLongOrNil(NSString *string);

@implementation RudderBrazeEcommerceUtils

#pragma mark - Consumed-key sets

// Source keys consumed by each event's mapping; everything else flows into metadata.
+ (NSSet<NSString *> *)productConsumedKeys {
    static NSSet *keys; static dispatch_once_t t;
    dispatch_once(&t, ^{ keys = [NSSet setWithArray:@[EC_PRODUCT_ID, EC_SKU, EC_NAME, EC_VARIANT, EC_QUANTITY, EC_PRICE, EC_IMAGE_URL, EC_URL]]; });
    return keys;
}

+ (NSSet<NSString *> *)productViewedConsumedKeys {
    static NSSet *keys; static dispatch_once_t t;
    dispatch_once(&t, ^{ keys = [NSSet setWithArray:@[EC_PRODUCT_ID, EC_SKU, EC_NAME, EC_VARIANT, EC_PRICE, EC_CURRENCY, EC_IMAGE_URL, EC_URL, EC_TYPE]]; });
    return keys;
}

+ (NSSet<NSString *> *)cartUpdatedConsumedKeys {
    static NSSet *keys; static dispatch_once_t t;
    dispatch_once(&t, ^{ keys = [NSSet setWithArray:@[EC_CART_ID, EC_CURRENCY, EC_PRODUCT_ID, EC_SKU, EC_NAME, EC_VARIANT, EC_QUANTITY, EC_PRICE, EC_IMAGE_URL, EC_URL, EC_TOTAL, EC_VALUE, EC_SUBTOTAL_VALUE, EC_TAX, EC_SHIPPING]]; });
    return keys;
}

+ (NSSet<NSString *> *)checkoutStartedConsumedKeys {
    static NSSet *keys; static dispatch_once_t t;
    dispatch_once(&t, ^{ keys = [NSSet setWithArray:@[EC_CHECKOUT_ID, EC_ORDER_ID, EC_CART_ID, EC_TOTAL, EC_REVENUE, EC_VALUE, EC_SUBTOTAL_VALUE, EC_CURRENCY, EC_PRODUCTS, EC_TAX, EC_SHIPPING]]; });
    return keys;
}

+ (NSSet<NSString *> *)orderPlacedConsumedKeys {
    static NSSet *keys; static dispatch_once_t t;
    dispatch_once(&t, ^{ keys = [NSSet setWithArray:@[EC_ORDER_ID, EC_CART_ID, EC_TOTAL, EC_REVENUE, EC_VALUE, EC_SUBTOTAL_VALUE, EC_CURRENCY, EC_PRODUCTS, EC_TAX, EC_SHIPPING, EC_DISCOUNT, EC_TOTAL_DISCOUNTS, EC_DISCOUNTS]]; });
    return keys;
}

+ (NSSet<NSString *> *)orderRefundedConsumedKeys {
    static NSSet *keys; static dispatch_once_t t;
    dispatch_once(&t, ^{ keys = [NSSet setWithArray:@[EC_ORDER_ID, EC_TOTAL, EC_REVENUE, EC_VALUE, EC_CURRENCY, EC_PRODUCTS, EC_DISCOUNT, EC_TOTAL_DISCOUNTS, EC_DISCOUNTS]]; });
    return keys;
}

+ (NSSet<NSString *> *)orderCancelledConsumedKeys {
    static NSSet *keys; static dispatch_once_t t;
    dispatch_once(&t, ^{ keys = [NSSet setWithArray:@[EC_ORDER_ID, EC_TOTAL, EC_REVENUE, EC_VALUE, EC_SUBTOTAL_VALUE, EC_CURRENCY, EC_CANCEL_REASON, EC_REASON, EC_PRODUCTS, EC_TAX, EC_SHIPPING, EC_DISCOUNT, EC_TOTAL_DISCOUNTS, EC_DISCOUNTS]]; });
    return keys;
}

#pragma mark - Resolution

+ (NSDictionary<NSString *, RudderBrazeEcommerceEvent *> *)ecommerceEventMapping {
    static NSDictionary *mapping; static dispatch_once_t t;
    dispatch_once(&t, ^{
        // Keyed off the SDK's RSECommerceEvents names (lowercased for case-insensitive lookup).
        mapping = @{
            [ECommProductViewed lowercaseString]:   [RudderBrazeEcommerceEvent eventWithType:RudderBrazeEcommerceEventTypeProductViewed brazeEvent:BRAZE_EVENT_PRODUCT_VIEWED action:nil],
            [ECommProductAdded lowercaseString]:    [RudderBrazeEcommerceEvent eventWithType:RudderBrazeEcommerceEventTypeProductAdded brazeEvent:BRAZE_EVENT_CART_UPDATED action:ACTION_ADD],
            [ECommProductRemoved lowercaseString]:  [RudderBrazeEcommerceEvent eventWithType:RudderBrazeEcommerceEventTypeProductRemoved brazeEvent:BRAZE_EVENT_CART_UPDATED action:ACTION_REMOVE],
            [ECommCheckoutStarted lowercaseString]: [RudderBrazeEcommerceEvent eventWithType:RudderBrazeEcommerceEventTypeCheckoutStarted brazeEvent:BRAZE_EVENT_CHECKOUT_STARTED action:nil],
            [ECommOrderCompleted lowercaseString]:  [RudderBrazeEcommerceEvent eventWithType:RudderBrazeEcommerceEventTypeOrderCompleted brazeEvent:BRAZE_EVENT_ORDER_PLACED action:nil],
            [ECommOrderRefunded lowercaseString]:   [RudderBrazeEcommerceEvent eventWithType:RudderBrazeEcommerceEventTypeOrderRefunded brazeEvent:BRAZE_EVENT_ORDER_REFUNDED action:nil],
            [ECommOrderCancelled lowercaseString]:  [RudderBrazeEcommerceEvent eventWithType:RudderBrazeEcommerceEventTypeOrderCancelled brazeEvent:BRAZE_EVENT_ORDER_CANCELLED action:nil],
        };
    });
    return mapping;
}

+ (RudderBrazeEcommerceEvent *)resolveEcommerceEvent:(NSString *)eventName {
    if (![eventName isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSString *key = [[eventName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    return [self ecommerceEventMapping][key];
}

#pragma mark - Building

+ (NSDictionary<NSString *, id> *)buildEcommerceProperties:(RudderBrazeEcommerceEvent *)ecommerceEvent
                                                properties:(NSDictionary<NSString *, id> *)properties {
    NSDictionary *props = (properties != nil) ? properties : @{};
    NSMutableDictionary *out = nil;
    switch (ecommerceEvent.type) {
        case RudderBrazeEcommerceEventTypeProductViewed:
            out = (NSMutableDictionary *)[self buildProductViewed:props];
            break;
        case RudderBrazeEcommerceEventTypeProductAdded:
        case RudderBrazeEcommerceEventTypeProductRemoved:
            out = (NSMutableDictionary *)[self buildCartUpdated:props action:ecommerceEvent.action];
            break;
        case RudderBrazeEcommerceEventTypeCheckoutStarted:
            out = (NSMutableDictionary *)[self buildCheckoutStarted:props];
            break;
        case RudderBrazeEcommerceEventTypeOrderCompleted:
            out = (NSMutableDictionary *)[self buildOrderPlaced:props];
            break;
        case RudderBrazeEcommerceEventTypeOrderRefunded:
            out = (NSMutableDictionary *)[self buildOrderRefunded:props];
            break;
        case RudderBrazeEcommerceEventTypeOrderCancelled:
            out = (NSMutableDictionary *)[self buildOrderCancelled:props];
            break;
    }
    if (out == nil) {
        return [NSMutableDictionary dictionary];
    }
    // Coerce resolved values toward Braze's expected types and warn on any residual mismatch.
    coerceAndWarnTypes(ecommerceEvent.brazeEvent, out);
    return out;
}

+ (NSDictionary<NSString *, id> *)buildProductViewed:(NSDictionary *)props {
    NSString *brazeEvent = BRAZE_EVENT_PRODUCT_VIEWED;
    NSMutableDictionary *out = [NSMutableDictionary dictionary];

    id productId = firstNonNull(props, @[EC_PRODUCT_ID, EC_SKU]);
    id productName = firstNonNull(props, @[EC_NAME]);
    id variantId = firstNonNull(props, @[EC_VARIANT, EC_SKU, EC_PRODUCT_ID]);
    id price = firstNonNull(props, @[EC_PRICE]);
    id currency = firstNonNull(props, @[EC_CURRENCY]);

    warnIfMissing(brazeEvent, BRAZE_PRODUCT_ID, productId);
    warnIfMissing(brazeEvent, BRAZE_PRODUCT_NAME, productName);
    warnIfMissing(brazeEvent, BRAZE_VARIANT_ID, variantId);
    warnIfMissing(brazeEvent, BRAZE_PRICE, price);
    warnIfMissing(brazeEvent, BRAZE_CURRENCY, currency);

    putIfPresent(out, BRAZE_PRODUCT_ID, productId);
    putIfPresent(out, BRAZE_PRODUCT_NAME, productName);
    putIfPresent(out, BRAZE_VARIANT_ID, variantId);
    putIfPresent(out, BRAZE_PRICE, price);
    putIfPresent(out, BRAZE_CURRENCY, currency);
    putIfPresent(out, BRAZE_IMAGE_URL, firstNonNull(props, @[EC_IMAGE_URL]));
    putIfPresent(out, BRAZE_PRODUCT_URL, firstNonNull(props, @[EC_URL]));
    putIfPresent(out, BRAZE_TYPE, firstNonNull(props, @[EC_TYPE]));
    out[SOURCE_KEY] = SOURCE;

    putMetadata(out, props, [self productViewedConsumedKeys]);
    return out;
}

// A single top-level product is wrapped into a 1-element products array; action distinguishes
// add from remove.
+ (NSDictionary<NSString *, id> *)buildCartUpdated:(NSDictionary *)props action:(NSString *)action {
    NSString *brazeEvent = BRAZE_EVENT_CART_UPDATED;
    NSMutableDictionary *out = [NSMutableDictionary dictionary];

    id cartId = firstNonNull(props, @[EC_CART_ID]);
    id currency = firstNonNull(props, @[EC_CURRENCY]);
    NSMutableDictionary *product = [self buildProductFields:props];

    warnIfMissing(brazeEvent, BRAZE_CART_ID, cartId);
    warnIfMissing(brazeEvent, BRAZE_CURRENCY, currency);
    if (product.count == 0) {
        warnIfMissing(brazeEvent, BRAZE_PRODUCTS, nil);
    }

    putIfPresent(out, BRAZE_CART_ID, cartId);
    putIfPresent(out, BRAZE_CURRENCY, currency);
    putIfPresent(out, BRAZE_TOTAL_VALUE, firstNonNull(props, @[EC_TOTAL, EC_VALUE]));
    putIfPresent(out, BRAZE_SUBTOTAL_VALUE, firstNonNull(props, @[EC_SUBTOTAL_VALUE]));
    putIfPresent(out, BRAZE_TAX, firstNonNull(props, @[EC_TAX]));
    putIfPresent(out, BRAZE_SHIPPING, firstNonNull(props, @[EC_SHIPPING]));
    out[BRAZE_ACTION] = action;
    if (product.count > 0) {
        out[BRAZE_PRODUCTS] = @[product];
    }
    out[SOURCE_KEY] = SOURCE;

    putMetadata(out, props, [self cartUpdatedConsumedKeys]);
    return out;
}

+ (NSDictionary<NSString *, id> *)buildCheckoutStarted:(NSDictionary *)props {
    NSString *brazeEvent = BRAZE_EVENT_CHECKOUT_STARTED;
    NSMutableDictionary *out = [NSMutableDictionary dictionary];

    id checkoutId = firstNonNull(props, @[EC_CHECKOUT_ID, EC_ORDER_ID]);
    id totalValue = firstNonNull(props, @[EC_TOTAL, EC_REVENUE, EC_VALUE]);
    id currency = firstNonNull(props, @[EC_CURRENCY]);
    NSArray *products = [self buildProducts:props];

    warnIfMissing(brazeEvent, BRAZE_CHECKOUT_ID, checkoutId);
    warnIfMissing(brazeEvent, BRAZE_TOTAL_VALUE, totalValue);
    warnIfMissing(brazeEvent, BRAZE_CURRENCY, currency);
    if (products == nil) {
        warnIfMissing(brazeEvent, BRAZE_PRODUCTS, nil);
    }

    putIfPresent(out, BRAZE_CHECKOUT_ID, checkoutId);
    putIfPresent(out, BRAZE_TOTAL_VALUE, totalValue);
    putIfPresent(out, BRAZE_CURRENCY, currency);
    if (products != nil) {
        out[BRAZE_PRODUCTS] = products;
    }
    putIfPresent(out, BRAZE_CART_ID, firstNonNull(props, @[EC_CART_ID]));
    putIfPresent(out, BRAZE_SUBTOTAL_VALUE, firstNonNull(props, @[EC_SUBTOTAL_VALUE]));
    putIfPresent(out, BRAZE_TAX, firstNonNull(props, @[EC_TAX]));
    putIfPresent(out, BRAZE_SHIPPING, firstNonNull(props, @[EC_SHIPPING]));
    out[SOURCE_KEY] = SOURCE;

    putMetadata(out, props, [self checkoutStartedConsumedKeys]);
    return out;
}

+ (NSDictionary<NSString *, id> *)buildOrderPlaced:(NSDictionary *)props {
    NSString *brazeEvent = BRAZE_EVENT_ORDER_PLACED;
    NSMutableDictionary *out = [NSMutableDictionary dictionary];

    id orderId = firstNonNull(props, @[EC_ORDER_ID]);
    id totalValue = firstNonNull(props, @[EC_TOTAL, EC_REVENUE, EC_VALUE]);
    id currency = firstNonNull(props, @[EC_CURRENCY]);
    NSArray *products = [self buildProducts:props];

    warnIfMissing(brazeEvent, BRAZE_ORDER_ID, orderId);
    warnIfMissing(brazeEvent, BRAZE_TOTAL_VALUE, totalValue);
    warnIfMissing(brazeEvent, BRAZE_CURRENCY, currency);
    if (products == nil) {
        warnIfMissing(brazeEvent, BRAZE_PRODUCTS, nil);
    }

    putIfPresent(out, BRAZE_ORDER_ID, orderId);
    putIfPresent(out, BRAZE_TOTAL_VALUE, totalValue);
    putIfPresent(out, BRAZE_CURRENCY, currency);
    if (products != nil) {
        out[BRAZE_PRODUCTS] = products;
    }
    putIfPresent(out, BRAZE_CART_ID, firstNonNull(props, @[EC_CART_ID]));
    putIfPresent(out, BRAZE_TAX, firstNonNull(props, @[EC_TAX]));
    putIfPresent(out, BRAZE_SHIPPING, firstNonNull(props, @[EC_SHIPPING]));
    putIfPresent(out, BRAZE_TOTAL_DISCOUNTS, firstNonNull(props, @[EC_DISCOUNT, EC_TOTAL_DISCOUNTS]));
    putIfPresent(out, BRAZE_SUBTOTAL_VALUE, firstNonNull(props, @[EC_SUBTOTAL_VALUE]));
    putIfPresent(out, BRAZE_DISCOUNTS, firstNonNull(props, @[EC_DISCOUNTS]));
    out[SOURCE_KEY] = SOURCE;

    putMetadata(out, props, [self orderPlacedConsumedKeys]);
    return out;
}

+ (NSDictionary<NSString *, id> *)buildOrderRefunded:(NSDictionary *)props {
    NSString *brazeEvent = BRAZE_EVENT_ORDER_REFUNDED;
    NSMutableDictionary *out = [NSMutableDictionary dictionary];

    id orderId = firstNonNull(props, @[EC_ORDER_ID]);
    id totalValue = firstNonNull(props, @[EC_TOTAL, EC_REVENUE, EC_VALUE]);
    id currency = firstNonNull(props, @[EC_CURRENCY]);
    NSArray *products = [self buildProducts:props];

    warnIfMissing(brazeEvent, BRAZE_ORDER_ID, orderId);
    warnIfMissing(brazeEvent, BRAZE_TOTAL_VALUE, totalValue);
    warnIfMissing(brazeEvent, BRAZE_CURRENCY, currency);
    if (products == nil) {
        warnIfMissing(brazeEvent, BRAZE_PRODUCTS, nil);
    }

    putIfPresent(out, BRAZE_ORDER_ID, orderId);
    putIfPresent(out, BRAZE_TOTAL_VALUE, totalValue);
    putIfPresent(out, BRAZE_CURRENCY, currency);
    if (products != nil) {
        out[BRAZE_PRODUCTS] = products;
    }
    putIfPresent(out, BRAZE_TOTAL_DISCOUNTS, firstNonNull(props, @[EC_DISCOUNT, EC_TOTAL_DISCOUNTS]));
    putIfPresent(out, BRAZE_DISCOUNTS, firstNonNull(props, @[EC_DISCOUNTS]));
    out[SOURCE_KEY] = SOURCE;

    putMetadata(out, props, [self orderRefundedConsumedKeys]);
    return out;
}

+ (NSDictionary<NSString *, id> *)buildOrderCancelled:(NSDictionary *)props {
    NSString *brazeEvent = BRAZE_EVENT_ORDER_CANCELLED;
    NSMutableDictionary *out = [NSMutableDictionary dictionary];

    id orderId = firstNonNull(props, @[EC_ORDER_ID]);
    id totalValue = firstNonNull(props, @[EC_TOTAL, EC_REVENUE, EC_VALUE]);
    id currency = firstNonNull(props, @[EC_CURRENCY]);
    id cancelReason = firstNonNull(props, @[EC_CANCEL_REASON, EC_REASON]);
    NSArray *products = [self buildProducts:props];

    warnIfMissing(brazeEvent, BRAZE_ORDER_ID, orderId);
    warnIfMissing(brazeEvent, BRAZE_TOTAL_VALUE, totalValue);
    warnIfMissing(brazeEvent, BRAZE_CURRENCY, currency);
    warnIfMissing(brazeEvent, BRAZE_CANCEL_REASON, cancelReason);
    if (products == nil) {
        warnIfMissing(brazeEvent, BRAZE_PRODUCTS, nil);
    }

    putIfPresent(out, BRAZE_ORDER_ID, orderId);
    putIfPresent(out, BRAZE_TOTAL_VALUE, totalValue);
    putIfPresent(out, BRAZE_CURRENCY, currency);
    putIfPresent(out, BRAZE_CANCEL_REASON, cancelReason);
    if (products != nil) {
        out[BRAZE_PRODUCTS] = products;
    }
    putIfPresent(out, BRAZE_TAX, firstNonNull(props, @[EC_TAX]));
    putIfPresent(out, BRAZE_SHIPPING, firstNonNull(props, @[EC_SHIPPING]));
    putIfPresent(out, BRAZE_TOTAL_DISCOUNTS, firstNonNull(props, @[EC_DISCOUNT, EC_TOTAL_DISCOUNTS]));
    putIfPresent(out, BRAZE_SUBTOTAL_VALUE, firstNonNull(props, @[EC_SUBTOTAL_VALUE]));
    putIfPresent(out, BRAZE_DISCOUNTS, firstNonNull(props, @[EC_DISCOUNTS]));
    out[SOURCE_KEY] = SOURCE;

    putMetadata(out, props, [self orderCancelledConsumedKeys]);
    return out;
}

#pragma mark - Products

+ (nullable NSArray<NSDictionary *> *)buildProducts:(NSDictionary *)props {
    id raw = props[EC_PRODUCTS];
    if (![raw isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSMutableArray *products = [NSMutableArray array];
    for (id item in (NSArray *)raw) {
        if ([item isKindOfClass:[NSDictionary class]]) {
            [products addObject:[self buildProduct:(NSDictionary *)item]];
        }
    }
    return products.count > 0 ? products : nil;
}

+ (NSMutableDictionary *)buildProduct:(NSDictionary *)rsProduct {
    NSMutableDictionary *product = [self buildProductFields:rsProduct];
    putMetadata(product, rsProduct, [self productConsumedKeys]);
    return product;
}

// Maps the shared Braze product object without metadata; callers add metadata as needed.
+ (NSMutableDictionary *)buildProductFields:(NSDictionary *)rsProduct {
    NSMutableDictionary *product = [NSMutableDictionary dictionary];
    putIfPresent(product, BRAZE_PRODUCT_ID, firstNonNull(rsProduct, @[EC_PRODUCT_ID, EC_SKU]));
    putIfPresent(product, BRAZE_PRODUCT_NAME, firstNonNull(rsProduct, @[EC_NAME]));
    putIfPresent(product, BRAZE_VARIANT_ID, firstNonNull(rsProduct, @[EC_VARIANT, EC_SKU, EC_PRODUCT_ID]));
    putIfPresent(product, BRAZE_QUANTITY, firstNonNull(rsProduct, @[EC_QUANTITY]));
    putIfPresent(product, BRAZE_PRICE, firstNonNull(rsProduct, @[EC_PRICE]));
    putIfPresent(product, BRAZE_IMAGE_URL, firstNonNull(rsProduct, @[EC_IMAGE_URL]));
    putIfPresent(product, BRAZE_PRODUCT_URL, firstNonNull(rsProduct, @[EC_URL]));
    return product;
}

#pragma mark - Helpers

// Copies every key not consumed by the mapping into a nested metadata object.
static void putMetadata(NSMutableDictionary *target, NSDictionary *props, NSSet<NSString *> *consumedKeys) {
    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
    for (NSString *key in props) {
        if (![consumedKeys containsObject:key]) {
            id value = props[key];
            if (value != nil) {
                metadata[key] = value;
            }
        }
    }
    if (metadata.count > 0) {
        target[BRAZE_METADATA] = metadata;
    }
}

// First non-null, non-empty value among the given keys.
static id firstNonNull(NSDictionary *props, NSArray<NSString *> *keys) {
    if (props == nil) {
        return nil;
    }
    for (NSString *key in keys) {
        id value = props[key];
        if (value != nil && value != [NSNull null] &&
            !([value isKindOfClass:[NSString class]] && [(NSString *)value length] == 0)) {
            return value;
        }
    }
    return nil;
}

static void putIfPresent(NSMutableDictionary *target, NSString *key, id value) {
    if (value != nil && value != [NSNull null]) {
        target[key] = value;
    }
}

// Logs a missing required field without dropping the event.
static void warnIfMissing(NSString *brazeEvent, NSString *field, id value) {
    if (value == nil) {
        [RSLogger logWarn:[NSString stringWithFormat:
            @"RudderBrazeIntegration: recommended event %@ is missing required field '%@'; sending event anyway.",
            brazeEvent, field]];
    }
}

#pragma mark - Type coercion

// Each Braze field has exactly one expected type globally, so a single ordered table serves both
// top-level and products[] fields (event-only keys simply never appear inside a product). Order =
// warning order. Control fields (source/action/products/metadata) are intentionally omitted.
static NSArray<NSArray *> *fieldTypeTable(void) {
    static NSArray *table; static dispatch_once_t once;
    dispatch_once(&once, ^{
        table = @[
            @[BRAZE_PRODUCT_ID,      @(RudderBrazeFieldTypeString)],
            @[BRAZE_PRODUCT_NAME,    @(RudderBrazeFieldTypeString)],
            @[BRAZE_VARIANT_ID,      @(RudderBrazeFieldTypeString)],
            @[BRAZE_QUANTITY,        @(RudderBrazeFieldTypeInteger)],
            @[BRAZE_PRICE,           @(RudderBrazeFieldTypeFloat)],
            @[BRAZE_IMAGE_URL,       @(RudderBrazeFieldTypeString)],
            @[BRAZE_PRODUCT_URL,     @(RudderBrazeFieldTypeString)],
            @[BRAZE_CART_ID,         @(RudderBrazeFieldTypeString)],
            @[BRAZE_CHECKOUT_ID,     @(RudderBrazeFieldTypeString)],
            @[BRAZE_ORDER_ID,        @(RudderBrazeFieldTypeString)],
            @[BRAZE_CURRENCY,        @(RudderBrazeFieldTypeString)],
            @[BRAZE_TOTAL_VALUE,     @(RudderBrazeFieldTypeFloat)],
            @[BRAZE_SUBTOTAL_VALUE,  @(RudderBrazeFieldTypeFloat)],
            @[BRAZE_TAX,             @(RudderBrazeFieldTypeFloat)],
            @[BRAZE_SHIPPING,        @(RudderBrazeFieldTypeFloat)],
            @[BRAZE_TOTAL_DISCOUNTS, @(RudderBrazeFieldTypeFloat)],
            @[BRAZE_CANCEL_REASON,   @(RudderBrazeFieldTypeString)],
            @[BRAZE_TYPE,            @(RudderBrazeFieldTypeStringArray)],
            @[BRAZE_DISCOUNTS,       @(RudderBrazeFieldTypeArray)],
        ];
    });
    return table;
}

// Coerces each resolved field toward its expected type (top-level and products[]), then logs one
// warning listing any field whose value still does not match after coercion (sent as-is).
static void coerceAndWarnTypes(NSString *brazeEvent, NSMutableDictionary *out) {
    NSMutableArray<NSString *> *mismatched = [NSMutableArray array];
    NSArray<NSArray *> *table = fieldTypeTable();

    for (NSArray *entry in table) {
        NSString *field = entry[0];
        RudderBrazeFieldType type = (RudderBrazeFieldType)[entry[1] integerValue];
        id value = out[field];
        if (value != nil) {
            id coerced = coerceValue(value, type);
            out[field] = coerced;
            if (!valueMatchesType(coerced, type)) {
                [mismatched addObject:[NSString stringWithFormat:@"%@ (expected %@)", field, fieldTypeName(type)]];
            }
        }
    }

    id productsObj = out[BRAZE_PRODUCTS];
    if ([productsObj isKindOfClass:[NSArray class]]) {
        NSArray *products = (NSArray *)productsObj;
        for (NSArray *entry in table) {
            NSString *field = entry[0];
            RudderBrazeFieldType type = (RudderBrazeFieldType)[entry[1] integerValue];
            BOOL anyMismatch = NO;
            for (id item in products) {
                if ([item isKindOfClass:[NSMutableDictionary class]]) {
                    NSMutableDictionary *product = (NSMutableDictionary *)item;
                    id value = product[field];
                    if (value != nil) {
                        id coerced = coerceValue(value, type);
                        product[field] = coerced;
                        if (!valueMatchesType(coerced, type)) {
                            anyMismatch = YES;
                        }
                    }
                }
            }
            if (anyMismatch) {
                [mismatched addObject:[NSString stringWithFormat:@"products[].%@ (expected %@)", field, fieldTypeName(type)]];
            }
        }
    }

    if (mismatched.count > 0) {
        [RSLogger logWarn:[NSString stringWithFormat:
            @"RudderBrazeIntegration: recommended event %@ has type-mismatched field(s) (sent as-is): [%@]",
            brazeEvent, [mismatched componentsJoinedByString:@", "]]];
    }
}

// numeric string -> number (FLOAT/INTEGER), number/boolean -> string (STRING). Numbers are left as-is
// for numeric fields (Braze accepts an integer where a float is expected); arrays/objects are never
// coerced. Anything that cannot be coerced is returned unchanged.
static id coerceValue(id value, RudderBrazeFieldType type) {
    switch (type) {
        case RudderBrazeFieldTypeString:
            if ([value isKindOfClass:[NSNumber class]]) {
                return numberToBrazeString((NSNumber *)value);
            }
            return value;
        case RudderBrazeFieldTypeFloat:
            if ([value isKindOfClass:[NSString class]]) {
                NSNumber *parsed = parseDoubleOrNil((NSString *)value);
                return parsed != nil ? parsed : value;
            }
            return value;
        case RudderBrazeFieldTypeInteger:
            if ([value isKindOfClass:[NSString class]]) {
                NSNumber *parsed = parseLongOrNil((NSString *)value);
                return parsed != nil ? parsed : value;
            }
            return value;
        case RudderBrazeFieldTypeStringArray:
        case RudderBrazeFieldTypeArray:
        default:
            return value;
    }
}

// 0 / false are valid; a numeric written as a string (e.g. "29.99") does not match a numeric type.
static BOOL valueMatchesType(id value, RudderBrazeFieldType type) {
    switch (type) {
        case RudderBrazeFieldTypeString:
            return [value isKindOfClass:[NSString class]];
        case RudderBrazeFieldTypeInteger:
            return [value isKindOfClass:[NSNumber class]] && !isBooleanNumber((NSNumber *)value)
                && isIntegralNumber((NSNumber *)value);
        case RudderBrazeFieldTypeFloat:
            return [value isKindOfClass:[NSNumber class]] && !isBooleanNumber((NSNumber *)value);
        case RudderBrazeFieldTypeStringArray:
            return isStringArray(value);
        case RudderBrazeFieldTypeArray:
            return [value isKindOfClass:[NSArray class]];
        default:
            return YES;
    }
}

static BOOL isIntegralNumber(NSNumber *number) {
    const char *t = [number objCType];
    if (strcmp(t, @encode(double)) == 0 || strcmp(t, @encode(float)) == 0) {
        double d = [number doubleValue];
        return isfinite(d) && d == floor(d);
    }
    return YES;
}

static BOOL isStringArray(id value) {
    if (![value isKindOfClass:[NSArray class]]) {
        return NO;
    }
    for (id item in (NSArray *)value) {
        if (![item isKindOfClass:[NSString class]]) {
            return NO;
        }
    }
    return YES;
}

static BOOL isBooleanNumber(NSNumber *number) {
    return CFGetTypeID((__bridge CFTypeRef)number) == CFBooleanGetTypeID();
}

static NSString *numberToBrazeString(NSNumber *number) {
    if (isBooleanNumber(number)) {
        return [number boolValue] ? @"true" : @"false";
    }
    return [number stringValue];
}

static NSString *fieldTypeName(RudderBrazeFieldType type) {
    switch (type) {
        case RudderBrazeFieldTypeString:      return @"STRING";
        case RudderBrazeFieldTypeInteger:     return @"INTEGER";
        case RudderBrazeFieldTypeFloat:       return @"FLOAT";
        case RudderBrazeFieldTypeStringArray: return @"STRING_ARRAY";
        case RudderBrazeFieldTypeArray:       return @"ARRAY";
    }
    return @"";
}

// Parses a fully-numeric string to a double, or nil if it is not a valid number (then sent as-is).
static NSNumber *parseDoubleOrNil(NSString *string) {
    NSString *trimmed = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (trimmed.length == 0) {
        return nil;
    }
    const char *c = [trimmed UTF8String];
    char *end = NULL;
    double d = strtod(c, &end);
    if (end == c || *end != '\0') {
        return nil;
    }
    return @(d);
}

// Parses a fully-integral string to a long, or nil otherwise (e.g. "2.5" and "free" both fail).
static NSNumber *parseLongOrNil(NSString *string) {
    NSString *trimmed = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (trimmed.length == 0) {
        return nil;
    }
    const char *c = [trimmed UTF8String];
    char *end = NULL;
    long long v = strtoll(c, &end, 10);
    if (end == c || *end != '\0') {
        return nil;
    }
    return @(v);
}

@end
