//
//  STPPaymentMethod.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"
#import "STPSourceProtocol.h"

@class STPPaymentMethodBillingDetails, STPPaymentMethodCard;

NS_ASSUME_NONNULL_BEGIN

/**
 PaymentMethod objects represent your customer's payment instruments. They can be used with PaymentIntents to collect payments.
 
 @see https://stripe.com/docs/api/payment_methods
 */
@interface STPPaymentMethod : NSObject <STPAPIResponseDecodable>

/**
 Unique identifier for the object.
 */
@property (nonatomic, readonly) NSString *identifier;

/**
 Time at which the object was created. Measured in seconds since the Unix epoch.
 */
@property (nonatomic, nullable, readonly) NSDate *created;

/**
 `YES` if the object exists in live mode or the value `NO` if the object exists in test mode.
 */
@property (nonatomic, readonly) BOOL liveMode;

/**
 The type of the PaymentMethod, currently only @"card" is supported. The corresponding property (`card`) contains additional information specific to the PaymentMethod type.
 */
@property (nonatomic, nullable, readonly) NSString *type;

/**
 Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodBillingDetails *billingDetails;

/**
 If this is a card PaymentMethod (ie `self.type == @"card"`), this contains details about the card.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodCard *card;

/**
 The ID of the Customer to which this PaymentMethod is saved. Nil when the PaymentMethod has not been saved to a Customer.
 */
@property (nonatomic, nullable, readonly) NSString *customerId;

/**
 Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
 */
@property (nonatomic, nullable, readonly) NSDictionary<NSString*, NSString *> *metadata;

@end

NS_ASSUME_NONNULL_END
