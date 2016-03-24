//
//  STPPaymentEmailViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPEmailEntryViewController.h"
#import "STPEmailEntryView.h"

@interface STPEmailEntryViewController ()<STPEmailEntryViewDelegate>
@property(nonatomic, weak)id<STPEmailEntryViewControllerDelegate> delegate;
@property(nonatomic, readwrite)STPEmailEntryView *view;
@end

@implementation STPEmailEntryViewController
@dynamic view;

- (instancetype)initWithDelegate:(id<STPEmailEntryViewControllerDelegate>)delegate {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)loadView {
    self.view = [[STPEmailEntryView alloc] initWithDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.view becomeFirstResponder];
}

- (void)emailEntryView:(__unused STPEmailEntryView *)emailView
    didEnterEmailAddress:(NSString *)emailAddress
              completion:(STPErrorBlock)completion {
    [self.delegate emailEntryViewController:self didEnterEmailAddress:emailAddress completion:completion];
}

@end
