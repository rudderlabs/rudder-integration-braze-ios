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

// RudderStack ecommerce source keys.
static NSString *const EC_PRODUCT_ID = @"product_id";
static NSString *const EC_QUANTITY = @"quantity";
static NSString *const EC_PRICE = @"price";
static NSString *const EC_CURRENCY = @"currency";
static NSString *const EC_PRODUCTS = @"products";
static NSString *const EC_CART_ID = @"cart_id";
static NSString *const EC_CHECKOUT_ID = @"checkout_id";
static NSString *const EC_ORDER_ID = @"order_id";
static NSString *const EC_TOTAL = @"total";
static NSString *const EC_REVENUE = @"revenue";
static NSString *const EC_DISCOUNT = @"discount";
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
static NSString *const EC_REASON = @"reason";

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
        mapping = @{
            @"product viewed":    [RudderBrazeEcommerceEvent eventWithType:RudderBrazeEcommerceEventTypeProductViewed brazeEvent:BRAZE_EVENT_PRODUCT_VIEWED action:nil],
            @"product added":     [RudderBrazeEcommerceEvent eventWithType:RudderBrazeEcommerceEventTypeProductAdded brazeEvent:BRAZE_EVENT_CART_UPDATED action:ACTION_ADD],
            @"product removed":   [RudderBrazeEcommerceEvent eventWithType:RudderBrazeEcommerceEventTypeProductRemoved brazeEvent:BRAZE_EVENT_CART_UPDATED action:ACTION_REMOVE],
            @"checkout started":  [RudderBrazeEcommerceEvent eventWithType:RudderBrazeEcommerceEventTypeCheckoutStarted brazeEvent:BRAZE_EVENT_CHECKOUT_STARTED action:nil],
            @"order completed":   [RudderBrazeEcommerceEvent eventWithType:RudderBrazeEcommerceEventTypeOrderCompleted brazeEvent:BRAZE_EVENT_ORDER_PLACED action:nil],
            @"order refunded":    [RudderBrazeEcommerceEvent eventWithType:RudderBrazeEcommerceEventTypeOrderRefunded brazeEvent:BRAZE_EVENT_ORDER_REFUNDED action:nil],
            @"order cancelled":   [RudderBrazeEcommerceEvent eventWithType:RudderBrazeEcommerceEventTypeOrderCancelled brazeEvent:BRAZE_EVENT_ORDER_CANCELLED action:nil],
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
    switch (ecommerceEvent.type) {
        case RudderBrazeEcommerceEventTypeProductViewed:
            return [self buildProductViewed:props];
        case RudderBrazeEcommerceEventTypeProductAdded:
        case RudderBrazeEcommerceEventTypeProductRemoved:
            return [self buildCartUpdated:props action:ecommerceEvent.action];
        case RudderBrazeEcommerceEventTypeCheckoutStarted:
            return [self buildCheckoutStarted:props];
        case RudderBrazeEcommerceEventTypeOrderCompleted:
            return [self buildOrderPlaced:props];
        case RudderBrazeEcommerceEventTypeOrderRefunded:
            return [self buildOrderRefunded:props];
        case RudderBrazeEcommerceEventTypeOrderCancelled:
            return [self buildOrderCancelled:props];
    }
    return [NSMutableDictionary dictionary];
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

@end
