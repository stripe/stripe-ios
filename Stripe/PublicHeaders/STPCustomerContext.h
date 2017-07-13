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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
/**
 An `STPCustomerContext` retrieves and updates a Stripe customer using
 an ephemeral key, a short-lived API key scoped to a specific customer object.
 If your current user logs out of your app and a new user logs in, be sure to
 either create a new instance of `STPCustomerContext` or clear the current
 instance's cached customer. On your backend, be sure to create and return a
 new ephemeral key for the Customer object associated with the new user.
 */
@interface STPCustomerContext : NSObject <STPBackendAPIAdapter>
#pragma clang diagnostic pop

/**
 Initializes a new `STPCustomerContext` with the specified key provider.
 Upon initialization, a CustomerContext will fetch a new ephemeral key from
 your backend and use it to prefetch the customer object specified in the key.
 Subsequent customer retrievals (e.g. by `STPPaymentContext`) will return the
 prefetched customer immediately if its age does not exceed `cachedCustomerMaxAge`.

 @param keyProvider   The key provider the customer context will use.
 @return the newly-instantiated customer context.
 */
- (instancetype)initWithKeyProvider:(id<STPEphemeralKeyProvider>)keyProvider;

/**
 `STPCustomerContext` will cache its customer object for up to 60 seconds.
 If your current user logs out of your app and a new user logs in, be sure
 to either call this method or create a new instance of `STPCustomerContext`.
 On your backend, be sure to create and return a new ephemeral key for the
 customer object associated with the new user.
 */
- (void)clearCachedCustomer;

@end

NS_ASSUME_NONNULL_END
