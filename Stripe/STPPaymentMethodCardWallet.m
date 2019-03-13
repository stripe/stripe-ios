//
//  STPPaymentMethodCardWallet.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodCardWallet.h"
#import "STPPaymentMethodCardWallet+Private.h"

#import "STPPaymentMethodCardWalletVisaCheckout.h"
#import "STPPaymentMethodCardWalletMasterpass.h"

#import "NSDictionary+Stripe.h"

@interface STPPaymentMethodCardWallet()

@property (nonatomic, readwrite) STPPaymentMethodCardWalletType type;
@property (nonatomic, strong, nullable, readwrite) STPPaymentMethodCardWalletMasterpass *masterpass;
@property (nonatomic, strong, nullable, readwrite) STPPaymentMethodCardWalletVisaCheckout *visaCheckout;
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodCardWallet

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // Properties
                       [NSString stringWithFormat:@"masterpass: %@", self.masterpass],
                       [NSString stringWithFormat:@"visaCheckout: %@", self.visaCheckout],
                       ];
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPPaymentMethodCardWalletType

+ (NSDictionary<NSString *,NSNumber *> *)stringToTypeMapping {
    return @{
             @"amex_express_checkout": @(STPPaymentMethodCardWalletTypeAmexExpressCheckout),
             @"apple_pay": @(STPPaymentMethodCardWalletTypeApplePay),
             @"google_pay": @(STPPaymentMethodCardWalletTypeGooglePay),
             @"masterpass": @(STPPaymentMethodCardWalletTypeMasterpass),
             @"samsung_pay": @(STPPaymentMethodCardWalletTypeSamsungPay),
             @"visa_checkout": @(STPPaymentMethodCardWalletTypeVisaCheckout),
             };
}

+ (STPPaymentMethodCardWalletType)typeFromString:(NSString *)string {
    NSString *key = [string lowercaseString];
    NSNumber *typeNumber = [self stringToTypeMapping][key];
    
    if (typeNumber != nil) {
        return (STPPaymentMethodCardWalletType)[typeNumber integerValue];
    }
    
    return STPPaymentMethodCardWalletTypeUnknown;
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    STPPaymentMethodCardWallet *wallet = [self new];
    wallet.allResponseFields = dict;
    wallet.type = [self typeFromString:[dict stp_stringForKey:@"type"]];
    wallet.visaCheckout = [STPPaymentMethodCardWalletVisaCheckout decodedObjectFromAPIResponse:[response stp_dictionaryForKey:@"visa_checkout"]];
    wallet.masterpass = [STPPaymentMethodCardWalletMasterpass decodedObjectFromAPIResponse:[response stp_dictionaryForKey:@"masterpass"]];
    return wallet;
}

@end
