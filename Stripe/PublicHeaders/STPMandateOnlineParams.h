//
//  STPMandateOnlineParams.h
//  Stripe
//
//  Created by Cameron Sabol on 10/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Contains details about a Mandate accepted online. @see https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-mandate_data-customer_acceptance-online
 */
@interface STPMandateOnlineParams : NSObject <STPFormEncodable>

/**
 The IP address from which the Mandate was accepted by the customer.
 */
@property (nonatomic, copy) NSString *ipAddress;

/**
 The user agent of the browser from which the Mandate was accepted by the customer.
 */
@property (nonatomic, copy) NSString *userAgent;

@end

NS_ASSUME_NONNULL_END
