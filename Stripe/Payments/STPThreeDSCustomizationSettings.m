//
//  STPThreeDSCustomizationSettings.m
//  StripeiOS
//
//  Created by Cameron Sabol on 5/30/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPThreeDSCustomizationSettings.h"

#import "STPThreeDSUICustomization.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPThreeDSCustomizationSettings

- (instancetype)init {
    self = [super init];
    if (self) {
        _uiCustomization = [STPThreeDSUICustomization defaultSettings];
        _authenticationTimeout = 5;
    }
    return self;
}

+ (instancetype)defaultSettings {
    return [self new];
}

@end

NS_ASSUME_NONNULL_END
