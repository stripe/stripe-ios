//
//  STPConnectAccountParams.m
//  Stripe
//
//  Created by Daniel Jackson on 1/4/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPConnectAccountParams.h"

#import "STPLegalEntityParams.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPConnectAccountParams

@synthesize additionalAPIParameters;

- (instancetype)initWithTosShownAndAccepted:(BOOL)wasAccepted
                                legalEntity:(STPLegalEntityParams *)legalEntity {
    // It is an error to call this method with wasAccepted == NO
    NSParameterAssert(wasAccepted == YES);
    self = [super init];
    if (self) {
        _tosShownAndAccepted = @(wasAccepted);
        _legalEntity = legalEntity;
    }
    return self;
}

- (instancetype)initWithLegalEntity:(STPLegalEntityParams *)legalEntity {
    self = [super init];
    if (self) {
        _tosShownAndAccepted = nil;
        _legalEntity = legalEntity;
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
                       [NSString stringWithFormat:@"legalEntity = %@", self.legalEntity.description],
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
             NSStringFromSelector(@selector(legalEntity)): @"legal_entity",
             };
}

@end

NS_ASSUME_NONNULL_END
