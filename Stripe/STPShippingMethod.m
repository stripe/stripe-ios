//
//  STPShippingMethod.m
//  Stripe
//
//  Created by Ben Guo on 8/29/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPShippingMethod.h"
#import "NSDecimalNumber+Stripe_Currency.h"
#import "STPLocalizationUtils.h"

@interface STPShippingMethod ()
@property (nonatomic)NSNumberFormatter *numberFormatter;
@end

@implementation STPShippingMethod

- (instancetype)initWithAmount:(NSInteger)amount
                      currency:(nonnull NSString *)currency
                         label:(nonnull NSString *)label
                        detail:(nonnull NSString *)detail
                    identifier:(nonnull NSString *)identifier {
    self = [super init];
    if (self) {
        _amount = amount;
        _currency = [currency uppercaseString];
        _label = label;
        _detail = detail;
        _identifier = identifier;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithPKShippingMethod:(PKShippingMethod *)method currency:(NSString *)currency {
    self = [super init];
    if (self) {
        _amount = [method.amount stp_amountWithCurrency:currency];
        _currency = [currency uppercaseString];
        _label = method.label;
        _detail = method.detail;
        _identifier = method.identifier;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    NSMutableDictionary<NSString *,NSString *>*localeInfo = [@{NSLocaleCurrencyCode: self.currency} mutableCopy];
    localeInfo[NSLocaleLanguageCode] = [[NSLocale preferredLanguages] firstObject];
    NSString *localeID = [NSLocale localeIdentifierFromComponents:localeInfo];
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:localeID];
    formatter.locale = locale;
    formatter.usesGroupingSeparator = YES;
    _numberFormatter = formatter;
}

- (PKShippingMethod *)pkShippingMethod {
    PKShippingMethod *method = [[PKShippingMethod alloc] init];
    method.amount = [NSDecimalNumber stp_decimalNumberWithAmount:self.amount
                                                        currency:self.currency];
    method.label = self.label;
    method.detail = self.detail;
    method.identifier = self.identifier;
    return method;
}

- (NSString *)amountString {
    if (self.amount == 0) {
        return STPLocalizedString(@"Free", @"Label for free shipping method");
    }
    NSDecimalNumber *number = [NSDecimalNumber stp_decimalNumberWithAmount:self.amount
                                                                  currency:self.currency];
    return [self.numberFormatter stringFromNumber:number];
}

+ (NSArray<PKShippingMethod *>*)pkShippingMethods:(NSArray<STPShippingMethod *>*)methods selectedMethod:(STPShippingMethod *)selectedMethod {
    if (methods == nil || [methods count] == 0) {
        return @[];
    }
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:[methods count]];
    [methods enumerateObjectsUsingBlock:^(STPShippingMethod *method, __unused NSUInteger idx, __unused BOOL *stop) {
        if (selectedMethod == nil || ![method.identifier isEqualToString:selectedMethod.identifier]) {
            [results addObject:[method pkShippingMethod]];
        }
    }];
    if (selectedMethod != nil && [methods indexOfObject:selectedMethod] != NSNotFound) {
        [results insertObject:[selectedMethod pkShippingMethod] atIndex:0];
    }
    return results;
}

- (BOOL)isEqual:(id)other {
    return [self isEqualToShippingMethod:other];
}

- (NSUInteger)hash {
    return [self.identifier hash];
}

- (BOOL)isEqualToShippingMethod:(STPShippingMethod *)other {
    if (self == other) {
        return YES;
    }
    if (!other || ![other isKindOfClass:self.class]) {
        return NO;
    }
    return [self.identifier isEqualToString:other.identifier];
}

@end
