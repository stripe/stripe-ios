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

+ (NSString *)rootObjectName {
    return @"fpx";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(bankName)): @"bank",
             };
}

@end
