//
//  STPPaymentMethodAUBECSDebitParams.m
//  StripeiOS
//
//  Created by Cameron Sabol on 3/3/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodAUBECSDebitParams.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPPaymentMethodAUBECSDebitParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

#pragma mark - STPFormEncodable

+ (nullable NSString *)rootObjectName {
    return @"au_becs_debit";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(accountNumber)): @"account_number",
             NSStringFromSelector(@selector(bsbNumber)): @"bsb_number",
             };
}

@end

NS_ASSUME_NONNULL_END
