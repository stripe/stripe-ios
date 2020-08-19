//
//  STPPaymentMethodGrabPayParams.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 7/21/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodGrabPayParams.h"

@implementation STPPaymentMethodGrabPayParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

#pragma mark - STPFormEncodable

+ (NSString *)rootObjectName {
    return @"grabpay";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{};
}

@end
