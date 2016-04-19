//
//  STPPaymentRequest.m
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentRequest.h"

@interface STPPaymentRequest ()

@property (nonatomic, readwrite) NSUInteger amount;
@property (nonatomic, readwrite) NSString *currency;

@end

@implementation STPPaymentRequest

- (instancetype)initWithAppleMerchantIdentifier:(NSString *)appleMerchantIdentifier
                             paymentMethod:(id<STPPaymentMethod>)paymentMethod
                               amount:(NSUInteger)amount
                                       currency:(NSString *)currency {
    self = [super init];
    if (self) {
        _appleMerchantIdentifier = appleMerchantIdentifier;
        _paymentMethod = paymentMethod;
        _amount = amount;
        _currency = currency;
    }
    return self;
}

- (NSDecimalNumber *)decimalAmount {
    NSArray *noDecimalCurrencies = @[@"bif", @"clp",@"djf",@"gnf",
                      @"jpy",@"kmf",@"krw",@"mga",@"pyg",@"rwf",@"vnd",
                                    @"vuv",@"xaf",@"xof", @"xpf"];
    NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithMantissa:self.amount exponent:0 isNegative:NO];
    if ([noDecimalCurrencies containsObject:self.currency.lowercaseString]) {
        return number;
    }
    return [number decimalNumberByMultiplyingByPowerOf10:-2];
}

@end
