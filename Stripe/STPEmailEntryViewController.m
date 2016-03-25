//
//  STPPaymentEmailViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPEmailEntryViewController.h"
#import "STPEmailAddressValidator.h"

@interface STPEmailEntryViewController ()<UITextFieldDelegate>

@property(nonatomic, weak)id<STPEmailEntryViewControllerDelegate> delegate;
@property(nonatomic, weak) UITextField *textField;
@property(nonatomic, weak) UIActivityIndicatorView *activityIndicator;
@property(nonatomic, weak) UIButton *nextButton;

@end

@implementation STPEmailEntryViewController
@dynamic view;

- (instancetype)initWithDelegate:(id<STPEmailEntryViewControllerDelegate>)delegate {
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
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectZero];
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.keyboardType = UIKeyboardTypeEmailAddress;
    textField.borderStyle = UITextBorderStyleBezel;
    textField.delegate = self;
    [textField addTarget:self action:@selector(textFieldDidChange) forControlEvents:UIControlEventEditingChanged];
    _textField = textField;
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.textField becomeFirstResponder];
}

- (void)nextPressed:(__unused id)sender {
    [self next];
}

- (void)next {
    [self.activityIndicator startAnimating];
    [self.delegate emailEntryViewController:self didEnterEmailAddress:self.textField.text completion:^(NSError *error) {
        if (error) {
            NSLog(@"%@", error);
            [self.activityIndicator stopAnimating];
            return;
        }
    }];
}

- (void)textFieldDidChange {
    self.nextButton.enabled = [STPEmailAddressValidator stringIsValidEmailAddress:self.textField.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    BOOL isValid = [STPEmailAddressValidator stringIsValidEmailAddress:textField.text];
    if (isValid) {
        [self next];
    }
    return isValid;
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
