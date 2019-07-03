//
//  STPSetupIntentConfirmParams.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPSetupIntentConfirmParams.h"

@implementation STPSetupIntentConfirmParams

@synthesize additionalAPIParameters = _additionalAPIParameters;

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
                       
                       // Additional params set by app
                       [NSString stringWithFormat:@"additionalAPIParameters = %@", self.additionalAPIParameters],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
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
             };
}

@end
