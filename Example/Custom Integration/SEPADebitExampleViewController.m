//
//  SEPADebitExampleViewController.m
//  Custom Integration
//
//  Created by Cameron Sabol on 10/7/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "SEPADebitExampleViewController.h"

#import "MyAPIClient.h"

@interface SEPADebitExampleViewController ()

@end

@implementation SEPADebitExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"SEPA Debit";

    [self.payButton setTitle:@"Pay with SEPA Debit" forState:UIControlStateNormal];
    [self.payButton sizeToFit];

    UILabel *mandateAuthLabel = [[UILabel alloc] init];
    mandateAuthLabel.numberOfLines = 0;
    mandateAuthLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCallout];
    mandateAuthLabel.textAlignment = NSTextAlignmentCenter;
    mandateAuthLabel.text = @"By providing your IBAN and confirming this payment, you are authorizing EXAMPLE COMPANY NAME and Stripe, our payment service provider, to send instructions to your bank to debit your account and your bank to debit your account in accordance with those instructions. You are entitled to a refund from your bank under the terms and conditions of your agreement with your bank. A refund must be claimed within 8 weeks starting from the date on which your account was debited.";
    mandateAuthLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:mandateAuthLabel];

    [NSLayoutConstraint activateConstraints:@[
        [mandateAuthLabel.leadingAnchor constraintEqualToSystemSpacingAfterAnchor:self.view.safeAreaLayoutGuide.leadingAnchor multiplier:2],
        [self.view.safeAreaLayoutGuide.trailingAnchor constraintEqualToSystemSpacingAfterAnchor:mandateAuthLabel.trailingAnchor multiplier:2],

        [mandateAuthLabel.topAnchor constraintEqualToSystemSpacingBelowAnchor:self.view.safeAreaLayoutGuide.topAnchor multiplier:2],
    ]];
}

- (void)payButtonSelected {
    [self updateUIForPaymentInProgress:YES];

    [[MyAPIClient sharedClient] createPaymentIntentWithCompletion:^(MyAPIClientResult status, NSString *clientSecret, NSError *error) {
        if (status == MyAPIClientResultFailure || clientSecret == nil) {
            [self.delegate exampleViewController:self didFinishWithError:error];
            return;
        }

        STPPaymentIntentParams *paymentIntentParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];

        STPPaymentMethodBillingDetails *billingDetails = [[STPPaymentMethodBillingDetails alloc] init];
        billingDetails.name = @"SEPA Test Customer";
        billingDetails.email = @"test@example.com";

        STPPaymentMethodSEPADebitParams *sepaDebitDetails = [[STPPaymentMethodSEPADebitParams alloc] init];
        sepaDebitDetails.iban = @"DE89370400440532013000";

        paymentIntentParams.paymentMethodParams = [STPPaymentMethodParams paramsWithSEPADebit:sepaDebitDetails
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
    } additionalParameters:@"country=nl"];

}

@end
