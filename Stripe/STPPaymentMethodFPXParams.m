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

- (STPFPXBankBrand)bank {
    return STPFPXBankBrandFromIdentifier(self.rawBankString);
}

- (void)setBank:(STPFPXBankBrand)bank {
    // If setting unknown and we're already unknown, don't want to override raw value
    if (bank != self.bank) {
        self.rawBankString = STPIdentifierFromFPXBankBrand(bank);
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
