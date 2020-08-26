//
//  STPMandateCustomerAcceptanceParams.h
//  Stripe
//
//  Created by Cameron Sabol on 10/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

@class STPMandateOnlineParams;

NS_ASSUME_NONNULL_BEGIN

/**
 The type of customer acceptance information included with the Mandate.
 */
typedef NS_ENUM(NSInteger, STPMandateCustomerAcceptanceType) {
    /// A Mandate that was accepted online.
    STPMandateCustomerAcceptanceTypeOnline,

    /// A Mandate that was accepted offline.
    STPMandateCustomerAcceptanceTypeOffline,
};

/**
 An object that contains details about the customer acceptance of the Mandate. @see https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-mandate_data-customer_acceptance
 */
@interface STPMandateCustomerAcceptanceParams : NSObject <STPFormEncodable>

/**
 The type of customer acceptance information included with the Mandate.
 */
@property (nonatomic) STPMandateCustomerAcceptanceType type;

/**
 If this is a Mandate accepted online, this object contains details about the online acceptance.
 @note If `type == STPMandateCustomerAcceptanceTypeOnline`, this value must be non-nil.
 */
@property (nonatomic, nullable) STPMandateOnlineParams *onlineParams;

@end

NS_ASSUME_NONNULL_END
