//
//  STPThreeDSUICustomization.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPThreeDSButtonCustomization.h"
#import "STPThreeDSFooterCustomization.h"
#import "STPThreeDSLabelCustomization.h"
#import "STPThreeDSNavigationBarCustomization.h"
#import "STPThreeDSSelectionCustomization.h"
#import "STPThreeDSTextFieldCustomization.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The `STPThreeDSUICustomization` provides configuration for UI elements displayed during 3D Secure authentication.
 
 Note: It's important to configure this object appropriately before calling any `STPPaymentHandler` APIs.
 The API makes a copy of the customization settings you provide; it ignores any subsequent changes you
 make to your `STPThreeDSUICustomization` instance.
 
 @see https://stripe.com/docs/mobile/ios/authentication
 */
@interface STPThreeDSUICustomization : NSObject

/// The default settings.  See individual properties for their default values.
+ (instancetype)defaultSettings;

/**
 Provides custom settings for the UINavigationBar of all UIViewControllers displayed during 3D Secure authentication.
 The default is `[STPThreeDSNavigationBarCustomization defaultSettings]`.
 */
@property (nonatomic, strong) STPThreeDSNavigationBarCustomization *navigationBarCustomization;

/**
 Provides custom settings for labels.
 The default is `[STPThreeDSLabelCustomization defaultSettings]`.
 */
@property (nonatomic, strong) STPThreeDSLabelCustomization *labelCustomization;

/**
 Provides custom settings for text fields.
 The default is `[STPThreeDSTextFieldCustomization defaultSettings]`.
 */
@property (nonatomic) STPThreeDSTextFieldCustomization *textFieldCustomization;

/**
 The primary background color of all UIViewControllers displayed during 3D Secure authentication.
 Defaults to white.
 */
@property (nonatomic) UIColor *backgroundColor;

/**
 Provides custom settings for the footer the challenge view can display containing additional details.
 The default is `[STPThreeDSFooterCustomization defaultSettings]`.
 */
@property (nonatomic, strong) STPThreeDSFooterCustomization *footerCustomization;

/**
 Sets a given button customization for the specified type.

 @param buttonCustomization The buttom customization to use.
 @param buttonType The type of button to use the customization for.
 */
- (void)setButtonCustomization:(STPThreeDSButtonCustomization *)buttonCustomization forType:(STPThreeDSCustomizationButtonType)buttonType;

/**
 Retrieves a button customization object for the given button type.

 @param buttonType The button type to retrieve a customization object for.
 @return A button customization object, or the default if none was set.
 @see STPThreeDSButtonCustomization
 */
- (STPThreeDSButtonCustomization *)buttonCustomizationForButtonType:(STPThreeDSCustomizationButtonType)buttonType;

/**
 Provides custom settings for radio buttons and checkboxes.
 The default is `[STPThreeDSSelectionCustomization defaultSettings]`.
 */
@property (nonatomic, strong) STPThreeDSSelectionCustomization *selectionCustomization;

#pragma mark - Progress View

/**
 The style of `UIActivityIndicatorView`s displayed.
 This should contrast with `backgroundColor`.  Defaults to gray.
 */
@property (nonatomic) UIActivityIndicatorViewStyle activityIndicatorViewStyle;

/**
 The style of the `UIBlurEffect` displayed underneath the `UIActivityIndicatorView`.
 Defaults to `UIBlurEffectStyleLight`.
 */
@property (nonatomic) UIBlurEffectStyle blurStyle;
@end

NS_ASSUME_NONNULL_END
