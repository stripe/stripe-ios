//
//  UIViewController+Stripe3DS2.m
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 5/6/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "UIViewController+Stripe3DS2.h"

#import "UIButton+CustomInitialization.h"
#import "STDSUICustomization.h"

@implementation UIViewController (Stripe3DS2)

- (void)_stds_setupNavigationBarElementsWithCustomization:(STDSUICustomization *)customization cancelButtonSelector:(SEL)cancelButtonSelector {
    STDSNavigationBarCustomization *navigationBarCustomization = customization.navigationBarCustomization;
    
    self.navigationController.navigationBar.barStyle = customization.navigationBarCustomization.barStyle;

    // Cancel button
    STDSButtonCustomization *cancelButtonCustomization = [customization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeCancel];
    UIButton *cancelButton = [UIButton _stds_buttonWithTitle:navigationBarCustomization.buttonText customization:cancelButtonCustomization];
    // The cancel button's frame has a size of 0 in iOS 8
    cancelButton.frame = CGRectMake(0, 0, cancelButton.intrinsicContentSize.width, cancelButton.intrinsicContentSize.height);
    cancelButton.accessibilityIdentifier = @"Cancel";
    [cancelButton addTarget:self action:cancelButtonSelector forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
    self.navigationItem.rightBarButtonItem = cancelBarButtonItem;
    
    // Title
    self.title = navigationBarCustomization.headerText;
    NSMutableDictionary *titleTextAttributes = [NSMutableDictionary dictionary];
    UIFont *headerFont = navigationBarCustomization.font;
    if (headerFont) {
        titleTextAttributes[NSFontAttributeName] = headerFont;
    }
    UIColor *headerColor = navigationBarCustomization.textColor;
    if (headerColor) {
        titleTextAttributes[NSForegroundColorAttributeName] = headerColor;
    }
    self.navigationController.navigationBar.titleTextAttributes = titleTextAttributes;
    
    // Color
    self.navigationController.navigationBar.barTintColor = navigationBarCustomization.barTintColor;
    self.navigationController.navigationBar.translucent = navigationBarCustomization.translucent;
}

@end

void _stds_import_uiviewcontroller_stripe3ds2() {}
