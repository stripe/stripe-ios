//
//  STPIntentActionOXXODisplayDetails.h
//  Stripe
//
//  Created by Polo Li on 6/23/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Contains OXXO details necessary for the customer to complete the payment.
 */
@interface STPIntentActionOXXODisplayDetails : NSObject<STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPIntentActionOXXODisplayDetails`.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPIntentActionOXXODisplayDetails.")));

/**
 The timestamp after which the OXXO voucher expires.
 */
@property (nonatomic, readonly) NSDate *expiresAfter;

/**
 The URL for the hosted OXXO voucher page, which allows customers to view and print an OXXO voucher.
 */
@property (nonatomic, readonly) NSURL *hostedVoucherURL;

/**
 OXXO reference number.
 */
@property (nonatomic, readonly) NSString *number;

@end

NS_ASSUME_NONNULL_END
