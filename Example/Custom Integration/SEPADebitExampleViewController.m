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
    } additionalParameters:@"payment_method_types[]=ideal&currency=eur"];

}

@end
