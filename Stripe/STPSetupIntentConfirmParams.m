//
//  STPSetupIntentConfirmParams.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPSetupIntentConfirmParams.h"
#import "STPSetupIntentConfirmParams+Utilities.h"

#import "STPMandateCustomerAcceptanceParams.h"
#import "STPMandateOnlineParams+Private.h"
#import "STPMandateDataParams.h"
#import "STPPaymentMethodParams.h"

@interface STPSetupIntentConfirmParams ()

@end

@implementation STPSetupIntentConfirmParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

- (instancetype)init {
    // Not a valid clientSecret, but at least it'll be non-null
    return [self initWithClientSecret:@""];
}

- (instancetype)initWithClientSecret:(NSString *)clientSecret {
    self = [super init];
    if (self) {
        _clientSecret = [clientSecret copy];
        _additionalAPIParameters = @{};
    }
    return self;
}

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // SetupIntentParams details (alphabetical)
                       [NSString stringWithFormat:@"clientSecret = %@", (self.clientSecret.length > 0) ? @"<redacted>" : @""],
                       [NSString stringWithFormat:@"returnURL = %@", self.returnURL],
                       [NSString stringWithFormat:@"paymentMethodId = %@", self.paymentMethodID],
                       [NSString stringWithFormat:@"paymentMethodParams = %@", self.paymentMethodParams],
                       [NSString stringWithFormat:@"useStripeSDK = %@", self.useStripeSDK],

                       // Mandate
                       [NSString stringWithFormat:@"mandateData = %@", self.mandateData],
                       [NSString stringWithFormat:@"mandate = %@", self.mandate],

                       // Additional params set by app
                       [NSString stringWithFormat:@"additionalAPIParameters = %@", self.additionalAPIParameters],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

- (STPMandateDataParams *)mandateData {
    BOOL paymentMethodRequiresMandate = self.paymentMethodParams.type == STPPaymentMethodTypeSEPADebit || self.paymentMethodParams.type == STPPaymentMethodTypeBacsDebit || self.paymentMethodParams.type == STPPaymentMethodTypeAUBECSDebit;
    
    if (_mandateData != nil) {
        return _mandateData;
    } else if (self.mandate == nil && paymentMethodRequiresMandate) {
        // Create default infer from client mandate_data
        STPMandateDataParams *mandateData = [[STPMandateDataParams alloc] init];
        STPMandateCustomerAcceptanceParams *customerAcceptance = [[STPMandateCustomerAcceptanceParams alloc] init];
        STPMandateOnlineParams *onlineParams = [[STPMandateOnlineParams alloc] init];
        onlineParams.inferFromClient = @YES;
        customerAcceptance.type = STPMandateCustomerAcceptanceTypeOnline;
        customerAcceptance.onlineParams = onlineParams;
        mandateData.customerAcceptance = customerAcceptance;

        return mandateData;
    } else {
        return nil;
    }
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    __typeof(self) copy = [[[self class] allocWithZone:zone] init];

    copy.clientSecret = self.clientSecret;
    copy.paymentMethodParams = self.paymentMethodParams;
    copy.paymentMethodID = self.paymentMethodID;
    copy.returnURL = self.returnURL;
    copy.useStripeSDK = self.useStripeSDK;
    copy.mandateData = self.mandateData;
    copy.mandate = self.mandate;
    copy.additionalAPIParameters = self.additionalAPIParameters;

    return copy;
}

#pragma mark - STPFormEncodable

+ (nullable NSString *)rootObjectName {
    return nil;
}

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(clientSecret)): @"client_secret",
             NSStringFromSelector(@selector(paymentMethodParams)): @"payment_method_data",
             NSStringFromSelector(@selector(paymentMethodID)): @"payment_method",
             NSStringFromSelector(@selector(returnURL)): @"return_url",
             NSStringFromSelector(@selector(useStripeSDK)): @"use_stripe_sdk",
             NSStringFromSelector(@selector(mandateData)): @"mandate_data",
             NSStringFromSelector(@selector(mandateData)) : @"mandate_data",
             NSStringFromSelector(@selector(mandate)) : @"mandate",
             };
}

#pragma mark - Utilities

+ (BOOL)isClientSecretValid:(NSString *)clientSecret {
    static dispatch_once_t onceToken;
    static NSRegularExpression *regex = nil;
    dispatch_once(&onceToken, ^{
        regex = [[NSRegularExpression alloc] initWithPattern:@"^seti_[^_]+_secret_[^_]+$"
                                                     options:0
                                                       error:NULL];
    });

    return ([regex numberOfMatchesInString:clientSecret
                                   options:NSMatchingAnchored
                                     range:NSMakeRange(0, clientSecret.length)]) == 1;
}

@end
