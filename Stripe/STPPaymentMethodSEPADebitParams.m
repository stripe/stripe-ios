//
//  STPPaymentMethodSEPADebitParams.m
//  StripeiOS
//
//  Created by Cameron Sabol on 10/7/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodSEPADebitParams.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPPaymentMethodSEPADebitParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

#pragma mark - STPFormEncodable

+ (nullable NSString *)rootObjectName {
    return @"sepa_debit";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(iban)): @"iban",
             };
}
@end

NS_ASSUME_NONNULL_END
