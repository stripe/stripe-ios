//
//  UIViewController+Stripe3DS2.m
//  Stripe3DS2
//
//  Created by Yuki Tokuhiro on 5/6/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "UIViewController+Stripe3DS2.h"

#import "STDSVisionSupport.h"
#import "UIButton+CustomInitialization.h"
#import "STDSUICustomization.h"

@implementation UIViewController (Stripe3DS2)

- (void)_stds_setupNavigationBarElementsWithCustomization:(STDSUICustomization *)customization cancelButtonSelector:(SEL)cancelButtonSelector {
    STDSNavigationBarCustomization *navigationBarCustomization = customization.navigationBarCustomization;
    
    self.navigationController.navigationBar.barStyle = customization.navigationBarCustomization.barStyle;

    // Cancel button
    STDSButtonCustomization *cancelButtonCustomization = [customization buttonCustomizationForButtonType:STDSUICustomizationButtonTypeCancel];
    UIButton *cancelButton = [UIButton _stds_buttonWithTitle:navigationBarCustomization.buttonText customization:cancelButtonCustomization];
    // Keep the title on a single line. Because this is a custom view in a bar button item, the
    // navigation bar won't size it for us and we set an explicit frame below; without this the
    // title can wrap to two lines (e.g. on iOS 26+ when the glass configuration adds padding).
    cancelButton.titleLabel.numberOfLines = 1;
    cancelButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    cancelButton.accessibilityIdentifier = @"Cancel";
    [cancelButton addTarget:self action:cancelButtonSelector forControlEvents:UIControlEventTouchUpInside];
#if defined(__IPHONE_26_0) && !STP_TARGET_VISION
    if (@available(iOS 26, *)) {
        cancelButton.configuration = UIButtonConfiguration.glassButtonConfiguration;
    }
#endif
    // Size the button after applying the final configuration so the frame accounts for the
    // configuration's content insets. (The cancel button's frame has a size of 0 in iOS 8.)
    cancelButton.frame = CGRectMake(0, 0, cancelButton.intrinsicContentSize.width, cancelButton.intrinsicContentSize.height);
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
    
    if (navigationBarCustomization.scrollEdgeAppearance) {
        self.navigationController.navigationBar.scrollEdgeAppearance = navigationBarCustomization.scrollEdgeAppearance;
    }
}

@end
