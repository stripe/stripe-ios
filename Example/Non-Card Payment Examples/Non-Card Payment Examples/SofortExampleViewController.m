//
//  SofortExampleViewController.m
//  Non-Card Payment Examples
//
//  Created by David Estes on 8/7/20.
//  Copyright © 2020 Stripe. All rights reserved.
//

#import "SofortExampleViewController.h"

#import "MyAPIClient.h"

@interface SofortExampleViewController ()

@end

@implementation SofortExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Sofort";
    
    [self.payButton setTitle:@"Pay with Sofort" forState:UIControlStateNormal];
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

        STPPaymentMethodSofortParams *sofort = [[STPPaymentMethodSofortParams alloc] init];
        sofort.country = @"DE";
        paymentIntentParams.paymentMethodParams = [STPPaymentMethodParams paramsWithSofort:sofort
                                                                            billingDetails:nil
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
