//
//  STPPaymentMethodParams.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPCardValidator+Private.h"
#import "STPPaymentMethodParams.h"
#import "STPPaymentMethod+Private.h"
#import "STPPaymentMethodFPX.h"
#import "STPPaymentMethodFPXParams.h"
#import "STPPaymentMethodiDEAL.h"
#import "STPPaymentMethodiDEALParams.h"
#import "STPImageLibrary+Private.h"
#import "STPFPXBankBrand.h"
#import "STPPaymentMethodCardParams.h"
#import "STPLocalizationUtils.h"
#import "STPFormEncoder.h"

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

+ (STPPaymentMethodParams *)paramsWithFPX:(STPPaymentMethodFPXParams *)fpx billingDetails:(STPPaymentMethodBillingDetails *)billingDetails metadata:(NSDictionary<NSString *,NSString *> *)metadata {
    STPPaymentMethodParams *params = [self new];
    params.type = STPPaymentMethodTypeFPX;
    params.fpx = fpx;
    params.billingDetails = billingDetails;
    params.metadata = metadata;
    return params;
}

+ (nullable STPPaymentMethodParams *)paramsWithSingleUsePaymentMethod:(STPPaymentMethod *)paymentMethod {
    STPPaymentMethodParams *params = [self new];
    switch ([paymentMethod type]) {
        case STPPaymentMethodTypeFPX:
        {
            params.type = STPPaymentMethodTypeFPX;
            STPPaymentMethodFPXParams *fpx = [[STPPaymentMethodFPXParams alloc] init];
            fpx.rawBankString = paymentMethod.fpx.bankIdentifierCode;
            params.fpx = fpx;
            params.billingDetails = paymentMethod.billingDetails;
            params.metadata = paymentMethod.metadata;
            break;
        }
        case STPPaymentMethodTypeiDEAL:
        {
            params.type = STPPaymentMethodTypeiDEAL;
            STPPaymentMethodiDEALParams *iDEAL = [[STPPaymentMethodiDEALParams alloc] init];
            params.iDEAL = iDEAL;
            params.iDEAL.bankName = paymentMethod.iDEAL.bankName;
            params.billingDetails = paymentMethod.billingDetails;
            params.metadata = paymentMethod.metadata;
            break;
        }
        case STPPaymentMethodTypeCard:
        case STPPaymentMethodTypeCardPresent:
        case STPPaymentMethodTypeUnknown:
            return nil;
    }
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
             NSStringFromSelector(@selector(fpx)): @"fpx",
             NSStringFromSelector(@selector(metadata)): @"metadata",
             };
}

@end
