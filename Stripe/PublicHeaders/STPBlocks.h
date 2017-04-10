//
//  STPBlocks.h
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>

@class STPToken, STPSource;

/**
 *  These values control the labels used in the shipping info collection form.
 */
typedef NS_ENUM(NSUInteger, STPShippingType) {
    /**
     *  Shipping the purchase to the provided address using a third-party
     *  shipping company.
     */
    STPShippingTypeShipping,
    /**
     *  Delivering the purchase by the seller.
     */
    STPShippingTypeDelivery,
};

/**
 *  An enum representing the status of a shipping address validation.
 */
typedef NS_ENUM(NSUInteger, STPShippingStatus) {
    /**
     *  The shipping address is valid.
     */
    STPShippingStatusValid,
    /**
     *  The shipping address is invalid.
     */
    STPShippingStatusInvalid,
};

/**
 *  An enum representing the status of a payment requested from the customer.
 */
typedef NS_ENUM(NSUInteger, STPPaymentStatus) {
    /**
     *  The payment succeeded or the user authorized the payment.
     *  Note that for payment methods that require additional customer action,
     *  (e.g., redirecting to authorize the payment with their bank), a `Success`
     *  means the payment has been authorized, but does not necessarily mean the
     *  customer has been charged. If you are using one of these payment methods,
     *  your backend should listen to the `source.chargeable` webhook to complete
     *  the charge.
     *  @see https://stripe.com/docs/sources#best-practices
     */
    STPPaymentStatusSuccess,
    /**
     *  The payment failed due to an unforeseen error, such as the user's
     *  Internet connection being offline.
     */
    STPPaymentStatusError,
    /**
     *  The user cancelled the payment (for example, by hitting "cancel"
     *  in the Apple Pay dialog).
     */
    STPPaymentStatusUserCancellation,
    /**
     *  The status of the payment cannot be determined at this time.
     *  In general, this means your customer chose to complete their payment using
     *  a method that requires additional action (e.g., they were redirected to
     *  authorize the payment with their bank), and the SDK was unable to determine
     *  the status of the action. In this case, you can simply inform your
     *  customer that their order was received.
     */
    STPPaymentStatusPending,
};

/**
 *  An empty block, called with no arguments, returning nothing.
 */
typedef void (^STPVoidBlock)();

/**
 *  A block that may optionally be called with an error.
 *
 *  @param error The error that occurred, if any.
 */
typedef void (^STPErrorBlock)(NSError * __nullable error);

/**
 *  A callback to be run with a token response from the Stripe API.
 *
 *  @param token The Stripe token from the response. Will be nil if an error occurs. @see STPToken
 *  @param error The error returned from the response, or nil in one occurs. @see StripeError.h for possible values.
 */
typedef void (^STPTokenCompletionBlock)(STPToken * __nullable token, NSError * __nullable error);

/**
 *  A callback to be run with a source response from the Stripe API.
 *
 *  @param source The Stripe source from the response. Will be nil if an error occurs. @see STPSource
 *  @param error The error returned from the response, or nil in one occurs. @see StripeError.h for possible values.
 */
typedef void (^STPSourceCompletionBlock)(STPSource * __nullable source, NSError * __nullable error);

/**
 *  A callback to be run with a validation result and shipping methods for a 
 *  shipping address.
 *
 *  @param status An enum representing whether the shipping address is valid.
 *  @param shippingValidationError If the shipping address is invalid, an error describing the issue with the address. If no error is given and the address is invalid, the default error message will be used.
 *  @param shippingMethods The shipping methods available for the address.
 *  @param selectedShippingMethod The default selected shipping method for the address.
 */
typedef void (^STPShippingMethodsCompletionBlock)(STPShippingStatus status, NSError * __nullable shippingValidationError, NSArray<PKShippingMethod *>* __nullable shippingMethods, PKShippingMethod * __nullable selectedShippingMethod);
