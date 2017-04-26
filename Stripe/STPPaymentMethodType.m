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
 (eg you cant pay with just "cards", it has to be a specific card.)

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
    return [STPImageLibrary cardIcon];
}

- (UIImage *)paymentMethodTemplateImage {
    return [STPImageLibrary cardIcon];
}

- (NSString *)paymentMethodLabel {
    return STPLocalizedString(@"New Card", @"Label for button to add a new credit or debit card") ;
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
    return [STPImageLibrary sepaIcon];
}

- (UIImage *)paymentMethodTemplateImage {
    return [STPImageLibrary sepaIcon];
}

- (NSString *)paymentMethodLabel {
    return STPLocalizedString(@"New Direct Debit Account", @"Label for button to add a new SEPA Direct Debit account") ;;
}

- (NSString *)paymentMethodAccessibilityLabel {
    return STPLocalizedString(@"New SEPA Direct Debit Account", @"Accessibility label for button to add a new SEPA Direct Debit account");
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
    return @"Apple Pay"; // brand name, doesn't need to be localized
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
    return [STPImageLibrary bancontactIcon];
}

- (UIImage *)paymentMethodTemplateImage {
    return [STPImageLibrary bancontactIcon];
}

- (NSString *)paymentMethodLabel {
    return @"Bancontact"; // brand name, doesn't need to be localized
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
    return [STPImageLibrary giropayIcon];
}

- (UIImage *)paymentMethodTemplateImage {
    return [STPImageLibrary giropayIcon];
}

- (NSString *)paymentMethodLabel {
    return @"Giropay"; // brand name, doesn't need to be localized
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
    return [STPImageLibrary idealIcon];
}

- (UIImage *)paymentMethodTemplateImage {
    return [STPImageLibrary idealIcon];
}

- (NSString *)paymentMethodLabel {
    return @"iDEAL"; // brand name, doesn't need to be localized
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
    return [STPImageLibrary sofortIcon];
}

- (UIImage *)paymentMethodTemplateImage {
    return [STPImageLibrary sofortIcon];
}

- (NSString *)paymentMethodLabel {
    return @"SOFORT"; // brand name, doesn't need to be localized
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

+ (instancetype)card {
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

- (NSString *)paymentMethodAccessibilityLabel {
    return self.paymentMethodLabel;
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

