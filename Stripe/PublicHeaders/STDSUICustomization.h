//
//  STDSUICustomization.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/14/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STDSCustomization.h"
#import "STDSButtonCustomization.h"
#import "STDSNavigationBarCustomization.h"
#import "STDSLabelCustomization.h"
#import "STDSTextFieldCustomization.h"
#import "STDSFooterCustomization.h"
#import "STDSSelectionCustomization.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The `STDSUICustomization` provides configuration for UI elements.
 
 It's important to configure this object appropriately before using it to initialize a
 `STDSThreeDS2Service` object. `STDSThreeDS2Service` makes a copy of the customization
 settings you provide; it ignores any subsequent changes you make to your `STDSUICustomization` instance.
*/
@interface STDSUICustomization: NSObject <NSCopying>

/// The default settings.  See individual properties for their default values.
+ (instancetype)defaultSettings;

/**
 Provides custom settings for the UINavigationBar of all UIViewControllers the SDK display.
 The default is `[STDSNavigationBarCustomization defaultSettings]`.
 */
@property (nonatomic) STDSNavigationBarCustomization *navigationBarCustomization;

/**
 Provides custom settings for labels.
 The default is `[STDSLabelCustomization defaultSettings]`.
 */
@property (nonatomic) STDSLabelCustomization *labelCustomization;

/**
 Provides custom settings for text fields.
 The default is `[STDSTextFieldCustomization defaultSettings]`.
 */
@property (nonatomic) STDSTextFieldCustomization *textFieldCustomization;

/**
 The primary background color of all UIViewControllers the SDK display.
 Defaults to white.
 */
@property (nonatomic) UIColor *backgroundColor;

/**
 The Challenge view displays a footer with additional details.  This controls the background color of that view.
 Defaults to gray.
 */
@property (nonatomic) STDSFooterCustomization *footerCustomization;

/**
 Sets a given button customization for the specified type.
 
 @param buttonCustomization The buttom customization to use.
 @param buttonType The type of button to use the customization for.
 */
- (void)setButtonCustomization:(STDSButtonCustomization *)buttonCustomization forType:(STDSUICustomizationButtonType)buttonType;

/**
 Retrieves a button customization object for the given button type.

 @param buttonType The button type to retrieve a customization object for.
 @return A button customization object, or the default if none was set.
 @see STDSButtonCustomization
 */
- (STDSButtonCustomization *)buttonCustomizationForButtonType:(STDSUICustomizationButtonType)buttonType;

/**
 Provides custom settings for radio buttons and checkboxes.
 The default is `[STDSSelectionCustomization defaultSettings]`.
 */
@property (nonatomic) STDSSelectionCustomization *selectionCustomization;


/**
 The preferred status bar style for all UIViewControllers the SDK display.
 Defaults to UIStatusBarStyleDefault.
 */
@property (nonatomic) UIStatusBarStyle preferredStatusBarStyle;

#pragma mark - Progress View

/**
 The style of UIActivityIndicatorViews displayed.
 This should contrast with `backgroundColor`.  Defaults to gray.
 */
@property (nonatomic) UIActivityIndicatorViewStyle activityIndicatorViewStyle;

/**
 The style of the UIBlurEffect displayed underneath the UIActivityIndicatorView.
 Defaults to UIBlurEffectStyleLight.
 */
@property (nonatomic) UIBlurEffectStyle blurStyle;

@end

NS_ASSUME_NONNULL_END
