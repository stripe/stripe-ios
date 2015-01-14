//
//  ViewController.m
//  StripeExample
//
//  Created by Jack Flintermann on 8/21/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <Stripe-WithoutApplePay/Stripe.h>
#import <Parse/Parse.h>
#import "ViewController.h"
#import "Constants.h"
#import "PaymentViewController.h"

@interface ViewController()
@property (weak, nonatomic) IBOutlet UILabel *cartLabel;
@property (weak, nonatomic) IBOutlet UIButton *checkoutButton;
@property (nonatomic) NSDecimalNumber *amount;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateCartWithNumberOfShirts:0];
}

- (void)updateCartWithNumberOfShirts:(NSUInteger)numberOfShirts {
    NSInteger price = 10;
    self.amount = [NSDecimalNumber decimalNumberWithMantissa:numberOfShirts * price exponent:0 isNegative:NO];
    self.cartLabel.text = [NSString stringWithFormat:@"%@ shirts = $%@", @(numberOfShirts), self.amount];
    self.checkoutButton.enabled = numberOfShirts > 0;
}

- (IBAction)changeCart:(UIStepper *)sender {
    [self updateCartWithNumberOfShirts:sender.value];
}

- (IBAction)beginPayment:(id)sender {
    PaymentViewController *paymentViewController = [[PaymentViewController alloc] initWithNibName:nil bundle:nil];
    paymentViewController.amount = self.amount;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:paymentViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

@end
