//
//  STPConfirmAlipayOptions.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 5/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPConfirmAlipayOptions.h"

#import "NSBundle+Stripe_AppName.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPConfirmAlipayOptions()
@end

@implementation STPConfirmAlipayOptions

@synthesize additionalAPIParameters;

- (NSString *)description {
    NSMutableArray *props = [@[
                               // Object
                               [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                               [NSString stringWithFormat:@"appBundleID = %@", self.appBundleID],
                               [NSString stringWithFormat:@"appVersionKey = %@", self.appVersionKey],
                               ] mutableCopy];


    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

- (NSString *)appBundleID {
    return[[NSBundle mainBundle] bundleIdentifier];
}

- (NSString *)appVersionKey {
    return [NSBundle stp_applicationVersion] ?: @"1.0.0"; // Should only be nil for tests
}

#pragma mark - STPFormEncodable

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
        NSStringFromSelector(@selector(appBundleID)): @"app_bundle_id",
        NSStringFromSelector(@selector(appVersionKey)): @"app_version_key",
    };
}

+ (nullable NSString *)rootObjectName {
    return @"alipay";
}

@end

NS_ASSUME_NONNULL_END
