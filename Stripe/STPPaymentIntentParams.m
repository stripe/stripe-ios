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
        _clientSecret = clientSecret;
        _additionalAPIParameters = @{};
    }
    return self;
}

- (NSString *)stripeId {
    return [STPPaymentIntent idFromClientSecret:self.clientSecret];
}

// FIXME: override description

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
             NSStringFromSelector(@selector(returnUrl)): @"return_url",
             };
}

@end
