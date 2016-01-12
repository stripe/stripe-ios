//
//  STPPaymentRequest.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentRequest.h"

@interface STPPaymentRequest()

@property(nonatomic) NSString *appleMerchantId;

@end

@implementation STPPaymentRequest

- (instancetype)initWithAppleMerchantId:(NSString *)appleMerchantId {
    self = [super init];
    if (self) {
        _appleMerchantId = appleMerchantId;
        _lineItems = @[];
    }
    return self;
}

@end
