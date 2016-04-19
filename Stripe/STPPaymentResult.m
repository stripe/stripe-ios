//
//  STPPaymentResult.m
//  Stripe
//
//  Created by Jack Flintermann on 1/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentResult.h"
#import "STPAddress.h"

@interface STPPaymentResult()

@property(nonatomic, nonnull) id<STPSource> source;
@property(nonatomic, nullable) NSString *customer;
@property(nonatomic, nullable) STPAddress *shippingAddress;

@end

@implementation STPPaymentResult

- (nonnull instancetype)initWithSource:(nonnull id<STPSource>)source customer:(nullable NSString *)customer shippingAddress:(nullable STPAddress *)shippingAddress {
    self = [super init];
    if (self) {
        _source = source;
        _customer = customer;
        _shippingAddress = shippingAddress;
    }
    return self;
}

@end
