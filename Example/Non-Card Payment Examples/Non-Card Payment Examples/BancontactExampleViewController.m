//
//  BancontactExampleViewController.m
//  Non-Card Payment Examples
//
//  Created by Vineet Shah on 4/29/20.
//  Copyright © 2020 Stripe. All rights reserved.
//

#import "BancontactExampleViewController.h"

#import "MyAPIClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface BancontactExampleViewController ()

@end

@implementation BancontactExampleViewController {
    UITextField *_nameField;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Bancontact";

    _nameField = [[UITextField alloc] init];
    _nameField.borderStyle = UITextBorderStyleRoundedRect;
    _nameField.textContentType = UITextContentTypeName;
    _nameField.placeholder = @"Full name";
    _nameField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_nameField];

    [self.payButton setTitle:@"Pay with Bancontact" forState:UIControlStateNormal];
    [self.payButton sizeToFit];

    [NSLayoutConstraint activateConstraints:@[
        [_nameField.centerXAnchor constraintEqualToAnchor:self.payButton.centerXAnchor],
        [_nameField.bottomAnchor constraintEqualToAnchor:self.payButton.topAnchor constant:-12.f],
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


        STPPaymentMethodBancontactParams *bancontact = [[STPPaymentMethodBancontactParams alloc] init];

        // Bancontact does not require additional parameters so we only need to pass the init-ed
        // STPPaymentMethodBancontactParams instance to STPPaymentMethodParams
        paymentIntentParams.paymentMethodParams = [STPPaymentMethodParams paramsWithBancontact:bancontact
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
    } additionalParameters:@"country=be"];
}

@end

NS_ASSUME_NONNULL_END
