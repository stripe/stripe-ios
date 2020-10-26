//
//  STPConnectAccountAddress.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 8/2/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPConnectAccountAddress.h"

@implementation STPConnectAccountAddress

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // Properties
                       [NSString stringWithFormat:@"line1 = %@", self.line1],
                       [NSString stringWithFormat:@"line2 = %@", self.line2],
                       [NSString stringWithFormat:@"town = %@", self.town],
                       [NSString stringWithFormat:@"city = %@", self.city],
                       [NSString stringWithFormat:@"state = %@", self.state],
                       [NSString stringWithFormat:@"postalCode = %@", self.postalCode],
                       [NSString stringWithFormat:@"country = %@", self.country],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPFormEncodable

@synthesize additionalAPIParameters;

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(line1)): @"line1",
             NSStringFromSelector(@selector(line2)): @"line2",
             NSStringFromSelector(@selector(town)): @"town",
             NSStringFromSelector(@selector(city)): @"city",
             NSStringFromSelector(@selector(country)): @"country",
             NSStringFromSelector(@selector(state)): @"state",
             NSStringFromSelector(@selector(postalCode)): @"postal_code",
             };
}

+ (nullable NSString *)rootObjectName {
    return nil;
}

@end
