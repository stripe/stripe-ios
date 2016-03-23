//
//  STPPaymentEmailViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPEmailEntryViewController.h"
#import "STPPaymentEmailView.h"

@interface STPEmailEntryViewController ()<STPPaymentEmailViewDelegate>
@property(nonatomic, readwrite)STPPaymentEmailView *view;
@end

@implementation STPEmailEntryViewController
@dynamic view;

- (void)loadView {
    self.view = [STPPaymentEmailView new];
    self.view.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.view becomeFirstResponder];
}

- (void)paymentEmailView:(__unused STPPaymentEmailView *)emailView
    didEnterEmailAddress:(NSString *)emailAddress
              completion:(STPErrorBlock)completion {
    [self.delegate paymentEmailViewController:self didEnterEmailAddress:emailAddress completion:completion];
}

@end
