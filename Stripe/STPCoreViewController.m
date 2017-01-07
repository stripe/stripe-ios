//
//  STPCoreViewController.m
//  Stripe
//
//  Created by Brian Dorfman on 1/6/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCoreViewController.h"

#import "STPColorUtils.h"
#import "STPLocalizationUtils.h"
#import "STPTheme.h"
#import "UIBarButtonItem+Stripe.h"
#import "UINavigationBar+Stripe_Theme.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"
#import "UIViewController+Stripe_ParentViewController.h"


@interface STPCoreViewController ()
@property(nonatomic) UIBarButtonItem *cancelItem;
@property(nonatomic) UIBarButtonItem *backItem;
@end

@implementation STPCoreViewController

- (instancetype)init {
    return [self initWithTheme:[STPTheme defaultTheme]];
}

- (instancetype)initWithTheme:(STPTheme *)theme {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _theme = theme;
        self.backItem = [UIBarButtonItem stp_backButtonItemWithTitle:STPLocalizedString(@"Back", @"Text for back button")
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(handleBackOrCancelTapped:)];
        self.cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                        target:self
                                                                        action:@selector(handleBackOrCancelTapped:)];

        self.stp_navigationItemProxy.leftBarButtonItem = self.cancelItem;
    }
    return self;
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
    [self.backItem stp_setTheme:navBarTheme];
    [self.cancelItem stp_setTheme:navBarTheme];

    self.view.backgroundColor = self.theme.primaryBackgroundColor;

    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (![self stp_isAtRootOfNavigationController]) {
        self.stp_navigationItemProxy.leftBarButtonItem = self.backItem;
    }
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

- (void)handleBackOrCancelTapped:(__unused id)sender {
    if ([self stp_isAtRootOfNavigationController]) {
        // if we're the root of the navigation controller, we've been presented modally.
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];

    } else {
        // otherwise, we've been pushed onto the stack.
        [self.navigationController popViewControllerAnimated:YES];
    }
}


@end
