//
//  STPEphemeralKeyProvider.h
//  Stripe
//
//  Created by Ben Guo on 5/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPBlocks.h"

NS_ASSUME_NONNULL_BEGIN

@class STPEphemeralKey;

/**
 You should make your application's API client conform to this interface.
 It provides a way for Stripe utility classes to request a new ephemeral key from
 your backend, which it will use to retrieve and update Stripe API objects.
 */
@protocol STPCustomerEphemeralKeyProvider <NSObject>
/**
 Creates a new ephemeral key for retrieving and updating a Stripe customer.
 On your backend, you should create a new ephemeral key for the Stripe customer
 associated with your user, and return the raw JSON response from the Stripe API.
 For an example Ruby implementation of this API, refer to our example backend:
 https://github.com/stripe/example-ios-backend/blob/v18.1.0/web.rb
 
 Back in your iOS app, once you have a response from this API, call the provided
 completion block with the JSON response, or an error if one occurred.
 
 @param apiVersion  The Stripe API version to use when creating a key.
 You should pass this parameter to your backend, and use it to set the API version
 in your key creation request. Passing this version parameter ensures that the
 Stripe SDK can always parse the ephemeral key response from your server.
 @param completion  Call this callback when you're done fetching a new ephemeral
 key from your backend. For example, `completion(json, nil)` (if your call succeeds)
 or `completion(nil, error)` if an error is returned.
 */
- (void)createCustomerKeyWithAPIVersion:(NSString *)apiVersion completion:(STPJSONResponseCompletionBlock)completion;
@end

/**
 You should make your application's API client conform to this interface.
 It provides a way for Stripe utility classes to request a new ephemeral key from
 your backend, which it will use to retrieve and update Stripe API objects.
 */
@protocol STPIssuingCardEphemeralKeyProvider <NSObject>
/**
 Creates a new ephemeral key for retrieving and updating a Stripe Issuing Card.
 On your backend, you should create a new ephemeral key for your logged-in user's
 primary Issuing Card, and return the raw JSON response from the Stripe API.
 For an example Ruby implementation of this API, refer to our example backend:
 https://github.com/stripe/example-ios-backend/blob/v18.1.0/web.rb
 
 Back in your iOS app, once you have a response from this API, call the provided
 completion block with the JSON response, or an error if one occurred.
 
 @param apiVersion  The Stripe API version to use when creating a key.
 You should pass this parameter to your backend, and use it to set the API version
 in your key creation request. Passing this version parameter ensures that the
 Stripe SDK can always parse the ephemeral key response from your server.
 @param completion  Call this callback when you're done fetching a new ephemeral
 key from your backend. For example, `completion(json, nil)` (if your call succeeds)
 or `completion(nil, error)` if an error is returned.
 */
- (void)createIssuingCardKeyWithAPIVersion:(NSString *)apiVersion completion:(STPJSONResponseCompletionBlock)completion;
@end

/**
 You should make your application's API client conform to this interface.
 It provides a way for Stripe utility classes to request a new ephemeral key from
 your backend, which it will use to retrieve and update Stripe API objects.
 @deprecated use `STPCustomerEphemeralKeyProvider` or `STPIssuingCardEphemeralKeyProvider`
depending on the type of key that will be fetched.
 */
__attribute__ ((deprecated("STPEphemeralKeyProvider has been renamed to STPCustomerEphemeralKeyProvider", "STPCustomerEphemeralKeyProvider")))
@protocol STPEphemeralKeyProvider <STPCustomerEphemeralKeyProvider>
@end

NS_ASSUME_NONNULL_END
