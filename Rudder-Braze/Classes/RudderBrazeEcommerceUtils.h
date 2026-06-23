//
//  RudderBrazeEcommerceUtils.h
//
//  Stateless mapping logic for Braze recommended ecommerce events (gated by
//  useRecommendedEcommerceEvents). Mirrors the Android/Kotlin device-mode implementation; the
//  actual braze logCustomEvent:withProperties: call stays in RudderBrazeIntegration.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Descriptor for a Braze recommended ecommerce event. action is non-nil only for cart_updated
// (Product Added -> add, Product Removed -> remove).
@interface RudderBrazeEcommerceEvent : NSObject

@property (nonatomic, copy, readonly) NSString *brazeEvent;
@property (nonatomic, copy, readonly, nullable) NSString *action;

@end

@interface RudderBrazeEcommerceUtils : NSObject

// Resolves a RudderStack event name to its Braze recommended event (case-insensitive).
// Returns nil for events without a recommended-event counterpart.
+ (nullable RudderBrazeEcommerceEvent *)resolveEcommerceEvent:(nullable NSString *)eventName;

// Builds the Braze custom-event property dictionary for a recommended ecommerce event.
// Send-anyway posture (D5): builds from an empty map when properties are absent so the event is
// still logged (with required-field warnings) rather than dropped.
+ (NSDictionary<NSString *, id> *)buildEcommerceProperties:(RudderBrazeEcommerceEvent *)ecommerceEvent
                                                properties:(nullable NSDictionary<NSString *, id> *)properties;

@end

NS_ASSUME_NONNULL_END
