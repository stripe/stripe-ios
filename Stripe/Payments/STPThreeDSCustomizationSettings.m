//
//  STPThreeDSCustomizationSettings.m
//  StripeiOS
//
//  Created by Cameron Sabol on 5/30/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPThreeDSCustomizationSettings.h"

#import <Stripe3DS2/Stripe3DS2.h>

NS_ASSUME_NONNULL_BEGIN

@implementation STPThreeDSCustomizationSettings

+ (instancetype)defaultSettings {
    STPThreeDSCustomizationSettings *settings = [[STPThreeDSCustomizationSettings alloc] init];
    settings.uiCustomization = [STDSUICustomization defaultSettings];
    settings.authenticationTimeout = 10*60;
}

@end

NS_ASSUME_NONNULL_END
