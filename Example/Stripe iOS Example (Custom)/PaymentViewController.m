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

// UI for testing setCard (TODO: remove)
@property (strong, nonatomic) UITextField *numberField;
@property (strong, nonatomic) UITextField *expMonthField;
@property (strong, nonatomic) UITextField *expYearField;
@property (strong, nonatomic) UITextField *cvcField;
@property (strong, nonatomic) UIButton *setButton;
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

    // UI for testing setCard (TODO: remove)
    self.numberField = [UITextField new];
    self.numberField.placeholder = @"Number";
    self.expMonthField = [UITextField new];
    self.expMonthField.placeholder = @"Exp Month";
    self.expYearField = [UITextField new];
    self.expYearField.placeholder = @"Exp Year";
    self.cvcField = [UITextField new];
    self.cvcField.placeholder = @"CVC";
    NSArray<UITextField *> *fields = @[self.numberField, self.expMonthField, self.expYearField, self.cvcField];
    for (UITextField *field in fields) {
        field.borderStyle = UITextBorderStyleLine;
        field.keyboardType = UIKeyboardTypeNumberPad;
        field.frame = CGRectMake(0, 0, 300, 40);
    }
    self.setButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.setButton setTitle:@"setCard" forState:UIControlStateNormal];
    [self.setButton addTarget:self action:@selector(setCard:) forControlEvents:UIControlEventTouchUpInside];
    [self.setButton sizeToFit];
    [self.view addSubview:self.numberField];
    [self.view addSubview:self.expMonthField];
    [self.view addSubview:self.expYearField];
    [self.view addSubview:self.cvcField];
    [self.view addSubview:self.setButton];
}

// UI for testing setCard (TODO: remove)
- (void)setCard:(UIButton *)button {
    STPCardParams *card = [[STPCardParams alloc] init];
    card.number = self.numberField.text;
    card.expMonth = [self.expMonthField.text integerValue];
    card.expYear = [self.expYearField.text integerValue];
    card.cvc = self.cvcField.text;
    [self.paymentTextField setCard:card];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat padding = 15;
    CGFloat width = CGRectGetWidth(self.view.frame) - (padding * 2);
    self.paymentTextField.frame = CGRectMake(padding, padding, width, 44);
    
    self.activityIndicator.center = self.view.center;

    // UI for testing setCard (TODO: remove)
    CGFloat centerX = self.paymentTextField.center.x;
    self.numberField.center = CGPointMake(centerX, CGRectGetMaxY(self.paymentTextField.frame) + padding*2);
    self.expMonthField.center = CGPointMake(centerX, CGRectGetMaxY(self.numberField.frame) + padding);
    self.expYearField.center = CGPointMake(centerX, CGRectGetMaxY(self.expMonthField.frame) + padding);
    self.cvcField.center = CGPointMake(centerX, CGRectGetMaxY(self.expYearField.frame) + padding);
    self.setButton.center = CGPointMake(centerX, CGRectGetMaxY(self.cvcField.frame) + padding);
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
    [[STPAPIClient sharedClient] createTokenWithCard:self.paymentTextField.card
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