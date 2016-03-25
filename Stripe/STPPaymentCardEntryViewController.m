//
//  STPPaymentCardEntryViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentCardEntryViewController.h"
#import "STPPaymentCardTextField.h"

@interface STPPaymentCardEntryViewController ()<STPPaymentCardTextFieldDelegate>
@property(nonatomic, weak) id<STPPaymentCardEntryViewControllerDelegate> delegate;
@property(nonatomic, weak)STPPaymentCardTextField *textField;
@property(nonatomic, weak)UIActivityIndicatorView *activityIndicator;
@property(nonatomic, weak)UIButton *nextButton;
@end

@implementation STPPaymentCardEntryViewController
@dynamic view;

- (instancetype)initWithDelegate:(id<STPPaymentCardEntryViewControllerDelegate>)delegate {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _delegate = delegate;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    STPPaymentCardTextField *textField = [[STPPaymentCardTextField alloc] initWithFrame:CGRectZero];
    _textField = textField;
    _textField.delegate = self;
    [self.view addSubview:textField];

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _activityIndicator = activityIndicator;
    [self.view addSubview:activityIndicator];

    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    nextButton.enabled = NO;
    [nextButton setTitle:NSLocalizedString(@"Next", nil) forState:UIControlStateNormal];
    [nextButton addTarget:self action:@selector(nextPressed:) forControlEvents:UIControlEventTouchUpInside];
    _nextButton = nextButton;
    [self.view addSubview:nextButton];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _activityIndicator.center = self.view.center;
    _textField.frame = CGRectMake(0, 0, self.view.bounds.size.width - 40, 44);
    _textField.center = CGPointMake(self.view.center.x, CGRectGetMinY(_activityIndicator.frame) - 50);
    [_nextButton sizeToFit];
    _nextButton.center = CGPointMake(self.view.center.x, CGRectGetMaxY(_activityIndicator.frame) + 50);
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.textField becomeFirstResponder];
}


- (void)nextPressed:(__unused id)sender {
    [self.activityIndicator startAnimating];
    [self.delegate paymentCardEntryViewController:self didEnterCardParams:self.textField.cardParams completion:^(NSError *error) {
        if (error) {
            NSLog(@"%@", error);
            [self.activityIndicator stopAnimating];
            return;
        }
    }];
}

- (void)paymentCardTextFieldDidChange:(STPPaymentCardTextField *)textField {
    self.nextButton.enabled = textField.isValid;
}

- (BOOL)canBecomeFirstResponder {
    return [self.textField canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [self.textField becomeFirstResponder];
}

- (BOOL)canResignFirstResponder {
    return [self.textField canResignFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [self.textField resignFirstResponder];
}

@end
