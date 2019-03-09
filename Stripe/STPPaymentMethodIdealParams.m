//
//  STPPaymentMethodIdealParams.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodIdealParams.h"

@implementation STPPaymentMethodIdealParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

#pragma mark - STPFormEncodable

+ (NSString *)rootObjectName {
    return @"ideal";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(bank)): @"bank",
             };
}

@end
