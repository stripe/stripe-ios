//
//  STPPaymentCardEntryViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentCardEntryViewController.h"
#import "STPPaymentCardTextField.h"
#import "STPToken.h"

@interface STPPaymentCardEntryViewController ()<STPPaymentCardTextFieldDelegate>
@property(nonatomic)STPAPIClient *apiClient;
@property(nonatomic, copy)STPPaymentCardEntryBlock completion;
@property(nonatomic, weak)STPPaymentCardTextField *textField;
@property(nonatomic, weak)UIActivityIndicatorView *activityIndicator;
@end

@implementation STPPaymentCardEntryViewController
@dynamic view;

- (instancetype)initWithAPIClient:(STPAPIClient *)apiClient
                       completion:(STPPaymentCardEntryBlock)completion {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _apiClient = apiClient;
        _completion = completion;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(nextPressed:)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.navigationItem.title = NSLocalizedString(@"Card", nil);
    
    
    STPPaymentCardTextField *textField = [[STPPaymentCardTextField alloc] initWithFrame:CGRectZero];
    _textField = textField;
    _textField.delegate = self;
    [self.view addSubview:textField];

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _activityIndicator = activityIndicator;
    [self.view addSubview:activityIndicator];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _activityIndicator.center = self.view.center;
    _textField.frame = CGRectMake(0, 0, self.view.bounds.size.width - 40, 44);
    _textField.center = CGPointMake(self.view.center.x, CGRectGetMinY(_activityIndicator.frame) - 50);
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.textField becomeFirstResponder];
}

- (void)cancelPressed:(__unused id)sender {
    if (self.completion) {
        self.completion(nil);
        self.completion = nil;
    }
}

- (void)nextPressed:(__unused id)sender {
    [self.activityIndicator startAnimating];
    [self.textField resignFirstResponder];
    [self.apiClient createTokenWithCard:self.textField.cardParams completion:^(STPToken *token, NSError *error) {
        if (error) {
            [self.activityIndicator stopAnimating];
            NSLog(@"%@", error);
            [self.textField becomeFirstResponder];
            // TODO handle error, probably by showing a UIAlertController
        } else {
            if (self.completion) {
                self.completion(token);
                self.completion = nil;
            }
        }
    }];
}

- (void)paymentCardTextFieldDidChange:(STPPaymentCardTextField *)textField {
    self.navigationItem.rightBarButtonItem.enabled = textField.isValid;
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
