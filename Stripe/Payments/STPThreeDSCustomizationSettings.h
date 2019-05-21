//
//  STPThreeDSCustomizationSettings.h
//  StripeiOS
//
//  Created by Cameron Sabol on 5/30/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STDSUICustomization;

NS_ASSUME_NONNULL_BEGIN

/**
 
 */
@interface STPThreeDSCustomizationSettings : NSObject

/**
 Returns an `STPThreeDSCustomizationSettings` preconfigured with the default
 Stripe UI settings and a 10 minute `authenticationTimeout`.
 */
+ (instancetype)defaultSettings;

/**
 `uiCustomization` can be used to provide custom UI settings for the authentication
 challenge screens presented during a Three Domain Secure authentication. For more information see
 our guide on supporting 3DS2 in your iOS application.
 */
@property (nonatomic, nullable) STDSUICustomization *uiCustomization;

/**
 `authenticationTimeout` is the total time allowed for a user to complete a 3DS2 authentication
 interaction. This value *must* be at least 5 minutes.
 */
@property (nonatomic) NSTimeInterval authenticationTimeout;

@end

NS_ASSUME_NONNULL_END
