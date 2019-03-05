//
//  STPPaymentMethod.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethod.h"

@interface STPPaymentMethod ()

@property (nonatomic, nullable) NSString *identifier;
@property (nonatomic, nullable) NSDate *created;
@property (nonatomic) BOOL liveMode;
@property (nonatomic, nullable) NSString *type;
@property (nonatomic, nullable) STPPaymentMethodBillingDetails *billingDetails;
@property (nonatomic, nullable) STPPaymentMethodCard *card;
@property (nonatomic, nullable) NSString *customerId;
@property (nonatomic, nullable, copy) NSDictionary<NSString*, NSString *> *metadata;

@end


@implementation STPPaymentMethod

@end
