//
//  STPCoreViewController.m
//  Stripe
//
//  Created by Brian Dorfman on 1/6/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCoreViewController.h"
#import "STPCoreViewController+Private.h"

#import "STPColorUtils.h"
#import "STPLocalizationUtils.h"
#import "STPTheme.h"
#import "UIBarButtonItem+Stripe.h"
#import "UINavigationBar+Stripe_Theme.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"
#import "UIViewController+Stripe_ParentViewController.h"

// Note:
// The private class extension for this class is in
// STPCoreViewController+Private.h

@implementation STPCoreViewController

- (instancetype)init {
    return [self initWithTheme:[STPTheme defaultTheme]];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInitWithTheme:[STPTheme defaultTheme]];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInitWithTheme:[STPTheme defaultTheme]];
    }
    return self;
}

- (instancetype)initWithTheme:(STPTheme *)theme {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self commonInitWithTheme:theme];
    }
    return self;
}

- (void)commonInitWithTheme:(STPTheme *)theme {
    _theme = theme;

    if (![self useSystemBackButton]) {
        self.cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                        target:self
                                                                        action:@selector(handleCancelTapped:)];

        self.stp_navigationItemProxy.leftBarButtonItem = self.cancelItem;
    }
}

- (void)setTheme:(STPTheme *)theme {
    _theme = theme;
    [self updateAppearance];
}

- (void)createAndSetupViews {
    // do nothing
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self createAndSetupViews];
    [self updateAppearance];
}

- (void)updateAppearance {
    STPTheme *navBarTheme = self.navigationController.navigationBar.stp_theme ?: self.theme;
    [self.navigationItem.leftBarButtonItem stp_setTheme:navBarTheme];
    [self.navigationItem.rightBarButtonItem stp_setTheme:navBarTheme];
    [self.cancelItem stp_setTheme:navBarTheme];

    self.view.backgroundColor = self.theme.primaryBackgroundColor;

    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    STPTheme *navBarTheme = self.navigationController.navigationBar.stp_theme ?: self.theme;
    return ([STPColorUtils colorIsBright:navBarTheme.secondaryBackgroundColor]
            ? UIStatusBarStyleDefault
            : UIStatusBarStyleLightContent);
}

- (void)handleCancelTapped:(__unused id)sender {
    if ([self stp_isAtRootOfNavigationController]) {
        // if we're the root of the navigation controller, we've been presented modally.
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];

    } else {
        // otherwise, we've been pushed onto the stack.
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (BOOL)useSystemBackButton {
    return NO;
}

@end
