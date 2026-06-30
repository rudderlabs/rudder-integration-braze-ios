//
//  RudderBrazeEcommerceUtils.h
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Descriptor for a Braze recommended ecommerce event. action is set only for cart_updated.
@interface RudderBrazeEcommerceEvent : NSObject

@property (nonatomic, copy, readonly) NSString *brazeEvent;
@property (nonatomic, copy, readonly, nullable) NSString *action;

@end

@interface RudderBrazeEcommerceUtils : NSObject

// Resolves a RudderStack event name to its Braze recommended event, or nil if there is none.
+ (nullable RudderBrazeEcommerceEvent *)resolveEcommerceEvent:(nullable NSString *)eventName;

+ (NSDictionary<NSString *, id> *)buildEcommerceProperties:(RudderBrazeEcommerceEvent *)ecommerceEvent
                                                properties:(nullable NSDictionary<NSString *, id> *)properties;

@end

NS_ASSUME_NONNULL_END
