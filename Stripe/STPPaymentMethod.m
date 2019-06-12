//
//  STPPaymentMethod.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethod.h"

#import "NSDictionary+Stripe.h"
#import "STPImageLibrary.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentMethodBillingDetails.h"
#import "STPPaymentMethodCard.h"
#import "STPPaymentMethodCardPresent.h"
#import "STPPaymentMethodiDEAL.h"

@interface STPPaymentMethod ()

@property (nonatomic, copy, nullable, readwrite) NSString *stripeId;
@property (nonatomic, strong, nullable, readwrite) NSDate *created;
@property (nonatomic, readwrite) BOOL liveMode;
@property (nonatomic, readwrite) STPPaymentMethodType type;
@property (nonatomic, strong, nullable, readwrite) STPPaymentMethodBillingDetails *billingDetails;
@property (nonatomic, strong, nullable, readwrite) STPPaymentMethodCard *card;
@property (nonatomic, strong, nullable, readwrite) STPPaymentMethodiDEAL *iDEAL;
@property (nonatomic, strong, nullable, readwrite) STPPaymentMethodCardPresent *cardPresent;
@property (nonatomic, copy, nullable, readwrite) NSString *customerId;
@property (nonatomic, copy, nullable, readwrite) NSDictionary<NSString*, NSString *> *metadata;
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;

@end


@implementation STPPaymentMethod

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // Identifier
                       [NSString stringWithFormat:@"stripeId = %@", self.stripeId],
                       
                       // STPPaymentMethod details (alphabetical)
                       [NSString stringWithFormat:@"billingDetails = %@", self.billingDetails],
                       [NSString stringWithFormat:@"card = %@", self.card],
                       [NSString stringWithFormat:@"cardPresent = %@", self.cardPresent],
                       [NSString stringWithFormat:@"created = %@", self.created],
                       [NSString stringWithFormat:@"customerId = %@", self.customerId],
                       [NSString stringWithFormat:@"ideal = %@", self.iDEAL],
                       [NSString stringWithFormat:@"liveMode = %@", self.liveMode ? @"YES" : @"NO"],
                       [NSString stringWithFormat:@"metadata = %@", self.metadata],
                       [NSString stringWithFormat:@"type = %@", [self.allResponseFields stp_stringForKey:@"type"]],
                       ];
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPPaymentMethodType

+ (NSDictionary<NSString *,NSNumber *> *)stringToTypeMapping {
    return @{
             @"card": @(STPPaymentMethodTypeCard),
             @"ideal": @(STPPaymentMethodTypeiDEAL),
             @"card_present": @(STPPaymentMethodTypeCardPresent),
             };
}

+ (nullable NSString *)stringFromType:(STPPaymentMethodType)type {
    return [[[self stringToTypeMapping] allKeysForObject:@(type)] firstObject];
}

+ (STPPaymentMethodType)typeFromString:(NSString *)string {
    NSString *key = [string lowercaseString];
    NSNumber *typeNumber = [self stringToTypeMapping][key];
    
    if (typeNumber != nil) {
        return (STPPaymentMethodType)[typeNumber integerValue];
    }
    
    return STPPaymentMethodTypeUnknown;
}

+ (NSArray<NSNumber *> *)typesFromStrings:(NSArray<NSString *> *)strings {
    NSMutableArray *types = [NSMutableArray new];
    for (NSString *string in strings) {
        [types addObject:@([self typeFromString:string])];
    }
    return [types copy];
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    
    // Required fields
    NSString *stripeId = [dict stp_stringForKey:@"id"];
    if (!stripeId) {
        return nil;
    }
    
    STPPaymentMethod * paymentMethod = [self new];
    paymentMethod.allResponseFields = dict;
    paymentMethod.stripeId = stripeId;
    paymentMethod.created = [dict stp_dateForKey:@"created"];
    paymentMethod.liveMode = [dict stp_boolForKey:@"livemode" or:NO];
    paymentMethod.billingDetails = [STPPaymentMethodBillingDetails decodedObjectFromAPIResponse:[dict stp_dictionaryForKey:@"billing_details"]];
    paymentMethod.card = [STPPaymentMethodCard decodedObjectFromAPIResponse:[dict stp_dictionaryForKey:@"card"]];
    paymentMethod.type = [self typeFromString:[dict stp_stringForKey:@"type"]];
    paymentMethod.iDEAL = [STPPaymentMethodiDEAL decodedObjectFromAPIResponse:[dict stp_dictionaryForKey:@"ideal"]];
    paymentMethod.cardPresent = [STPPaymentMethodCardPresent decodedObjectFromAPIResponse:[dict stp_dictionaryForKey:@"card_present"]];
    paymentMethod.customerId = [dict stp_stringForKey:@"customer"];
    paymentMethod.metadata = [[dict stp_dictionaryForKey:@"metadata"] stp_dictionaryByRemovingNonStrings];
    return paymentMethod;
}

#pragma mark - STPPaymentOption

- (UIImage *)image {
    if (self.type == STPPaymentMethodTypeCard && self.card != nil) {
        return [STPImageLibrary brandImageForCardBrand:self.card.brand];
    } else {
        return [STPImageLibrary brandImageForCardBrand:STPCardBrandUnknown];
    }
}

- (UIImage *)templateImage {
    if (self.type == STPPaymentMethodTypeCard && self.card != nil) {
        return [STPImageLibrary templatedBrandImageForCardBrand:self.card.brand];
    } else {
        return [STPImageLibrary templatedBrandImageForCardBrand:STPCardBrandUnknown];
    }
}

- (NSString *)label {
    switch (self.type) {
        case STPPaymentMethodTypeCard:
            if (self.card != nil) {
                NSString *brand = STPStringFromCardBrand(self.card.brand);
                return [NSString stringWithFormat:@"%@ %@", brand, self.card.last4];
            } else {
                return STPStringFromCardBrand(STPCardBrandUnknown);
            }
        case STPPaymentMethodTypeiDEAL:
            return @"iDEAL";
        case STPPaymentMethodTypeCardPresent:
        case STPPaymentMethodTypeUnknown:
            return STPLocalizedString(@"Unknown", @"Default missing source type label");
    }
}

@end
