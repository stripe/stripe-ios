//
//  STPPaymentMethodAfterpayClearpayParams.m
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 10/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodAfterpayClearpayParams.h"

@implementation STPPaymentMethodAfterpayClearpayParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

#pragma mark - STPFormEncodable

+ (NSString *)rootObjectName {
    return @"afterpay_clearpay";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             };
}

@end
