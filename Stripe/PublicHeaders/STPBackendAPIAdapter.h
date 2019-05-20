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
 Typically, you will not need to implement this protocol yourself. You
 should instead use `STPCustomerContext`, which implements <STPBackendAPIAdapter>
 and manages retrieving and updating a Stripe customer for you.
 @see STPCustomerContext.h

 If you would prefer retrieving and updating your Stripe customer object via
 your own backend instead of using `STPCustomerContext`, you should make your 
 application's API client conform to this interface. It provides a "bridge" from 
 the prebuilt UI we expose (such as `STPPaymentOptionsViewController`) to your
 backend to fetch the information it needs to power those views.
 */
@protocol STPBackendAPIAdapter<NSObject>

/**
 Retrieve the customer to be displayed inside a payment context.
 
 If you are not using STPCustomerContext:
 On your backend, retrieve the Stripe customer associated with your currently 
 logged-in user ( https://stripe.com/docs/api#retrieve_customer ), and return
 the raw JSON response from the Stripe API. Back in your iOS app, after you've 
 called this API, deserialize your API response into an `STPCustomer` object
 (you can use the `STPCustomerDeserializer` class to do this).

 @see STPCard
 @param completion call this callback when you're done fetching and parsing the above information from your backend. For example, `completion(customer, nil)` (if your call succeeds) or `completion(nil, error)` if an error is returned.
 */
- (void)retrieveCustomer:(nullable STPCustomerCompletionBlock)completion;

/**
 Retrieves a list of Payment Methods attached to a customer.
 
 If you are implementing your own <STPBackendAPIAdapter>:
 Call the list method ( https://stripe.com/docs/api/payment_methods/lists )
 with the Stripe customer. If this API call succeeds, call `completion(paymentMethods)`
 with the list of PaymentMethods. Otherwise, call `completion(error)` with the error
 that occurred.
 
 @param completion  Call this callback with the list of Payment Methods attached to the
 customer.  For example, `completion(paymentMethods)` (if your call succeeds) or
 `completion(error)` if an error is returned.
 
 */
- (void)listPaymentMethodsForCustomerWithCompletion:(nullable STPPaymentMethodsCompletionBlock)completion;

/**
 Adds a Payment Method to a customer.
 
 If you are implementing your own <STPBackendAPIAdapter>:
 On your backend, retrieve the Stripe customer associated with your logged-in user.
 Then, call the Attach method on the Payment Method with that customer's ID
 ( https://stripe.com/docs/api/payment_methods/attach ). If this API call succeeds,
 call `completion(nil)`. Otherwise, call `completion(error)` with the error that
 occurred.
 
 @param paymentMethod   A valid Payment Method
 @param completion      Call this callback when you're done adding the payment method
 to the customer on your backend. For example, `completion(nil)` (if your call succeeds)
 or `completion(error)` if an error is returned.
 */
- (void)attachPaymentMethodToCustomer:(STPPaymentMethod *)paymentMethod completion:(nullable STPErrorBlock)completion;

@optional

/**
 Deletes the given Payment Method from the customer.
 
 If you are implementing your own <STPBackendAPIAdapter>:
 Call the Detach method ( https://stripe.com/docs/api/payment_methods/detach )
 on the Payment Method. If this API call succeeds, call `completion(nil)`.
 Otherwise, call `completion(error)` with the error that occurred.
 
 @param paymentMethod   The Payment Method to delete from the customer
 @param completion      Call this callback when you're done deleting the Payment Method
 from the customer on your backend. For example, `completion(nil)` (if your call
 succeeds) or `completion(error)` if an error is returned.
 */
- (void)detachPaymentMethodFromCustomer:(STPPaymentMethod *)paymentMethod completion:(nullable STPErrorBlock)completion;

/**
 Sets the given shipping address on the customer.
 
 If you are implementing your own <STPBackendAPIAdapter>:
 On your backend, retrieve the Stripe customer associated with your logged-in user.
 Then, call the Customer Update method ( https://stripe.com/docs/api#update_customer )
 specifying shipping to be the given shipping address. If this API call succeeds, 
 call `completion(nil)`. Otherwise, call `completion(error)` with the error that occurred.

 @param shipping   The shipping address to set on the customer
 @param completion call this callback when you're done updating the customer on
 your backend. For example, `completion(nil)` (if your call succeeds) or
 `completion(error)` if an error is returned.

 @see https://stripe.com/docs/api#update_customer
 */
- (void)updateCustomerWithShippingAddress:(STPAddress *)shipping completion:(nullable STPErrorBlock)completion;

@end

NS_ASSUME_NONNULL_END
