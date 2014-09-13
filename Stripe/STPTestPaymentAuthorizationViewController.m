//
//  STPTestPaymentAuthorizationViewController.m
//  StripeExample
//
//  Created by Jack Flintermann on 9/8/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

#import "STPTestPaymentAuthorizationViewController.h"
#import "PKPayment+STPTestKeys.h"

@interface STPTestPaymentAuthorizationViewController()<UIActionSheetDelegate>
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@end

@implementation STPTestPaymentAuthorizationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator = activityIndicator;
    self.activityIndicator.center = self.view.center;
    self.activityIndicator.hidesWhenStopped = YES;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Test Card Picker" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Select Test Working Card", @"Select Test Failing Card", nil];
    [actionSheet showInView:self.view];
}

- (void)makePaymentWithCardNumber:(NSString *)cardNumber {
    [self.activityIndicator startAnimating];
    PKPayment *payment = [PKPayment new];
    payment.stp_testCardNumber = cardNumber;
    
    PKPaymentAuthorizationViewController *auth = (PKPaymentAuthorizationViewController *)self;
    
    [self.activityIndicator startAnimating];
    [self.delegate paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)auth
                                  didAuthorizePayment:payment
                                           completion:^(PKPaymentAuthorizationStatus status) {
                                               [self.activityIndicator stopAnimating];
                                               [self.delegate paymentAuthorizationViewControllerDidFinish:auth];
                                           }];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.cancelButtonIndex == buttonIndex) {
        [self actionSheetCancel:actionSheet];
        return;
    }
    switch (buttonIndex) {
        case 0:
            [self makePaymentWithCardNumber:STPSuccessfulChargeCardNumber];
            break;
        default:
            [self makePaymentWithCardNumber:STPFailingChargeCardNumber];
            break;
    }
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    [self.delegate paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)self];
}

@end

#endif
