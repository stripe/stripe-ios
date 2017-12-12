//
//  VisaCheckoutExampleViewController.m
//  Custom Integration (ObjC)
//
//  Copyright © 2017 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "VisaCheckoutExampleViewController.h"
#import "BrowseExamplesViewController.h"

#import <VisaCheckoutSDK/VisaCheckout.h>

NSString *const VisaCheckoutAPIKey = nil; // TODO: replace nil with your own value

@interface VisaCheckoutExampleViewController ()
@property (nonatomic, weak) VisaCheckoutButton *payButton;
@property (nonatomic, weak) UILabel *waitingLabel;
@property (nonatomic, weak) UIActivityIndicatorView *activityIndicator;
@end

@implementation VisaCheckoutExampleViewController

+ (void)initialize {
    if (self == [VisaCheckoutExampleViewController class]
        && VisaCheckoutAPIKey != nil) {
        [VisaCheckoutSDK configureWithEnvironment:VisaEnvironmentSandbox
                                           apiKey:VisaCheckoutAPIKey ?: @""
                                      profileName:nil
                                           result:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (![Stripe defaultPublishableKey]) {
        [self.delegate exampleViewController:self didFinishWithMessage:@"Please set a Stripe Publishable Key in Constants.m"];
        return;
    }

    if (!VisaCheckoutAPIKey) {
        [self.delegate exampleViewController:self didFinishWithMessage:@"Please set a Visa Checkout API Key in VisaCheckoutExampleViewController.m"];
        return;
    }

    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Visa Checkout";
    self.edgesForExtendedLayout = UIRectEdgeNone;

    VisaCheckoutButton *button = [VisaCheckoutButton new];
    [button sizeToFit];
    __weak VisaCheckoutExampleViewController *weak_self = self;
    [button onCheckoutWithTotal:[[VisaCurrencyAmount alloc] initWithIntegerLiteral:500]
                       currency:VisaCurrencyUsd
                     completion:^(VisaCheckoutResult * _Nonnull result) {
                         [weak_self handleVisaCheckoutResult:result];
                     }];
    self.payButton = button;
    [self.view addSubview:button];

    UILabel *label = [UILabel new];
    label.text = @"Waiting for payment authorization";
    [label sizeToFit];
    label.textColor = [UIColor grayColor];
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
    self.payButton.center = CGPointMake(CGRectGetMidX(bounds), 100);
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

- (void)handleVisaCheckoutResult:(VisaCheckoutResult *)result {
    [self updateUIForPaymentInProgress:YES];
    STPSourceParams *sourceParams = [STPSourceParams visaCheckoutParamsWithCallId:result.callId];
    [[STPAPIClient sharedClient] createSourceWithParams:sourceParams completion:^(STPSource *source, NSError *error) {
        if (error) {
            [self.delegate exampleViewController:self didFinishWithError:error];
        } else {
            [self.delegate createBackendChargeWithSource:source.stripeID completion:^(STPBackendChargeResult status, NSError *error) {
                [self updateUIForPaymentInProgress:NO];
                if (error) {
                    [self.delegate exampleViewController:self didFinishWithError:error];
                    return;
                }
                [self.delegate exampleViewController:self didFinishWithMessage:@"Payment successfully created"];
            }];
        }
    }];
}

@end
