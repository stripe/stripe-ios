//
//  STPSetupIntent.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"
#import "STPSetupIntentEnums.h"

@class STPIntentAction, STPSetupIntentLastSetupError;

NS_ASSUME_NONNULL_BEGIN

/**
 A SetupIntent guides you through the process of setting up a customer's payment credentials for future payments.

 @see https://stripe.com/docs/api/setup_intents
 */
@interface STPSetupIntent : NSObject<STPAPIResponseDecodable>

/**
 The Stripe ID of the SetupIntent.
 */
@property (nonatomic, readonly) NSString *stripeID;

/**
 The client secret of this SetupIntent. Used for client-side retrieval using a publishable key.
 */
@property (nonatomic, readonly) NSString *clientSecret;

/**
 Time at which the object was created.
 */
@property (nonatomic, readonly) NSDate *created;

/**
 ID of the Customer this SetupIntent belongs to, if one exists.
 */
@property (nonatomic, nullable, readonly) NSString *customerID;

/**
 An arbitrary string attached to the object. Often useful for displaying to users.
 */
@property (nonatomic, nullable, readonly) NSString *stripeDescription;

/**
 Has the value `YES` if the object exists in live mode or the value `NO` if the object exists in test mode.
 */
@property (nonatomic, readonly) BOOL livemode;

/**
 Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
 
 @see https://stripe.com/docs/api#metadata
 */
@property (nonatomic, nullable, readonly) NSDictionary<NSString*, NSString *> *metadata;

/**
 If present, this property tells you what actions you need to take in order for your customer to set up this payment method.
 */
@property (nonatomic, nullable, readonly) STPIntentAction *nextAction;

/**
 ID of the payment method used with this SetupIntent.
 */
@property (nonatomic, nullable, readonly) NSString *paymentMethodID;

/**
 The list of payment method types (e.g. `@[@(STPPaymentMethodTypeCard)]`) that this SetupIntent is allowed to set up.
 */
@property (nonatomic, readonly) NSArray<NSNumber *> *paymentMethodTypes;

/**
 Status of this SetupIntent.
 */
@property (nonatomic, readonly) STPSetupIntentStatus status;

/**
 Indicates how the payment method is intended to be used in the future.
 */
@property (nonatomic, readonly) STPSetupIntentUsage usage;

/**
 The setup error encountered in the previous SetupIntent confirmation.
 */
@property (nonatomic, nullable, readonly) STPSetupIntentLastSetupError *lastSetupError;

@end

NS_ASSUME_NONNULL_END
