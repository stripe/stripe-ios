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
#import "STPSource.h"

NS_ASSUME_NONNULL_BEGIN

@class STPCard, STPToken;

/**
 *  Call this block after you're done fetching a customer on your server, returning their cards and selected card to your iOS application, and parsing them into STPCard objects. For more information, see the `retrieveSources` documentation.
 *
 *  @param selectedCard the user's currently selected card
 *  @param cards        the user's list of available cards
 *  @param error        any error that occurred while communicating with your server
 */
typedef void (^STPCardCompletionBlock)(STPCard * __nullable selectedCard, NSArray<STPCard *>* __nullable cards, NSError * __nullable error);

typedef void (^STPAddressCompletionBlock)(STPAddress * __nullable address, NSError * __nullable error);

/**
 *  You should make your application's API client conform to this interface in order to use it with an STPPaymentContext. It provides a "bridge" from the prebuilt UI we expose (such as STPPaymentMethodsViewController) to your backend to fetch the information it needs to power those views. To see examples of implementing these APIs, see MyAPIClient.swift in our example project and https://github.com/stripe/example-ios-backend .
 */
@protocol STPBackendAPIAdapter<NSObject>

/**
 *  Retrieve the cards to be displayed inside a payment context. On your backend, retrieve the Stripe customer associated with your currently logged-in user (see https://stripe.com/docs/api#retrieve_customer ), and return all of their `sources` where `object` == `card`. Also specifically return the user's currently selected card. (For an example Ruby implementation of this API, see https://github.com/stripe/example-ios-backend/blob/master/web.rb#L40 ). Back in your iOS app, after you've called this API, create an STPCard object for the user's selected card (see [STPCard cardWithID:brand:last4:expMonth:expYear:funding]) and the array of their cards, and call `completion` with this information. See MyAPIClient.swift in our example project to see this in action.
 *
 *  @see STPCard
 *  @param completion call this callback when you're done fetching and parsing the above information from your backend. For example, completion(selectedCard, cards, nil) (if your call succeeds) or completion(nil, nil, error) if an error is returned.
 */
- (void)retrieveCustomerCards:(STPCardCompletionBlock)completion;

/**
 *  Adds a payment source to a customer. On your backend, retrieve the Stripe customer associated with your logged-in user. Then, call the Update Customer method on that customer as described at https://stripe.com/docs/api#update_customer (for an example Ruby implementation of this API, see https://github.com/stripe/example-ios-backend/blob/master/web.rb#L60 ). If this API call succeeds, call completion(nil). Otherwise, call completion(error) with the error that occurred.
 *
 *  @param source     a valid payment source, such as a card token.
 *  @param completion call this callback when you're done adding the token to the customer on your backend. For example, completion(nil) (if your call succeeds) or completion(error) if an error is returned.
 */
- (void)attachSourceToCustomer:(id<STPSource>)source completion:(STPErrorBlock)completion;

/**
 *  Change a customer's default_source to be the provided card. On your backend, retrieve the Stripe customer associated with your logged-in user. Then, call the Customer Update method as described at https://stripe.com/docs/api#update_customer , specifying default_source to be the value of source.stripeID (for an example Ruby implementation of this API, see https://github.com/stripe/example-ios-backend/blob/master/web.rb#L82 ). If this API call succeeds, call completion(nil). Otherwise, call completion(error) with the error that occurred.
 *
 *  @param card       The newly-selected default source for the user.
 *  @param completion call this callback when you're done selecting the new default source for the customer on your backend. For example, completion(nil) (if your call succeeds) or completion(error) if an error is returned.
 */
- (void)selectDefaultCustomerSource:(id<STPSource>)source completion:(STPErrorBlock)completion;

/**
 *  Delete a card from a customer's list of sources. On your backend, retrieve the Stripe customer associated with your logged-in user. Then, call the Delete Card method as described at https://stripe.com/docs/api#delete_card on your customer (for an example Ruby implementation of this API, see https://github.com/stripe/example-ios-backend/blob/master/web.rb#L99 ). If this API call succeeds, call completion(nil). Otherwise, call completion(error) with the error that occurred.
 *
 *  @param card       The card to delete from the customer
 *  @param completion call this callback when you're done deleting the card from the customer on your backend. For example, completion(nil) (if your call succeeds) or completion(error) if an error is returned.
 */
- (void)deleteCard:(STPCard *)card completion:(STPErrorBlock)completion;

@end

NS_ASSUME_NONNULL_END
