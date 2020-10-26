//
//  STPPaymentMethodCardParams.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodCardParams.h"

#import "STPCardParams.h"
#import "FauxPasAnnotations.h"

@implementation STPPaymentMethodCardParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

- (instancetype)initWithCardSourceParams:(STPCardParams *)cardSourceParams {
    self = [self init];
    if (self) {
        _number = [cardSourceParams.number copy];
        _expMonth = @(cardSourceParams.expMonth);
        _expYear = @(cardSourceParams.expYear);
        _cvc = [cardSourceParams.cvc copy];
    }

    return self;
}

#pragma mark - Description

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // Basic card details
                       [NSString stringWithFormat:@"last4 = %@", self.last4],
                       [NSString stringWithFormat:@"expMonth = %@", self.expMonth],
                       [NSString stringWithFormat:@"expYear = %@", self.expYear],
                       [NSString stringWithFormat:@"cvc = %@", (self.cvc) ? @"<redacted>" : nil],
                       
                       // Token
                       [NSString stringWithFormat:@"token = %@", self.token],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

- (NSString *)last4 {
    if (self.number && self.number.length >= 4) {
        return [self.number substringFromIndex:(self.number.length - 4)];
    } else {
        return nil;
    }
}

#pragma mark - STPFormEncodable


+ (NSString *)rootObjectName {
    return @"card";
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(number)): @"number",
             NSStringFromSelector(@selector(expMonth)): @"exp_month",
             NSStringFromSelector(@selector(expYear)): @"exp_year",
             NSStringFromSelector(@selector(cvc)): @"cvc",
             NSStringFromSelector(@selector(token)): @"token",
             };
}

#pragma mark - NSCopying

- (id)copyWithZone:(__unused NSZone *)zone { FAUXPAS_IGNORED_ON_LINE(UnusedMethod)
    STPPaymentMethodCardParams *copyCardParams = [self.class new];
    
    copyCardParams.number = self.number;
    copyCardParams.expMonth = self.expMonth;
    copyCardParams.expYear = self.expYear;
    copyCardParams.cvc = self.cvc;
    return copyCardParams;
}


@end
