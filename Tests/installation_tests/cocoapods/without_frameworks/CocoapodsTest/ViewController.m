//
//  ViewController.m
//  CocoapodsTest
//
//  Created by Jack Flintermann on 8/4/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

#import "ViewController.h"
#import <Stripe/Stripe.h>
#import "MyAPIClient.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *pushButton;
@property (nonatomic, strong) UIButton *presentButton;
@property (nonatomic, strong) STPPaymentContext *paymentContext;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    STPPaymentConfiguration *config = [STPPaymentConfiguration sharedConfiguration];
    config.publishableKey = @"test";
    STPTheme *theme = [STPTheme new];
    theme.accentColor = [UIColor purpleColor];
    STPPaymentContext *paymentContext = [[STPPaymentContext alloc] initWithAPIAdapter:[MyAPIClient new]
                                                                 configuration:config
                                                                         theme:theme];
    paymentContext.hostViewController = self;
    self.paymentContext = paymentContext;
    UIButton *pushButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [pushButton setTitle:@"Push" forState:UIControlStateNormal];
    [pushButton sizeToFit];
    [pushButton addTarget:self action:@selector(push) forControlEvents:UIControlEventTouchUpInside];
    self.pushButton = pushButton;
    UIButton *presentButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [presentButton setTitle:@"Present" forState:UIControlStateNormal];
    [presentButton sizeToFit];
    [presentButton addTarget:self action:@selector(present) forControlEvents:UIControlEventTouchUpInside];
    self.presentButton = presentButton;
    [self.view addSubview:self.pushButton];
    [self.view addSubview:self.presentButton];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.pushButton.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds)/2.0);
    self.presentButton.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds)*3.0/4.0);
}

- (void)push {
    [self.paymentContext pushPaymentMethodsViewController];
}

- (void)present {
    [self.paymentContext presentPaymentMethodsViewController];
}

@end
