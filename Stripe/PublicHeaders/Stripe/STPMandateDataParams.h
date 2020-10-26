//
//  STPMandateDataParams.h
//  Stripe
//
//  Created by Cameron Sabol on 10/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

@class STPMandateCustomerAcceptanceParams;

NS_ASSUME_NONNULL_BEGIN

/**
 This object contains details about the Mandate to create. @see https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-mandate_data
 */
@interface STPMandateDataParams : NSObject <STPFormEncodable>

/**
 Details about the customer acceptance of the Mandate.
 */
@property (nonatomic) STPMandateCustomerAcceptanceParams *customerAcceptance;

@end

NS_ASSUME_NONNULL_END
