//
//  PaymentViewController.m
//
//  Created by Alex MacCaw on 2/14/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "Stripe.h"

#import "MBProgressHUD.h"

#import "PaymentViewController.h"
#import "PKView.h"
#import <Parse/Parse.h>

@interface PaymentViewController ()<PKViewDelegate>
@property(weak, nonatomic) PKView *paymentView;
@end

@implementation PaymentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Add Card";
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
      self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    // Setup save button
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(save:)];
    saveButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = saveButton;
    
    // Setup checkout
    PKView *paymentView = [[PKView alloc] initWithFrame:CGRectMake(15, 20, 290, 55)];
    paymentView.delegate = self;
    self.paymentView = paymentView;
    [self.view addSubview:paymentView];
}

- (void)paymentView:(PKView *)paymentView
           withCard:(PKCard *)card
            isValid:(BOOL)valid {
    // Enable save button if the Checkout is valid
    self.navigationItem.rightBarButtonItem.enabled = valid;
}

- (IBAction)save:(id)sender {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    STPCard *card = [[STPCard alloc] init];
    card.number = self.paymentView.card.number;
    card.expMonth = self.paymentView.card.expMonth;
    card.expYear = self.paymentView.card.expYear;
    card.cvc = self.paymentView.card.cvc;
    [Stripe createTokenWithCard:card completion:^(STPToken *token, NSError *error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (error) {
            [self hasError:error];
        } else {
            [self hasToken:token];
        }
    }];
}

- (void)hasError:(NSError *)error {
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                      message:[error localizedDescription]
                                                     delegate:nil
                                            cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                            otherButtonTitles:nil];
    [message show];
}

- (void)hasToken:(STPToken *)token
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSDictionary *chargeParams = @{
                                   @"token": token.tokenId,
                                   @"currency": @"usd",
                                   @"amount": @"1000", // this is in cents (i.e. $10)
                                   };
    
    // This passes the token off to our payment backend, which will then actually complete charging the card using your account's
    [PFCloud callFunctionInBackground:@"charge" withParameters:chargeParams block:^(id object, NSError *error) {
       [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (error) {
            [self hasError:error];
            return;
        }
        [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
            [[[UIAlertView alloc] initWithTitle:@"Payment Succeeded" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
        }];
    }];
}

@end
