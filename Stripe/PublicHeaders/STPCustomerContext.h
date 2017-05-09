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

@protocol STPResourceKeyProvider;
@class STPResourceKey;

/**
 An `STPCustomerContext` retrieves and updates a Stripe customer using
 a resource key, a short-lived API key with a specific set of permissions.
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
@interface STPCustomerContext : NSObject <STPBackendAPIAdapter>
#pragma clang diagnostic pop

/**
 When the customer context retrieves a customer, it will return a cached
 value if it was retrieved less than this number of seconds ago.
 The default value is 60 seconds.
 */
@property (nonatomic, assign) NSTimeInterval cachedCustomerMaxAge;

/**
 Initializes a new `STPCustomerContext` with the specified customer and key provider.
 Upon initialization, a customer context will prefetch the specified customer.
 Subsequent customer retrievals (e.g. by `STPPaymentContext`) will return the
 prefetched customer immediately if its age does not exceed `cachedCustomerMaxAge`.

 @param customerId    The id of the Stripe customer the customer context will retrieve and modify.
 @param keyProvider   The key provider the customer context will use.
 @return the newly-instantiated customer context.
 */
- (instancetype)initWithCustomerId:(NSString *)customerId
                       keyProvider:(id<STPResourceKeyProvider>)keyProvider;

@end

NS_ASSUME_NONNULL_END
