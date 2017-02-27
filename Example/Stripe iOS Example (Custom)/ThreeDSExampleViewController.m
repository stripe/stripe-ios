//
//  Card3DSExampleViewController.m
//  Stripe iOS Example (Custom)
//
//  Created by Ben Guo on 2/22/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "ThreeDSExampleViewController.h"
#import "BrowseExamplesViewController.h"

/**
 This example demonstrates using Sources to accept card payments verified using 3D Secure. First, we
 create a Source using card information collected with STPPaymentCardTextField. If the card Source
 indicates that 3D Secure is required, we create a 3D Secure Source and redirect the user to authorize the payment. 
 Otherwise, we send the ID of the card Source to our example backend to create the charge request.
 
 Because 3D Secure payments require further action from the user, we don't tell our backend to create a charge 
 request after creating a 3D Secure Source. Instead, your backend should listen to the `source.chargeable` webhook 
 event to charge the 3D Secure source. See https://stripe.com/docs/sources#best-practices for more information.
 
 Note that support for 3D Secure is in preview, and must be activated in the dashboard in order 
 for this example to work. You can request an invite at https://dashboard.stripe.com/account/payments/settings
 */
@interface ThreeDSExampleViewController () <STPPaymentCardTextFieldDelegate>
@property (weak, nonatomic) STPPaymentCardTextField *paymentTextField;
@property (weak, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) STPSource *source;
@end

@implementation ThreeDSExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Card + 3DS";
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    STPPaymentCardTextField *paymentTextField = [[STPPaymentCardTextField alloc] init];
    STPCardParams *cardParams = [STPCardParams new];
    // Only successful 3D Secure transactions on this test card will succeed.
    cardParams.number = @"4000000000003063";
    paymentTextField.cardParams = cardParams;
    paymentTextField.delegate = self;
    paymentTextField.cursorColor = [UIColor purpleColor];
    self.paymentTextField = paymentTextField;
    [self.view addSubview:paymentTextField];

    NSString *title = @"Pay";
    UIBarButtonItem *payButton = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleDone target:self action:@selector(pay)];
    payButton.enabled = paymentTextField.isValid;
    self.navigationItem.rightBarButtonItem = payButton;

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator = activityIndicator;
    [self.view addSubview:activityIndicator];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.paymentTextField becomeFirstResponder];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat padding = 15;
    CGFloat width = CGRectGetWidth(self.view.frame) - (padding*2);
    CGRect bounds = self.view.bounds;
    self.paymentTextField.frame = CGRectMake(padding, padding, width, 44);
    self.activityIndicator.center = CGPointMake(CGRectGetMidX(bounds),
                                                CGRectGetMaxY(self.paymentTextField.frame) + padding*2);
}

- (void)presentPollingUI {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Waiting for payment authorization"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)dismissPollingUI {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)paymentCardTextFieldDidChange:(nonnull STPPaymentCardTextField *)textField {
    self.navigationItem.rightBarButtonItem.enabled = textField.isValid;
}

- (void)pay {
    if (![self.paymentTextField isValid]) {
        return;
    }
    if (![Stripe defaultPublishableKey]) {
        [self.delegate exampleViewController:self didFinishWithMessage:@"Please set a Stripe Publishable Key in Constants.m"];
        return;
    }
    [self.activityIndicator startAnimating];
    STPAPIClient *stripeClient = [STPAPIClient sharedClient];
    STPSourceParams *sourceParams = [STPSourceParams cardParamsWithCard:self.paymentTextField.cardParams];
    [stripeClient createSourceWithParams:sourceParams completion:^(STPSource *source, NSError *error) {
        if (source.cardDetails.threeDSecure == STPSourceCard3DSecureStatusRequired) {
            STPSourceParams *threeDSParams = [STPSourceParams threeDSecureParamsWithAmount:1099
                                                                                  currency:@"usd"
                                                                                 returnURL:@"payments-example://stripe-redirect"
                                                                                      card:source.stripeID];
            [stripeClient createSourceWithParams:threeDSParams completion:^(STPSource * source, NSError *error) {
                if (error) {
                    [self.delegate exampleViewController:self didFinishWithError:error];
                } else {
                    self.source = source;
                    [self presentPollingUI];
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
                    [[UIApplication sharedApplication] openURL:source.redirect.url];
                }
            }];
        } else {
            [self.delegate createBackendChargeWithSource:source.stripeID completion:^(STPBackendChargeResult status, NSError *error) {
                if (error) {
                    [self.delegate exampleViewController:self didFinishWithError:error];
                    return;
                }
                [self.delegate exampleViewController:self didFinishWithMessage:@"Payment successfully created"];
            }];
        }
    }];
}

- (void)handleAppForeground {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[STPAPIClient sharedClient] startPollingSourceWithId:self.source.stripeID
                                             clientSecret:self.source.clientSecret
                                                  timeout:10
                                               completion:^(STPSource *source, NSError *error) {
        [self dismissPollingUI];
        if (error) {
            [self.delegate exampleViewController:self didFinishWithError:error];
        } else {
            if (source.status == STPSourceStatusConsumed) {
                [self.delegate exampleViewController:self didFinishWithMessage:@"Payment successfully created"];
            } else if (source.status == STPSourceStatusFailed) {
                [self.delegate exampleViewController:self didFinishWithMessage:@"Payment failed"];
            } else {
                [self.delegate exampleViewController:self didFinishWithMessage:@"Order received"];
            }
        }
    }];
}

@end
