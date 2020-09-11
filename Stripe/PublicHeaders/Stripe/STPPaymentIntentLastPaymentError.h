//
//  STPPaymentIntentLastPaymentError.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 8/8/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

@class STPPaymentMethod;

/**
 The type of the error represented by `STPPaymentIntentLastPaymentError`.
 
 Some STPPaymentIntentLastPaymentError properties are only populated for certain error types.
 */
typedef NS_ENUM(NSUInteger, STPPaymentIntentLastPaymentErrorType) {
    /**
     An unknown error type.
     */
    STPPaymentIntentLastPaymentErrorTypeUnknown,
    
    /**
     An error connecting to Stripe's API.
     */
    STPPaymentIntentLastPaymentErrorTypeAPIConnection,
    
    /**
     An error with the Stripe API.
     */
    STPPaymentIntentLastPaymentErrorTypeAPI,
    
    /**
     A failure to authenticate your customer.
     */
    STPPaymentIntentLastPaymentErrorTypeAuthentication,
    
    /**
     Card errors are the most common type of error you should expect to handle.
     They result when the user enters a card that can't be charged for some reason.
     
     Check the `declineCode` property for the decline code.  The `message` property contains a message you can show to your users.
     */
    STPPaymentIntentLastPaymentErrorTypeCard,
    
    /**
     Keys for idempotent requests can only be used with the same parameters they were first used with.
     */
    STPPaymentIntentLastPaymentErrorTypeIdempotency,
    
    /**
     Invalid request errors.  Typically, this is because your request has invalid parameters.
     */
    STPPaymentIntentLastPaymentErrorTypeInvalidRequest,
    
    /**
     Too many requests hit the API too quickly.
     */
    STPPaymentIntentLastPaymentErrorTypeRateLimit,
};

NS_ASSUME_NONNULL_BEGIN

/**
 A value for `code` indicating the provided payment method failed authentication.
 */
extern NSString *const STPPaymentIntentLastPaymentErrorCodeAuthenticationFailure;

/**
 The payment error encountered in the previous PaymentIntent confirmation.
 
 @see https://stripe.com/docs/api/payment_intents/object#payment_intent_object-last_payment_error
 */
@interface STPPaymentIntentLastPaymentError : NSObject <STPAPIResponseDecodable>

/**
 For some errors that could be handled programmatically, a short string indicating the error code reported.
 
 @see https://stripe.com/docs/error-codes
 */
@property (nonatomic, nullable, readonly) NSString *code;

/**
 For card (`STPPaymentIntentLastPaymentErrorTypeCard`) errors resulting from a card issuer decline,
 a short string indicating the card issuer’s reason for the decline if they provide one.
 
 @see https://stripe.com/docs/declines#issuer-declines
 */
@property (nonatomic, nullable, readonly) NSString *declineCode;

/**
 A URL to more information about the error code reported.
 
 @see https://stripe.com/docs/error-codes
 */
@property (nonatomic, readonly) NSString *docURL;

/**
 A human-readable message providing more details about the error.
 For card (`STPPaymentIntentLastPaymentErrorTypeCard`) errors, these messages can be shown to your users.
 */
@property (nonatomic, readonly) NSString *message;

/**
 If the error is parameter-specific, the parameter related to the error.
 For example, you can use this to display a message near the correct form field.
 */
@property (nonatomic, nullable, readonly) NSString *param;

/**
 The PaymentMethod object for errors returned on a request involving a PaymentMethod.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethod *paymentMethod;

/**
 The type of error.
 */
@property (nonatomic, readonly) STPPaymentIntentLastPaymentErrorType type;

@end

NS_ASSUME_NONNULL_END
