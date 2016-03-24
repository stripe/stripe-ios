//
//  STPPaymentCardEntryViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentCardEntryViewController.h"
#import "STPPaymentCardEntryView.h"

@interface STPPaymentCardEntryViewController ()<STPPaymentCardEntryViewDelegate>
@property(nonatomic, weak) id<STPPaymentCardEntryViewControllerDelegate> delegate;
@property(nonatomic) STPPaymentCardEntryView *view;
@end

@implementation STPPaymentCardEntryViewController
@dynamic view;

- (instancetype)initWithDelegate:(id<STPPaymentCardEntryViewControllerDelegate>)delegate {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _delegate = delegate;
    }
    return self;
}


- (void)loadView {
    self.view = [[STPPaymentCardEntryView alloc] initWithDelegate:self];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.view becomeFirstResponder];
}

- (void)paymentCardEntryView:(__unused STPPaymentCardEntryView *)emailView didEnterCardParams:(STPCardParams *)params completion:(STPErrorBlock)completion {
    [self.delegate paymentCardEntryViewController:self
                               didEnterCardParams:params
                                       completion:completion];
}

@end
