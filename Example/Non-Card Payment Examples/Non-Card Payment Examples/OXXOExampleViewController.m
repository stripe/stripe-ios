//
//  OXXOExampleViewController.m
//  Non-Card Payment Examples
//
//  Created by Polo Li on 6/18/20.
//  Copyright © 2020 Stripe. All rights reserved.
//

#import "OXXOExampleViewController.h"

#import "MyAPIClient.h"

@interface OXXOExampleViewController ()

@end

@implementation OXXOExampleViewController {
    UITextField *_nameField;
    UITextField *_emailField;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.title = @"OXXO";

    _nameField = [[UITextField alloc] init];
    _nameField.borderStyle = UITextBorderStyleRoundedRect;
    _nameField.textContentType = UITextContentTypeName;
    _nameField.placeholder = @"Full name";
    _nameField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_nameField];

    _emailField = [[UITextField alloc] init];
    _emailField.borderStyle = UITextBorderStyleRoundedRect;
    _emailField.textContentType = UITextContentTypeEmailAddress;
    _emailField.placeholder = @"Email address";
    _emailField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_emailField];

    [self.payButton setTitle:@"Pay with OXXO" forState:UIControlStateNormal];
    [self.payButton sizeToFit];

    [NSLayoutConstraint activateConstraints:@[
        [_emailField.centerXAnchor constraintEqualToAnchor:self.payButton.centerXAnchor],
        [_emailField.widthAnchor constraintEqualToConstant:240.f],
        [_emailField.bottomAnchor constraintEqualToAnchor:self.payButton.topAnchor constant:-12.f],
        [_nameField.centerXAnchor constraintEqualToAnchor:self.payButton.centerXAnchor],
        [_nameField.bottomAnchor constraintEqualToAnchor:self->_emailField.topAnchor constant:-12.f],
        [_nameField.widthAnchor constraintEqualToConstant:240.f],
    ]];
}

- (void)payButtonSelected {
    [super payButtonSelected];
    [self updateUIForPaymentInProgress:YES];

    [[MyAPIClient sharedClient] createPaymentIntentWithCompletion:^(MyAPIClientResult status, NSString *clientSecret, NSError *error) {
        if (status == MyAPIClientResultFailure || clientSecret == nil) {
            [self.delegate exampleViewController:self didFinishWithError:error];
            return;
        }

        STPPaymentIntentParams *paymentIntentParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];

        STPPaymentMethodBillingDetails *billingDetails = [[STPPaymentMethodBillingDetails alloc] init];
        billingDetails.name = self->_nameField.text;
        billingDetails.email = self->_emailField.text;


        STPPaymentMethodOXXOParams *oxxo = [[STPPaymentMethodOXXOParams alloc] init];

        // OXXO does not require additional parameters so we only need to pass the init-ed
        // STPPaymentMethodOXXOParams instance to STPPaymentMethodParams
        paymentIntentParams.paymentMethodParams = [STPPaymentMethodParams paramsWithOXXO:oxxo
                                                                          billingDetails:billingDetails
                                                                                metadata:nil];

        [[STPPaymentHandler sharedHandler] confirmPayment:paymentIntentParams
                                withAuthenticationContext:self.delegate
                                               completion:^(STPPaymentHandlerActionStatus handlerStatus, STPPaymentIntent * handledIntent, NSError * _Nullable handlerError) {
            switch (handlerStatus) {
                case STPPaymentHandlerActionStatusFailed:
                    [self.delegate exampleViewController:self didFinishWithError:handlerError];
                    break;
                case STPPaymentHandlerActionStatusCanceled:
                    [self.delegate exampleViewController:self didFinishWithMessage:@"Canceled"];
                    break;
                case STPPaymentHandlerActionStatusSucceeded:
                    [self.delegate exampleViewController:self didFinishWithMessage:@"Payment successfully created"];
                    break;
            }
        }];
    } additionalParameters:@"country=mx"];
}

@end
