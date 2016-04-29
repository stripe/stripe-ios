//
//  PaymentViewController.m
//
//  Created by Alex MacCaw on 2/14/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "ViewController.h"

#import "PaymentViewController.h"

@interface PaymentViewController () <STPPaymentCardTextFieldDelegate>
@property (weak, nonatomic) STPPaymentCardTextField *paymentTextField;
@property (weak, nonatomic) UIActivityIndicatorView *activityIndicator;
@end

@implementation PaymentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Buy a shirt";
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    // Setup save button
    NSString *title = [NSString stringWithFormat:@"Pay $%@", self.amount];
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleDone target:self action:@selector(save:)];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    saveButton.enabled = NO;
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = saveButton;
    
    // Setup payment view
    STPPaymentCardTextField *paymentTextField = [[STPPaymentCardTextField alloc] init];
    paymentTextField.delegate = self;
    paymentTextField.cursorColor = [UIColor purpleColor];
    self.paymentTextField = paymentTextField;
    [self.view addSubview:paymentTextField];
    
    // Setup Activity Indicator
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator = activityIndicator;
    [self.view addSubview:activityIndicator];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat padding = 15;
    CGFloat width = CGRectGetWidth(self.view.frame) - (padding * 2);
    self.paymentTextField.frame = CGRectMake(padding, padding, width, 44);
    
    self.activityIndicator.center = self.view.center;
}

- (void)paymentCardTextFieldDidChange:(nonnull STPPaymentCardTextField *)textField {
    self.navigationItem.rightBarButtonItem.enabled = textField.isValid;
}

- (void)cancel:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)save:(id)sender {
    if (![self.paymentTextField isValid]) {
        return;
    }
    if (![Stripe defaultPublishableKey]) {
        NSError *error = [NSError errorWithDomain:StripeDomain
                                             code:STPInvalidRequestError
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey: @"Please specify a Stripe Publishable Key in Constants.m"
                                                    }];
        [self.delegate paymentViewController:self didFinish:error];
        return;
    }
    [self.activityIndicator startAnimating];
    [[STPAPIClient sharedClient] createTokenWithCard:self.paymentTextField.cardParams
                                          completion:^(STPToken *token, NSError *error) {
                                              [self.activityIndicator stopAnimating];
                                              if (error) {
                                                  [self.delegate paymentViewController:self didFinish:error];
                                              }
                                              [self.backendCharger createBackendChargeWithToken:token
                                                                                     completion:^(STPBackendChargeResult result, NSError *error) {
                                                                                         if (error) {
                                                                                             [self.delegate paymentViewController:self didFinish:error];
                                                                                             return;
                                                                                         }
                                                                                         [self.delegate paymentViewController:self didFinish:nil];
                                                                                     }];
                                          }];
}

@end