//
//  GiropayExampleViewControllewrViewController.m
//  Non-Card Payment Examples
//
//  Created by Cameron Sabol on 4/22/20.
//  Copyright © 2020 Stripe. All rights reserved.
//

#import "GiropayExampleViewControllewrViewController.h"

#import "MyAPIClient.h"

@interface GiropayExampleViewControllewrViewController ()

@end

@implementation GiropayExampleViewControllewrViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"giropay";

    [self.payButton setTitle:@"Pay with giropay" forState:UIControlStateNormal];
    [self.payButton sizeToFit];
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
        billingDetails.name = @"giropay Test Customer";


        STPPaymentMethodGiropayParams *giropay = [[STPPaymentMethodGiropayParams alloc] init];

        // giropay does not require additional parameters so we only need to pass the init-ed
        // STPPaymentMethoGiropayParams instance to STPPaymentMethodParams
        paymentIntentParams.paymentMethodParams = [STPPaymentMethodParams paramsWithGiropay:giropay
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
    } additionalParameters:@"country=de"];
}

@end
