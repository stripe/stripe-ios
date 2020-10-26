//
//  STPPaymentMethodBacsDebitParams.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 1/29/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodBacsDebitParams.h"

@implementation STPPaymentMethodBacsDebitParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

+ (nullable NSString *)rootObjectName {
    return @"bacs_debit";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(sortCode)): @"sort_code",
             NSStringFromSelector(@selector(accountNumber)): @"account_number",
             };
}

@end
