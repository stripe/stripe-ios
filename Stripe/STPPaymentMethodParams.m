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
#import "STPPaymentMethodBacsDebit.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentMethod+Private.h"
#import "STPPaymentMethodBacsDebit.h"
#import "STPPaymentMethodBancontactParams.h"
#import "STPPaymentMethodCardParams.h"
#import "STPPaymentMethodEPSParams.h"
#import "STPPaymentMethodFPX.h"
#import "STPPaymentMethodFPXParams.h"
#import "STPPaymentMethodGiropayParams.h"
#import "STPPaymentMethodGrabPayParams.h"
#import "STPPaymentMethodiDEAL.h"
#import "STPPaymentMethodiDEALParams.h"
#import "STPPaymentMethodOXXOParams.h"
#import "STPPaymentMethodPayPalParams.h"
#import "STPPaymentMethodPrzelewy24Params.h"
#import "STPPaymentMethodSEPADebitParams.h"
#import "STPPaymentMethodSofortParams.h"

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

+ (nullable STPPaymentMethodParams *)paramsWithGiropay:(STPPaymentMethodGiropayParams *)giropay
                                        billingDetails:(STPPaymentMethodBillingDetails *)billingDetails
                                              metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata {
    STPPaymentMethodParams *params = [self new];
    params.type = STPPaymentMethodTypeGiropay;
    params.giropay = giropay;
    params.billingDetails = billingDetails;
    params.metadata = metadata;
    return params;
}

+ (nonnull STPPaymentMethodParams *)paramsWithEPS:(STPPaymentMethodEPSParams *)eps
                                    billingDetails:(STPPaymentMethodBillingDetails *)billingDetails
                                          metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata {
    STPPaymentMethodParams *params = [self new];
    params.type = STPPaymentMethodTypeEPS;
    params.eps = eps;
    params.billingDetails = billingDetails;
    params.metadata = metadata;
    return params;
}

+ (STPPaymentMethodParams *)paramsWithPrzelewy24:(STPPaymentMethodPrzelewy24Params *)przelewy24
                                  billingDetails:(STPPaymentMethodBillingDetails *)billingDetails
                                        metadata:(NSDictionary<NSString *,NSString *> *)metadata {
    STPPaymentMethodParams *params = [self new];
    params.type = STPPaymentMethodTypePrzelewy24;
    params.przelewy24 = przelewy24;
    params.billingDetails = billingDetails;
    params.metadata = metadata;
    return params;
}

+ (nullable STPPaymentMethodParams *)paramsWithBancontact:(STPPaymentMethodBancontactParams *)bancontact
                                           billingDetails:(STPPaymentMethodBillingDetails *)billingDetails
                                                 metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata {
    STPPaymentMethodParams *params = [self new];
    params.type = STPPaymentMethodTypeBancontact;
    params.bancontact = bancontact;
    params.billingDetails = billingDetails;
    params.metadata = metadata;
    return params;
}

+ (nullable STPPaymentMethodParams *)paramsWithOXXO:(STPPaymentMethodOXXOParams *)oxxo
                                     billingDetails:(STPPaymentMethodBillingDetails *)billingDetails
                                           metadata:(NSDictionary<NSString *,NSString *> *)metadata {
    STPPaymentMethodParams *params = [self new];
    params.type = STPPaymentMethodTypeOXXO;
    params.oxxo = oxxo;
    params.billingDetails = billingDetails;
    params.metadata = metadata;
    return params;
}

+ (nullable STPPaymentMethodParams *)paramsWithSofort:(STPPaymentMethodSofortParams *)sofort
                                       billingDetails:(nullable STPPaymentMethodBillingDetails *)billingDetails
                                             metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata {
    STPPaymentMethodParams *params = [self new];
    params.type = STPPaymentMethodTypeSofort;
    params.sofort = sofort;
    params.billingDetails = billingDetails;
    params.metadata = metadata;
    return params;
}

+ (STPPaymentMethodParams *)paramsWithAlipay:(STPPaymentMethodAlipayParams *)alipay billingDetails:(STPPaymentMethodBillingDetails *)billingDetails metadata:(NSDictionary<NSString *,NSString *> *)metadata {
    STPPaymentMethodParams *params = [self new];
    params.type = STPPaymentMethodTypeAlipay;
    params.alipay = alipay;
    params.billingDetails = billingDetails;
    params.metadata = metadata;
    return params;
}

+ (STPPaymentMethodParams *)paramsWithGrabPay:(STPPaymentMethodGrabPayParams *)grabPay
                               billingDetails:(STPPaymentMethodBillingDetails *)billingDetails
                                     metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata {
    STPPaymentMethodParams *params = [self new];
    params.type = STPPaymentMethodTypeGrabPay;
    params.grabPay = grabPay;
    params.billingDetails = billingDetails;
    params.metadata = metadata;
    return params;
}

+ (STPPaymentMethodParams *)paramsWithPayPal:(STPPaymentMethodPayPalParams *)payPal
                              billingDetails:(nullable STPPaymentMethodBillingDetails *)billingDetails
                                    metadata:(nullable NSDictionary<NSString *, NSString *> *)metadata {
    STPPaymentMethodParams *params = [self new];
    params.type = STPPaymentMethodTypePayPal;
    params.payPal = payPal;
    params.billingDetails = billingDetails;
    params.metadata = metadata;
    return params;
}

+ (nullable STPPaymentMethodParams *)paramsWithSingleUsePaymentMethod:(STPPaymentMethod *)paymentMethod {
    STPPaymentMethodParams *params = [self new];
    switch ([paymentMethod type]) {
        case STPPaymentMethodTypeEPS:
        {
            params.type = STPPaymentMethodTypeEPS;
            STPPaymentMethodEPSParams *eps = [[STPPaymentMethodEPSParams alloc] init];
            params.eps = eps;
            params.billingDetails = paymentMethod.billingDetails;
            break;
        }
        case STPPaymentMethodTypeFPX:
        {
            params.type = STPPaymentMethodTypeFPX;
            STPPaymentMethodFPXParams *fpx = [[STPPaymentMethodFPXParams alloc] init];
            fpx.rawBankString = paymentMethod.fpx.bankIdentifierCode;
            params.fpx = fpx;
            params.billingDetails = paymentMethod.billingDetails;
            break;
        }
        case STPPaymentMethodTypeiDEAL:
        {
            params.type = STPPaymentMethodTypeiDEAL;
            STPPaymentMethodiDEALParams *iDEAL = [[STPPaymentMethodiDEALParams alloc] init];
            params.iDEAL = iDEAL;
            params.iDEAL.bankName = paymentMethod.iDEAL.bankName;
            params.billingDetails = paymentMethod.billingDetails;
            break;
        }
        case STPPaymentMethodTypeGiropay:
        {
            params.type = STPPaymentMethodTypeGiropay;
            STPPaymentMethodGiropayParams *giropay = [[STPPaymentMethodGiropayParams alloc] init];
            params.giropay = giropay;
            params.billingDetails = paymentMethod.billingDetails;
            break;
        }
        case STPPaymentMethodTypePrzelewy24:
        {
            params.type = STPPaymentMethodTypePrzelewy24;
            STPPaymentMethodPrzelewy24Params *przelewy24 = [[STPPaymentMethodPrzelewy24Params alloc] init];
            params.przelewy24 = przelewy24;
            params.billingDetails = paymentMethod.billingDetails;
            break;
        }
        case STPPaymentMethodTypeBancontact:
        {
            params.type = STPPaymentMethodTypeBancontact;
            STPPaymentMethodBancontactParams *bancontact = [[STPPaymentMethodBancontactParams alloc] init];
            params.bancontact = bancontact;
            params.billingDetails = paymentMethod.billingDetails;
            break;
        }
        case STPPaymentMethodTypeOXXO:
        {
            params.type = STPPaymentMethodTypeOXXO;
            STPPaymentMethodOXXOParams *oxxo = [[STPPaymentMethodOXXOParams alloc] init];
            params.oxxo = oxxo;
            params.billingDetails = paymentMethod.billingDetails;
            break;
        }
        case STPPaymentMethodTypeAlipay:
        {
            // Careful! In the future, when we add recurring Alipay, we'll need to look at this!
            params.type = STPPaymentMethodTypeAlipay;
            params.billingDetails = paymentMethod.billingDetails;
            break;
        }
        case STPPaymentMethodTypeSofort:
        {
            params.type = STPPaymentMethodTypeSofort;
            STPPaymentMethodSofortParams *sofort = [[STPPaymentMethodSofortParams alloc] init];
            params.sofort = sofort;
            params.billingDetails = paymentMethod.billingDetails;
            break;
        }
        case STPPaymentMethodTypeGrabPay:
        {
            params.type = STPPaymentMethodTypeGrabPay;
            STPPaymentMethodGrabPayParams *grabpay = [STPPaymentMethodGrabPayParams new];
            params.grabPay = grabpay;
            params.billingDetails = paymentMethod.billingDetails;
            break;
        }
        case STPPaymentMethodTypePayPal:
        {
            params.type = STPPaymentMethodTypePayPal;
            STPPaymentMethodPayPalParams *payPal = [STPPaymentMethodPayPalParams new];
            params.payPal = payPal;
            params.billingDetails = paymentMethod.billingDetails;
            break;
        }
        // All reusable PaymentMethods go below:
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
             NSStringFromSelector(@selector(eps)): @"eps",
             NSStringFromSelector(@selector(fpx)): @"fpx",
             NSStringFromSelector(@selector(sepaDebit)): @"sepa_debit",
             NSStringFromSelector(@selector(bacsDebit)): @"bacs_debit",
             NSStringFromSelector(@selector(auBECSDebit)): @"au_becs_debit",
             NSStringFromSelector(@selector(giropay)): @"giropay",
             NSStringFromSelector(@selector(grabPay)): @"grabpay",
             NSStringFromSelector(@selector(przelewy24)): @"p24",
             NSStringFromSelector(@selector(bancontact)): @"bancontact",
             NSStringFromSelector(@selector(oxxo)): @"oxxo",
             NSStringFromSelector(@selector(sofort)): @"sofort",
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
        case STPPaymentMethodTypeAlipay:
            return @"Alipay"; //? Why aren't these localized?
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
        case STPPaymentMethodTypeGiropay:
            return @"giropay";
        case STPPaymentMethodTypePrzelewy24:
            return @"Przelewy24";
        case STPPaymentMethodTypeEPS:
            return @"EPS";
        case STPPaymentMethodTypeBancontact:
            return @"Bancontact";
        case STPPaymentMethodTypeOXXO:
            return @"OXXO";
        case STPPaymentMethodTypeSofort:
            return @"Sofort";
        case STPPaymentMethodTypeGrabPay:
            return @"GrabPay";
        case STPPaymentMethodTypePayPal:
            return @"PayPal";
        case STPPaymentMethodTypeCardPresent:
        case STPPaymentMethodTypeUnknown:
            return STPLocalizedString(@"Unknown", @"Default missing source type label");
    }
}

- (BOOL)isReusable {

    switch (self.type) {
        case STPPaymentMethodTypeCard:
            return YES;
        case STPPaymentMethodTypeAlipay:
        case STPPaymentMethodTypeAUBECSDebit:
        case STPPaymentMethodTypeBacsDebit:
        case STPPaymentMethodTypeSEPADebit:
        case STPPaymentMethodTypeiDEAL:
        case STPPaymentMethodTypeFPX:
        case STPPaymentMethodTypeCardPresent:
        case STPPaymentMethodTypeGiropay:
        case STPPaymentMethodTypeGrabPay:
        case STPPaymentMethodTypeEPS:
        case STPPaymentMethodTypePayPal:
        case STPPaymentMethodTypePrzelewy24:
        case STPPaymentMethodTypeBancontact:
        case STPPaymentMethodTypeOXXO:
        case STPPaymentMethodTypeSofort:
            // fall through
        case STPPaymentMethodTypeUnknown:
            return NO;
    }
}

@end
