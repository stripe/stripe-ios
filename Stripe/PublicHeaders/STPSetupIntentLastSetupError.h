//
//  STPSetupIntentLastSetupError.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 8/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

@class STPPaymentMethod;

/**
 The type of the error represented by `STPSetupIntentLastSetupError`.
 
 Some STPSetupIntentLastError properties are only populated for certain error types.
 */
typedef NS_ENUM(NSUInteger, STPSetupIntentLastSetupErrorType) {
    /**
     An unknown error type.
     */
    STPSetupIntentLastSetupErrorTypeUnknown,
    
    /**
     An error connecting to Stripe's API.
     */
    STPSetupIntentLastSetupErrorTypeAPIConnection,
    
    /**
     An error with the Stripe API.
     */
    STPSetupIntentLastSetupErrorTypeAPI,
    
    /**
     A failure to authenticate your customer.
     */
    STPSetupIntentLastSetupErrorTypeAuthentication,
    
    /**
     Card errors are the most common type of error you should expect to handle.
     They result when the user enters a card that can't be charged for some reason.
     
     Check the `declineCode` property for the decline code.  The `message` property contains a message you can show to your users.
     */
    STPSetupIntentLastSetupErrorTypeCard,
    
    /**
     Keys for idempotent requests can only be used with the same parameters they were first used with.
     */
    STPSetupIntentLastSetupErrorTypeIdempotency,
    
    /**
     Invalid request errors.  Typically, this is because your request has invalid parameters.
     */
    STPSetupIntentLastSetupErrorTypeInvalidRequest,
    
    /**
     Too many requests hit the API too quickly.
     */
    STPSetupIntentLastSetupErrorTypeRateLimit,
};

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Error Codes

/**
 A value for `code` indicating the provided payment method failed authentication.
 */
extern NSString *const STPSetupIntentLastSetupErrorCodeAuthenticationFailure;

/**
 The error encountered in the previous SetupIntent confirmation.
 
 @see https://stripe.com/docs/api/setup_intents/object#setup_intent_object-last_setup_error
*/
@interface STPSetupIntentLastSetupError : NSObject <STPAPIResponseDecodable>

/**
 For some errors that could be handled programmatically, a short string indicating the error code reported.
 
 @see https://stripe.com/docs/error-codes
 */
@property (nonatomic, nullable, readonly) NSString *code;

/**
 For card (`STPSetupIntentLastSetupErrorTypeCard`) errors resulting from a card issuer decline,
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
 For card (`STPSetupIntentLastSetupErrorTypeCard`) errors, these messages can be shown to your users.
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
@property (nonatomic, readonly) STPSetupIntentLastSetupErrorType type;

@end

NS_ASSUME_NONNULL_END
