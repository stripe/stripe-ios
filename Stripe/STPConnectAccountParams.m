//
//  STPConnectAccountParams.m
//  Stripe
//
//  Created by Daniel Jackson on 1/4/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPConnectAccountParams.h"

#import "STPConnectAccountIndividualParams.h"
#import "STPConnectAccountCompanyParams.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPConnectAccountParams

@synthesize additionalAPIParameters;

- (instancetype)initWithTosShownAndAccepted:(BOOL)wasAccepted
                                 individual:(STPConnectAccountIndividualParams *)individual {
    // It is an error to call this method with wasAccepted == NO
    NSParameterAssert(wasAccepted == YES);
    self = [super init];
    if (self) {
        _tosShownAndAccepted = @(wasAccepted);
        _individual = individual;
        _businessType = STPConnectAccountBusinessTypeIndividual;
    }
    return self;
}

- (instancetype)initWithTosShownAndAccepted:(BOOL)wasAccepted
                                    company:(STPConnectAccountCompanyParams *)company {
    // It is an error to call this method with wasAccepted == NO
    NSParameterAssert(wasAccepted == YES);
    self = [super init];
    if (self) {
        _tosShownAndAccepted = @(wasAccepted);
        _company = company;
        _businessType = STPConnectAccountBusinessTypeCompany;
    }
    return self;
}

- (instancetype)initWithIndividual:(STPConnectAccountIndividualParams *)individual {
    self = [super init];
    if (self) {
        _tosShownAndAccepted = nil;
        _individual = individual;
        _businessType = STPConnectAccountBusinessTypeIndividual;
    }
    return self;
}

- (instancetype)initWithCompany:(STPConnectAccountCompanyParams *)company {
    self = [super init];
    if (self) {
        _tosShownAndAccepted = nil;
        _company = company;
        _businessType = STPConnectAccountBusinessTypeCompany;
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
                       [NSString stringWithFormat:@"individual = %@", self.individual],
                       [NSString stringWithFormat:@"company = %@", self.company],
                       [NSString stringWithFormat:@"business_type = %@", [[self class] stringFromBusinessType: self.businessType]],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPConnectAccountBusinessType

+ (NSString *)stringFromBusinessType:(STPConnectAccountBusinessType)businessType {
    switch (businessType) {
    case STPConnectAccountBusinessTypeIndividual:
        return @"individual";
    case STPConnectAccountBusinessTypeCompany:
        return @"company";
    }
}

#pragma mark - STPFormEncodable

+ (nullable NSString *)rootObjectName {
    return @"account";
}

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(tosShownAndAccepted)): @"tos_shown_and_accepted",
             NSStringFromSelector(@selector(individual)): @"individual",
             NSStringFromSelector(@selector(company)): @"company",
             NSStringFromSelector(@selector(businessTypeString)): @"business_type",
             };
}

- (NSString *)businessTypeString {
    return [[self class] stringFromBusinessType:self.businessType];
}

@end

NS_ASSUME_NONNULL_END
