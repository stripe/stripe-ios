//
//  STPCustomerContext.h
//  Stripe
//
//  Created by Ben Guo on 5/2/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPBackendAPIAdapter.h"

NS_ASSUME_NONNULL_BEGIN

@protocol STPEphemeralKeyProvider;
@class STPEphemeralKey, STPEphemeralKeyManager;

/**
 An `STPCustomerContext` retrieves and updates a Stripe customer using
 an ephemeral key, a short-lived API key scoped to a specific Customer object.
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
@interface STPCustomerContext : NSObject <STPBackendAPIAdapter>
#pragma clang diagnostic pop

/**
 This is a convenience singleton CustomerContext. Before using the singleton
 instance, you'll need to give it a key provider using `setKeyProvider`.
 */
+ (instancetype)sharedInstance;

/**
 Whenever the customer context retrieves a customer, it will return a cached
 value if it was retrieved less than this number of seconds ago.
 The default value is 60 seconds.
 */
@property (nonatomic, assign) NSTimeInterval cachedCustomerMaxAge;

/**
 Initializes a new `STPCustomerContext` with the specified key provider.
 Upon initialization, a CustomerContext will fetch a new ephemeral key from
 your backend and use it to prefetch the Customer object specified in the key.
 Subsequent customer retrievals (e.g. by `STPPaymentContext`) will return the
 prefetched customer immediately if its age does not exceed `cachedCustomerMaxAge`.

 @param keyProvider   The key provider the customer context will use.
 @return the newly-instantiated customer context.
 */
- (instancetype)initWithKeyProvider:(id<STPEphemeralKeyProvider>)keyProvider;

/**
 Sets the CustomerContext's key provider. If you're using the singleton
 CustomerContext instance, be sure to set its keyProvider using this method.
 Upon setting a keyProvider, the customer context will request a new ephemeral key
 from your backend, and use this key to prefetch the Customer specified in
 the key. Subsequent customer retrievals (e.g. by `STPPaymentContext` or
 `STPPaymentMethodsViewController) will return the prefetched customer immediately
 if its age does not exceed `cachedCustomerMaxAge`.

 @param keyProvider  The key provider the customer context will use.
 */
- (void)setKeyProvider:(id<STPEphemeralKeyProvider>)keyProvider;

@end

NS_ASSUME_NONNULL_END
