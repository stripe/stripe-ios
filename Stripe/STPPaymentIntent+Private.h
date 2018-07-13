//
//  STPPaymentIntent+Private.h
//  Stripe
//
//  Created by Daniel Jackson on 6/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPPaymentIntent.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentIntent ()

/**
 Helper function for extracting PaymentIntent id from the Client Secret.
 This avoids having to pass around both the id and the secret.

 @param clientSecret The `client_secret` from the PaymentIntent
 */
+ (nullable NSString *)idFromClientSecret:(NSString *)clientSecret;

/**
 Parse the string and return the correct `STPPaymentIntentStatus`,
 or `STPPaymentIntentStatusUnknown` if it's unrecognized by this version of the SDK.

 @param string the NSString with the status
 */
+ (STPPaymentIntentStatus)statusFromString:(NSString *)string;

/**
 Parse the string and return the correct `STPPaymentIntentCaptureMethod`,
 or `STPPaymentIntentCaptureMethodUnknown` if it's unrecognized by this version of the SDK.

 @param string the NSString with the capture method
 */
+ (STPPaymentIntentCaptureMethod)captureMethodFromString:(NSString *)string;

/**
 Parse the string and return the correct `STPPaymentIntentConfirmationMethod`,
 or `STPPaymentIntentConfirmationMethodUnknown` if it's unrecognized by this version of the SDK.

 @param string the NSString with the capture method
 */
+ (STPPaymentIntentConfirmationMethod)confirmationMethodFromString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
