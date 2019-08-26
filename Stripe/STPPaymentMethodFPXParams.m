//
//  STPPaymentMethodFPXParams.m
//  Stripe
//
//  Created by David Estes on 7/30/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodFPXParams.h"

@implementation STPPaymentMethodFPXParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

#pragma mark - STPFormEncodable

- (STPBankBrand)bank {
    return STPBankBrandFromIdentifier(self.rawBankString);
}

- (void)setBank:(STPBankBrand)bank {
    // If setting unknown and we're already unknown, don't want to override raw value
    if (bank != self.bank) {
        self.rawBankString = STPIdentifierFromBankBrand(bank);
    }
}

+ (NSString *)rootObjectName {
    return @"fpx";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(rawBankString)): @"bank",
             };
}

@end
