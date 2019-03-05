//
//  STPPaymentMethodCard.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodCard.h"

@interface STPPaymentMethodCard ()

@property (nonatomic, nullable) NSString *brand;
@property (nonatomic, nullable) STPPaymentMethodCardChecks *checks;
@property (nonatomic, nullable) NSString *country;
@property (nonatomic, nullable) NSString *expMonth;
@property (nonatomic, nullable) NSString *expYear;
@property (nonatomic, nullable) NSString *funding;
@property (nonatomic, nullable) NSString *last4;
@property (nonatomic, nullable) STPPaymentMethodThreeDSecureUsage *threeDSecureUsage;
@property (nonatomic, nullable) STPPaymentMethodCardWallet *wallet;

@end

@implementation STPPaymentMethodCard

@end
