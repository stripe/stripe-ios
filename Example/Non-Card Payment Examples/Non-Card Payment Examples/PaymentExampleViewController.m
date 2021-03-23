//
//  PaymentExampleViewController.m
//  Non-Card Payment Examples
//
//  Created by Cameron Sabol on 10/7/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "PaymentExampleViewController.h"

@interface PaymentExampleViewController ()

@end

@implementation PaymentExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
    }
#endif
    self.title = @"Payment Example";
    self.edgesForExtendedLayout = UIRectEdgeNone;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Pay" forState:UIControlStateNormal];
    [button sizeToFit];
    [button addTarget:self action:@selector(payButtonSelected) forControlEvents:UIControlEventTouchUpInside];
    self.payButton = button;
    [self.view addSubview:button];

    UILabel *label = [UILabel new];
    label.text = @"Waiting for payment authorization";
    [label sizeToFit];
    label.textColor = [UIColor grayColor];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        label.textColor = [UIColor secondaryLabelColor];
    }
#endif
    label.alpha = 0;
    [self.view addSubview:label];
    self.waitingLabel = label;

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator = activityIndicator;
    [self.view addSubview:activityIndicator];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat padding = 15;
    CGRect bounds = self.view.bounds;
    self.payButton.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetHeight(bounds)/3.0);
    self.activityIndicator.center = CGPointMake(CGRectGetMidX(bounds),
                                                CGRectGetMaxY(self.payButton.frame) + padding*2);
    self.waitingLabel.center = CGPointMake(CGRectGetMidX(bounds),
                                           CGRectGetMaxY(self.activityIndicator.frame) + padding*2);
}

- (void)updateUIForPaymentInProgress:(BOOL)paymentInProgress {
    self.navigationController.navigationBar.userInteractionEnabled = !paymentInProgress;
    self.payButton.enabled = !paymentInProgress;
    [UIView animateWithDuration:0.2 animations:^{
        self.waitingLabel.alpha = paymentInProgress ? 1 : 0;
    }];
    if (paymentInProgress) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
}

- (void)payButtonSelected {
    if (![StripeAPI defaultPublishableKey]) {
        [self.delegate exampleViewController:self didFinishWithMessage:@"Please set a Stripe Publishable Key in Constants.m"];
        return;
    }
    // no-op, to be implemented by subclasses
}


#pragma mark - STPAuthenticationContext

- (UIViewController *)authenticationPresentingViewController {
    return self.navigationController.topViewController;
}

- (void)authenticationContextWillDismissViewController:(UIViewController *)viewController {
    // no-op, to be implemented by subclasses as needed
}

@end
