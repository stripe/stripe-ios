//
//  STPPaymentIntentParams.m
//  Stripe
//
//  Created by Daniel Jackson on 7/3/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPPaymentIntentParams.h"
#import "STPPaymentIntent+Private.h"

@implementation STPPaymentIntentParams

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

- (NSString *)stripeId {
    return [STPPaymentIntent idFromClientSecret:self.clientSecret];
}

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       // Identifier
                       [NSString stringWithFormat:@"stripeId = %@", self.stripeId],

                       // PaymentIntentParams details (alphabetical)
                       [NSString stringWithFormat:@"clientSecret = %@", (self.clientSecret.length > 0) ? @"<redacted>" : @""],
                       [NSString stringWithFormat:@"receiptEmail = %@", self.receiptEmail],
                       [NSString stringWithFormat:@"returnURL = %@", self.returnURL],
                       [NSString stringWithFormat:@"saveSourceToCustomer = %@", (self.saveSourceToCustomer.boolValue) ? @"YES" : @"NO"],
                       [NSString stringWithFormat:@"sourceId = %@", self.sourceId],
                       [NSString stringWithFormat:@"sourceParams = %@", self.sourceParams],

                       // Additional params set by app
                       [NSString stringWithFormat:@"additionalAPIParameters = %@", self.additionalAPIParameters],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - Deprecated Properties

- (NSString *)returnUrl {
    return self.returnURL;
}

- (void)setReturnUrl:(NSString *)returnUrl {
    self.returnURL = returnUrl;
}

#pragma mark - STPFormEncodable

+ (nullable NSString *)rootObjectName {
    return nil;
}

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(clientSecret)): @"client_secret",
             NSStringFromSelector(@selector(sourceParams)): @"source_data",
             NSStringFromSelector(@selector(sourceId)): @"source",
             NSStringFromSelector(@selector(receiptEmail)): @"receipt_email",
             NSStringFromSelector(@selector(saveSourceToCustomer)): @"save_source_to_customer",
             NSStringFromSelector(@selector(returnURL)): @"return_url",
             };
}

@end
