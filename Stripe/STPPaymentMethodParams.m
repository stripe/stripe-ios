//
//  STPPaymentMethodParams.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodParams.h"
#import "STPPaymentMethod+Private.h"

@implementation STPPaymentMethodParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

+ (STPPaymentMethodParams *)paramsWithCard:(STPPaymentMethodCardParams *)card billingDetails:(STPPaymentMethodBillingDetails *)billingDetails metadata:(NSDictionary<NSString *,NSString *> *)metadata {
    STPPaymentMethodParams *params = [self new];
    params.type = STPPaymentMethodTypeCard;
    params.card = card;
    params.billingDetails = billingDetails;
    params.metadata = metadata;
    return params;
}

+ (STPPaymentMethodParams *)paramsWithiDEAL:(STPPaymentMethodiDEALParams *)iDEAL billingDetails:(STPPaymentMethodBillingDetails *)billingDetails metadata:(NSDictionary<NSString *,NSString *> *)metadata {
    STPPaymentMethodParams *params = [self new];
    params.type = STPPaymentMethodTypeiDEAL;
    params.iDEAL = iDEAL;
    params.billingDetails = billingDetails;
    params.metadata = metadata;
    return params;
}

- (STPPaymentMethodType)type {
    return [STPPaymentMethod typeFromString:self.rawTypeString];
}

- (void)setType:(STPPaymentMethodType)type {
    if (type != self.type) {
        self.rawTypeString = [STPPaymentMethod stringFromType:type];
    }
}

#pragma mark - STPFormEncodable

+ (nullable NSString *)rootObjectName {
    return nil;
}

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(rawTypeString)): @"type",
             NSStringFromSelector(@selector(billingDetails)): @"billing_details",
             NSStringFromSelector(@selector(card)): @"card",
             NSStringFromSelector(@selector(iDEAL)): @"ideal",
             NSStringFromSelector(@selector(metadata)): @"metadata",
             };
}

@end
