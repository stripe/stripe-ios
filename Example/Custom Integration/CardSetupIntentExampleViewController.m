//
//  CardSetupIntentExampleViewController.m
//  Custom Integration
//
//  Created by Yuki Tokuhiro on 7/1/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

@import Stripe;

#import "CardSetupIntentExampleViewController.h"
#import "BrowseExamplesViewController.h"

/**
 This example demonstrates using SetupIntents to accept card payments verified using 3D Secure.
 
 1. Collect user's card information via `STPPaymentCardTextField`
 2. Create a `SetupIntent` on our backend (this can happen concurrently with #1)
 3. Confirm SetupIntent with `STPPaymentHandler`, using the `STPPaymentMethodParams` for the user's card information.
 */
@interface CardSetupIntentExampleViewController () <STPPaymentCardTextFieldDelegate>

@property (weak, nonatomic) STPPaymentCardTextField *paymentTextField;
@property (weak, nonatomic) UILabel *waitingLabel;
@property (weak, nonatomic) UIActivityIndicatorView *activityIndicator;

@end

@implementation CardSetupIntentExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    #ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
    }
    #endif
    self.title = @"Card";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    STPPaymentCardTextField *paymentTextField = [[STPPaymentCardTextField alloc] init];
    STPPaymentMethodCardParams *cardParams = [STPPaymentMethodCardParams new];
    // Only successful 3D Secure transactions on this test card will succeed.
    cardParams.number = @"4000000000003063";
    paymentTextField.cardParams = cardParams;
    paymentTextField.delegate = self;
    paymentTextField.cursorColor = [UIColor purpleColor];
    #ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        paymentTextField.cursorColor = [UIColor systemPurpleColor];
    }
    #endif
    self.paymentTextField = paymentTextField;
    [self.view addSubview:paymentTextField];
    
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
    self.waitingLabel.center = CGPointMake(CGRectGetMidX(bounds),
                                           CGRectGetMaxY(self.activityIndicator.frame) + padding*2);
}

- (void)updateUIForPaymentInProgress:(BOOL)paymentInProgress {
    self.navigationController.navigationBar.userInteractionEnabled = !paymentInProgress;
    self.navigationItem.rightBarButtonItem.enabled = !paymentInProgress;
    self.paymentTextField.userInteractionEnabled = !paymentInProgress;
    [UIView animateWithDuration:0.2 animations:^{
        self.waitingLabel.alpha = paymentInProgress ? 1 : 0;
    }];
    if (paymentInProgress) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
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
    [self updateUIForPaymentInProgress:YES];
    [self.delegate createSetupIntentWithPaymentMethod:nil
                                            returnURL:nil
                                           completion:^(STPBackendResult status, NSString *clientSecret, NSError *error) {
                                               if (status == STPBackendResultFailure || clientSecret == nil) {
                                                   [self.delegate exampleViewController:self didFinishWithError:error];
                                                   return;
                                               }
                                               STPSetupIntentConfirmParams *setupIntentConfirmParams = [[STPSetupIntentConfirmParams alloc] initWithClientSecret:clientSecret];
                                               setupIntentConfirmParams.paymentMethodParams = [STPPaymentMethodParams paramsWithCard:self.paymentTextField.cardParams
                                                                                                                      billingDetails:nil
                                                                                                                            metadata:nil];
                                               setupIntentConfirmParams.returnURL = @"payments-example://stripe-redirect";
                                               [[STPPaymentHandler sharedHandler] confirmSetupIntent:setupIntentConfirmParams
                                                                           withAuthenticationContext:self.delegate
                                                                                          completion:^(STPPaymentHandlerActionStatus handlerStatus, STPSetupIntent * _Nullable handledIntent, NSError * _Nullable handlerError) {
                                                                                              switch (handlerStatus) {
                                                                                                  case STPPaymentHandlerActionStatusSucceeded:
                                                                                                      [self.delegate exampleViewController:self didFinishWithMessage:@"SetupIntent successfully created"];
                                                                                                      break;
                                                                                                  case STPPaymentHandlerActionStatusCanceled:
                                                                                                      [self.delegate exampleViewController:self didFinishWithMessage:@"Cancelled"];
                                                                                                      break;
                                                                                                  case STPPaymentHandlerActionStatusFailed:
                                                                                                      [self.delegate exampleViewController:self didFinishWithError:handlerError];
                                                                                                      break;
                                                                                              }
                                                                                          }];
                                               
                                           }];
}

@end
