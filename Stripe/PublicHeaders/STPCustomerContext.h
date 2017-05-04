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

@class STPResourceKey;

/**
 Call this block after you're done creating a new resource key on your server.
 You can use `STPResourceKey`'s `decodedObjectFromAPIResponse` method to convert
 a JSON response into an `STPResourceKey` object.

 @param resourceKey   a deserialized `STPResourceKey` object obtained from your
 backend API, or nil if an error occurred.
 @param error         any error that occurred while communicating with your server,
 or nil if the call succeeded.
 */
typedef void (^STPResourceKeyCompletionBlock)(STPResourceKey * __nullable resourceKey, NSError * __nullable error);

/**
 You should make your application's API client conform to this interface in order
 to use it with an `STPCustomerContext`. It provides a way for an `STPCustomerContext`
 to request a new resource key from your backend, which it will use to retrieve
 and update a Stripe customer.
 */
@protocol STPResourceKeyProvider <NSObject>

/**
 Retrieve a new Stripe resource key. On your backend, create a new resource key,
 and return the raw JSON response from the Stripe API. For an example Ruby 
 implementation of this API, see: {// TODO}
 Back in your iOS app, after you've called this API, deserialize your API response
 into an `STPResourceKey` object using `decodedObjectFromAPIResponse`.
 See MyAPIClient.swift in our example project to see this in action.

 @param completion call this callback when you're done fetching a new resource 
 key from your backend. For example, `completion(key, nil)` (if your call succeeds) or `completion(nil, error)` if an error is returned.
 */
- (void)retrieveKey:(STPResourceKeyCompletionBlock)completion;

@end

/**
 An `STPCustomerContext` retrieves and updates a Stripe customer using 
 a resource key, a short-lived API key with a specific set of permissions.
 */
@interface STPCustomerContext : NSObject <STPBackendAPIAdapter>


/**
 Initializes a new `STPCustomerContext` with the specified customer and key provider.

 @param customerId    The id of the Stripe customer the customer context will retrieve and modify.
 @param keyProvider   The key provider the customer context will user to retrieve a new resource key.
 @return the newly-instantiated customer context.
 */
- (instancetype)initWithCustomerId:(NSString *)customerId
                       keyProvider:(id<STPResourceKeyProvider>)keyProvider;

@end

NS_ASSUME_NONNULL_END
