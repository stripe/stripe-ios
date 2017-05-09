//
//  STPBackendAPIAdapter.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "STPAddress.h"
#import "STPBlocks.h"
#import "STPCustomer.h"
#import "STPSourceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class STPCard, STPToken;

/**
 *  You should make your application's API client conform to this interface in order to use it with an `STPPaymentContext`. It provides a "bridge" from the prebuilt UI we expose (such as `STPPaymentMethodsViewController`) to your backend to fetch the information it needs to power those views. To read about how to implement this protocol, see https://stripe.com/docs/mobile/ios/standard#prepare-your-api . To see examples of implementing these APIs, see MyAPIClient.swift in our example project and https://github.com/stripe/example-ios-backend .
 *
 *  @deprecated Use `STPCustomerContext`.
 *  Instead of providing your own backend API adapter, you can now create an
 *  `STPCustomerContext`, which will manage retrieving and updating a
 *  Stripe customer for you. @see STPCustomerContext.h
 */
__attribute__((deprecated))
@protocol STPBackendAPIAdapter<NSObject>

/**
 *  Retrieve the cards to be displayed inside a payment context. On your backend, retrieve the Stripe customer associated with your currently logged-in user (see https://stripe.com/docs/api#retrieve_customer ), and return the raw JSON response from the Stripe API. (For an example Ruby implementation of this API, see https://github.com/stripe/example-ios-backend/blob/master/web.rb#L40 ). Back in your iOS app, after you've called this API, deserialize your API response into an `STPCustomer` object (you can use the `STPCustomerDeserializer` class to do this). See MyAPIClient.swift in our example project to see this in action.
 *
 *  @see STPCard
 *  @param completion call this callback when you're done fetching and parsing the above information from your backend. For example, `completion(customer, nil)` (if your call succeeds) or `completion(nil, error)` if an error is returned.
 */
- (void)retrieveCustomer:(nullable STPCustomerCompletionBlock)completion;

/**
 *  Adds a payment source to a customer. On your backend, retrieve the Stripe customer associated with your logged-in user. Then, call the Update Customer method on that customer as described at https://stripe.com/docs/api#update_customer (for an example Ruby implementation of this API, see https://github.com/stripe/example-ios-backend/blob/master/web.rb#L60 ). If this API call succeeds, call `completion(nil)`. Otherwise, call `completion(error)` with the error that occurred.
 *
 *  @param source     a valid payment source, such as a card token.
 *  @param completion call this callback when you're done adding the token to the customer on your backend. For example, `completion(nil)` (if your call succeeds) or `completion(error)` if an error is returned.
 */
- (void)attachSourceToCustomer:(id<STPSourceProtocol>)source completion:(STPErrorBlock)completion;

/**
 *  Change a customer's `default_source` to be the provided card. On your backend, retrieve the Stripe customer associated with your logged-in user. Then, call the Customer Update method as described at https://stripe.com/docs/api#update_customer , specifying default_source to be the value of source.stripeID (for an example Ruby implementation of this API, see https://github.com/stripe/example-ios-backend/blob/master/web.rb#L82 ). If this API call succeeds, call `completion(nil)`. Otherwise, call `completion(error)` with the error that occurred.
 *
 *  @param source     The newly-selected default source for the user.
 *  @param completion call this callback when you're done selecting the new default source for the customer on your backend. For example, `completion(nil)` (if your call succeeds) or `completion(error)` if an error is returned.
 */
- (void)selectDefaultCustomerSource:(id<STPSourceProtocol>)source completion:(STPErrorBlock)completion;

@end

NS_ASSUME_NONNULL_END
