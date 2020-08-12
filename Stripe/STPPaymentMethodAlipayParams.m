//
//  STPPaymentMethodAlipayParams.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 5/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodAlipayParams.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPPaymentMethodAlipayParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

#pragma mark - STPFormEncodable

+ (nullable NSString *)rootObjectName {
    return @"alipay";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{};
}

@end

NS_ASSUME_NONNULL_END
