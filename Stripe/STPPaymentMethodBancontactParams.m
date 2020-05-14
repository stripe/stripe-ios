//
//  STPPaymentMethodBancontactParams.m
//  StripeiOS
//
//  Created by Vineet Shah on 4/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodBancontactParams.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPPaymentMethodBancontactParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

+ (nullable NSString *)rootObjectName {
    return @"bancontact";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             };
}

@end

NS_ASSUME_NONNULL_END
