//
//  STPPaymentMethodType.m
//  Stripe
//
//  Created by Brian Dorfman on 3/14/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodType.h"
#import "STPPaymentMethodType+Private.h"

#import "STPImageLibrary+Private.h"
#import "STPImageLibrary.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentMethod.h"

/*
 Reusable payment methods types cannot be used directly at payment time
 (eg you cant pay with just "credit cards", it has to be a specific card.)

 Single Use payment methods types are allowed to be payment methods types.
 When the user attempts payment with one of these, we go create the source and
 replace the payment method on the STPPaymentContext with the specific
 created source
 */

#pragma mark - Reusable types

@interface STPPaymentMethodTypeCreditCard : STPPaymentMethodType
@end
@implementation STPPaymentMethodTypeCreditCard

- (UIImage *)paymentMethodImage {
    return [STPImageLibrary addIcon];
}

- (UIImage *)paymentMethodTemplateImage {
    return [STPImageLibrary addIcon];
}

- (NSString *)paymentMethodLabel {
    return STPLocalizedString(@"New Credit Card", @"Label for 'new credit card' payment method field") ;
}

- (BOOL)convertsToSourceAtSelection {
    return YES;
}

- (BOOL)canBeDefaultSource {
    return YES;
}

- (NSString *)analyticsString {
    return @"cards";
}

- (STPSourceType)sourceType {
    return STPSourceTypeCard;
}

@end

@interface STPPaymentMethodTypeSEPADebit : STPPaymentMethodType
@end
@implementation STPPaymentMethodTypeSEPADebit

- (UIImage *)paymentMethodImage {
    return [STPImageLibrary addIcon];
}

- (UIImage *)paymentMethodTemplateImage {
    return [STPImageLibrary addIcon];
}

- (NSString *)paymentMethodLabel {
    return STPLocalizedString(@"New SEPA Debit", @"Label for 'new sepa debit' payment method field") ;;
}

- (BOOL)convertsToSourceAtSelection {
    return YES;
}

- (BOOL)canBeDefaultSource {
    return YES;
}

- (NSString *)analyticsString {
    return @"sepadebit";
}

- (STPSourceType)sourceType {
    return STPSourceTypeSEPADebit;
}

@end

#pragma mark - Single use types

@interface STPPaymentMethodTypeApplePay : STPPaymentMethodType
@end
@implementation STPPaymentMethodTypeApplePay

- (UIImage *)paymentMethodImage {
    return [STPImageLibrary applePayCardImage];
}

- (UIImage *)paymentMethodTemplateImage {
    // No template for Apple Pay
    return [STPImageLibrary applePayCardImage];
}

- (NSString *)paymentMethodLabel {
    return STPLocalizedString(@"Apple Pay", @"Text for Apple Pay payment method");
}

- (NSString *)analyticsString {
    return @"apple_pay";
}

- (STPSourceType)sourceType {
    return STPSourceTypeUnknown;
}

@end

@interface STPPaymentMethodTypeBancontact : STPPaymentMethodType
@end
@implementation STPPaymentMethodTypeBancontact

- (UIImage *)paymentMethodImage {
    return nil;
}

- (UIImage *)paymentMethodTemplateImage {
    return nil;
}

- (NSString *)paymentMethodLabel {
    return STPLocalizedString(@"Bancontact", @"Text for Bancontact payment method");
}


- (NSString *)analyticsString {
    return @"bancontact";
}

- (STPSourceType)sourceType {
    return STPSourceTypeBancontact;
}

@end

@interface STPPaymentMethodTypeGiropay : STPPaymentMethodType
@end
@implementation STPPaymentMethodTypeGiropay

- (UIImage *)paymentMethodImage {
    return nil;
}

- (UIImage *)paymentMethodTemplateImage {
    return nil;
}

- (NSString *)paymentMethodLabel {
    return STPLocalizedString(@"Giropay", @"Text for Giropay payment method");;
}


- (NSString *)analyticsString {
    return @"giropay";
}

- (STPSourceType)sourceType {
    return STPSourceTypeGiropay;
}

@end

@interface STPPaymentMethodTypeIdeal : STPPaymentMethodType
@end
@implementation STPPaymentMethodTypeIdeal

- (UIImage *)paymentMethodImage {
    return nil;
}

- (UIImage *)paymentMethodTemplateImage {
    return nil;
}

- (NSString *)paymentMethodLabel {
    return STPLocalizedString(@"iDEAL", @"Text for iDEAL payment method");
}


- (NSString *)analyticsString {
    return @"ideal";
}

- (STPSourceType)sourceType {
    return STPSourceTypeIDEAL;
}

@end

@interface STPPaymentMethodTypeSofort : STPPaymentMethodType
@end
@implementation STPPaymentMethodTypeSofort

- (UIImage *)paymentMethodImage {
    return nil;
}

- (UIImage *)paymentMethodTemplateImage {
    return nil;
}

- (NSString *)paymentMethodLabel {
    return STPLocalizedString(@"SOFORT", @"Text for SOFORT payment method");
}

- (NSString *)analyticsString {
    return @"sofort";
}
- (STPSourceType)sourceType {
    return STPSourceTypeSofort;
}

@end

#pragma mark - Base class cluster

@implementation STPPaymentMethodType

+ (instancetype)creditCard {
    return [STPPaymentMethodTypeCreditCard new];
}

+ (instancetype)applePay {
    return [STPPaymentMethodTypeApplePay new];
}

+ (instancetype)bancontact {
    return [STPPaymentMethodTypeBancontact new];
}

+ (instancetype)giropay {
    return [STPPaymentMethodTypeGiropay new];
}

+ (instancetype)ideal {
    return [STPPaymentMethodTypeIdeal new];
}

+ (instancetype)sepaDebit {
    return [STPPaymentMethodTypeSEPADebit new];
}

+ (instancetype)sofort {
    return [STPPaymentMethodTypeSofort new];
}

- (UIImage *)paymentMethodImage {
    return nil;
}

- (UIImage *)paymentMethodTemplateImage {
    return nil;
}

- (NSString *)paymentMethodLabel {
    return nil;
}

- (BOOL)convertsToSourceAtSelection {
    return NO;
}

- (BOOL)canBeDefaultSource {
    return NO;
}

- (STPSourceType)sourceType {
    return STPSourceTypeUnknown;
}

- (NSString *)analyticsString {
    return @"unknown";
}

- (nullable STPPaymentMethodType *)paymentMethodType {
    return self;
}

- (BOOL)isEqual:(id)other {
    return [other isMemberOfClass:self.class];
}

- (NSUInteger)hash {
    return [self.class hash];
}

@end

