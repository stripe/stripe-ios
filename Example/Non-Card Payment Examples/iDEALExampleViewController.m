//
//  iDEALExampleViewController.m
//  Non-Card Payment Examples
//
//  Created by Cameron Sabol on 10/10/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "iDEALExampleViewController.h"

#import "MyAPIClient.h"

@interface iDEALExampleViewController ()

@end

@implementation iDEALExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"iDEAL";

    [self.payButton setTitle:@"Pay with iDEAL" forState:UIControlStateNormal];
    [self.payButton sizeToFit];
}

- (void)payButtonSelected {
    [self updateUIForPaymentInProgress:YES];

    [[MyAPIClient sharedClient] createPaymentIntentWithCompletion:^(MyAPIClientResult status, NSString *clientSecret, NSError *error) {
        if (status == MyAPIClientResultFailure || clientSecret == nil) {
            [self.delegate exampleViewController:self didFinishWithError:error];
            return;
        }

        STPPaymentIntentParams *paymentIntentParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];

        STPPaymentMethodiDEALParams *iDEALParams = [[STPPaymentMethodiDEALParams alloc] init];
        iDEALParams.bankName = @"ing";

        paymentIntentParams.paymentMethodParams = [STPPaymentMethodParams paramsWithiDEAL:iDEALParams
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
    } additionalParameters:@"country=nl"];

}

@end
