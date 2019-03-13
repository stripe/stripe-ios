//
//  STPPaymentMethodiDEALParams.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodiDEALParams.h"

@implementation STPPaymentMethodiDEALParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

#pragma mark - STPFormEncodable

+ (NSString *)rootObjectName {
    return @"ideal";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(bankName)): @"bank",
             };
}

@end
