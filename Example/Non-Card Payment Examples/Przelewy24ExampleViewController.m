//
//  Przelewy24ExampleViewController.m
//  Non-Card Payment Examples
//
//  Created by Vineet Shah on 4/23/20.
//  Copyright © 2020 Stripe. All rights reserved.
//

#import "Przelewy24ExampleViewController.h"

#import "MyAPIClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface Przelewy24ExampleViewController ()

@end

@implementation Przelewy24ExampleViewController {
    UITextField *_emailField;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Przelewy24";

    _emailField = [[UITextField alloc] init];
    _emailField.borderStyle = UITextBorderStyleRoundedRect;
    _emailField.textContentType = UITextContentTypeEmailAddress;
    _emailField.placeholder = @"Email";
    _emailField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_emailField];

    [self.payButton setTitle:@"Pay with Przelewy24" forState:UIControlStateNormal];
    [self.payButton sizeToFit];

    [NSLayoutConstraint activateConstraints:@[
        [_emailField.centerXAnchor constraintEqualToAnchor:self.payButton.centerXAnchor],
        [_emailField.bottomAnchor constraintEqualToAnchor:self.payButton.topAnchor constant:-12.f],
        [_emailField.widthAnchor constraintEqualToConstant:240.f],
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
        billingDetails.email = self->_emailField.text;


        STPPaymentMethodPrzelewy24Params *przelewy24 = [[STPPaymentMethodPrzelewy24Params alloc] init];

        // Przelewy24 does not require additional parameters so we only need to pass the init-ed
        // STPPaymentMethodPrzelewy24Params instance to STPPaymentMethodParams
        paymentIntentParams.paymentMethodParams = [STPPaymentMethodParams paramsWithPrzelewy24:przelewy24
                                                                                billingDetails:billingDetails
                                                                                      metadata:nil];

        paymentIntentParams.returnURL = @"payments-example://stripe-redirect";
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
    } additionalParameters:@"country=pl"];
}

@end

NS_ASSUME_NONNULL_END
