//
//  STPPaymentMethodParams.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/6/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodParams.h"

#import "STPCardValidator+Private.h"
#import "STPFormEncoder.h"
#import "STPFPXBankBrand.h"
#import "STPImageLibrary+Private.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentMethod+Private.h"
#import "STPPaymentMethodCardParams.h"
#import "STPPaymentMethodFPX.h"
#import "STPPaymentMethodFPXParams.h"
#import "STPPaymentMethodiDEAL.h"
#import "STPPaymentMethodiDEALParams.h"
#import "STPPaymentMethodSEPADebitParams.h"
#import "STPPaymentMethodBacsDebit.h"

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

+ (nullable STPPaymentMethodParams *)paramsWithSEPADebit:(STPPaymentMethodSEPADebitParams *)sepaDebit
billingDetails:(STPPaymentMethodBillingDetails *)billingDetails
                                                metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata {
    STPPaymentMethodParams *params = [self new];
    params.type = STPPaymentMethodTypeSEPADebit;
    params.sepaDebit = sepaDebit;
    params.billingDetails = billingDetails;
    params.metadata = metadata;
    return params;
}

+ (STPPaymentMethodParams *)paramsWithBacsDebit:(STPPaymentMethodBacsDebitParams *)bacsDebit billingDetails:(STPPaymentMethodBillingDetails *)billingDetails metadata:(NSDictionary<NSString *,NSString *> *)metadata {
    STPPaymentMethodParams *params = [self new];
    params.type = STPPaymentMethodTypeBacsDebit;
    params.bacsDebit = bacsDebit;
    params.billingDetails = billingDetails;
    params.metadata = metadata;
    return params;
}

+ (nullable STPPaymentMethodParams *)paramsWithAUBECSDebit:(STPPaymentMethodAUBECSDebitParams *)auBECSDebit
                                            billingDetails:(STPPaymentMethodBillingDetails *)billingDetails
                                                  metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata {
    STPPaymentMethodParams *params = [self new];
    params.type = STPPaymentMethodTypeAUBECSDebit;
    params.auBECSDebit = auBECSDebit;
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
        case STPPaymentMethodTypeSEPADebit:
        case STPPaymentMethodTypeBacsDebit:
        case STPPaymentMethodTypeCard:
        case STPPaymentMethodTypeCardPresent:
        case STPPaymentMethodTypeAUBECSDebit:
            // fall through
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
             NSStringFromSelector(@selector(sepaDebit)): @"sepa_debit",
             NSStringFromSelector(@selector(bacsDebit)): @"bacs_debit",
             NSStringFromSelector(@selector(auBECSDebit)): @"au_becs_debit",
             NSStringFromSelector(@selector(metadata)): @"metadata",
             };
}

#pragma mark - STPPaymentOption

- (UIImage *)image {
    if (self.type == STPPaymentMethodTypeCard && self.card != nil) {
        STPCardBrand brand = [STPCardValidator brandForNumber:self.card.number];
        return [STPImageLibrary brandImageForCardBrand:brand];
    } else {
        return [STPImageLibrary brandImageForCardBrand:STPCardBrandUnknown];
    }}

- (UIImage *)templateImage {
    if (self.type == STPPaymentMethodTypeCard && self.card != nil) {
        STPCardBrand brand = [STPCardValidator brandForNumber:self.card.number];
        return [STPImageLibrary templatedBrandImageForCardBrand:brand];
    } else if (self.type == STPPaymentMethodTypeFPX) {
        return [STPImageLibrary bankIcon];
    } else {
        return [STPImageLibrary templatedBrandImageForCardBrand:STPCardBrandUnknown];
    }
}

- (NSString *)label {
    switch (self.type) {
        case STPPaymentMethodTypeCard:
            if (self.card != nil) {
                STPCardBrand brand = [STPCardValidator brandForNumber:self.card.number];
                NSString *brandString = STPStringFromCardBrand(brand);
                return [NSString stringWithFormat:@"%@ %@", brandString, self.card.last4];
            } else {
                return STPStringFromCardBrand(STPCardBrandUnknown);
            }
        case STPPaymentMethodTypeiDEAL:
            return @"iDEAL";
        case STPPaymentMethodTypeFPX:
            if (self.fpx != nil) {
                return STPStringFromFPXBankBrand(self.fpx.bank);
            } else {
                return @"FPX";
            }
        case STPPaymentMethodTypeSEPADebit:
            return @"SEPA Debit";
        case STPPaymentMethodTypeBacsDebit:
            return @"Bacs Debit";
        case STPPaymentMethodTypeAUBECSDebit:
            return @"AU BECS Debit";
        case STPPaymentMethodTypeCardPresent:
        case STPPaymentMethodTypeUnknown:
            return STPLocalizedString(@"Unknown", @"Default missing source type label");

    }
}

- (BOOL)isReusable {

    switch (self.type) {
        case STPPaymentMethodTypeCard:
            return YES;

        case STPPaymentMethodTypeAUBECSDebit:
        case STPPaymentMethodTypeBacsDebit:
        case STPPaymentMethodTypeSEPADebit:
        case STPPaymentMethodTypeiDEAL:
        case STPPaymentMethodTypeFPX:
        case STPPaymentMethodTypeCardPresent:
            // fall through
        case STPPaymentMethodTypeUnknown:
            return NO;
    }
}

@end
