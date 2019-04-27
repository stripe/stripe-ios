//
//  STPConnectIndividualAccountParams.m
//  Stripe
//
//  Created by Peter Suwara on 27/4/19.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPConnectIndividualAccountParams.h"

#import "STPIndividualParams.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPConnectIndividualAccountParams

@synthesize additionalAPIParameters;

- (instancetype)initWithTosShownAndAccepted:(BOOL)wasAccepted
                               businessType:(NSString *)businessType
                                 individual:(STPIndividualParams *)individual {
    // It is an error to call this method with wasAccepted == NO
    NSParameterAssert(wasAccepted == YES);
    self = [super init];
    if (self) {
        _tosShownAndAccepted = @(wasAccepted);
        _businessType = businessType;
        _individual = individual;
    }
    return self;
}

- (instancetype)initWithIndividual:(STPIndividualParams *)individual {
    self = [super init];
    if (self) {
        _tosShownAndAccepted = nil;
        _businessType = @"individual";
        _individual = individual;
    }
    return self;
}

#pragma mark - description

- (NSString *)description {
    NSArray *props = @[
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       // We use NSParameterAssert to block this being NO:
                       [NSString stringWithFormat:@"tosShownAndAccepted = %@",
                        self.tosShownAndAccepted != nil ? @"YES" : @"<nil>"],
                       [NSString stringWithFormat:@"individual = %@", self.individual.description],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPFormEncodable

+ (nullable NSString *)rootObjectName {
    return @"account";
}

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(tosShownAndAccepted)): @"tos_shown_and_accepted",
             NSStringFromSelector(@selector(individual)): @"individual",
             NSStringFromSelector(@selector(businessType)): @"business_type",
             };
}

@end

NS_ASSUME_NONNULL_END

