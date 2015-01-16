//
//  PKPayment+STPTestKeys.h
//  StripeExample
//
//  Created by Jack Flintermann on 9/8/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//



#import <PassKit/PassKit.h>

extern NSString * const STPSuccessfulChargeCardNumber;
extern NSString * const STPFailingChargeCardNumber;

@interface PKPayment (STPTestKeys)
@property(nonatomic, strong) NSString *stp_testCardNumber;
@end


