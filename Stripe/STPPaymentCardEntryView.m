//
//  STPPaymentCardEntryView.m
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentCardEntryView.h"
#import "STPPaymentCardTextField.h"

@interface STPPaymentCardEntryView()<STPPaymentCardTextFieldDelegate>

@property(nonatomic, weak) id<STPPaymentCardEntryViewDelegate> delegate;
@property(nonatomic, weak)STPPaymentCardTextField *textField;
@property(nonatomic, weak)UIActivityIndicatorView *activityIndicator;
@property(nonatomic, weak)UIButton *nextButton;

@end

@implementation STPPaymentCardEntryView

- (instancetype)initWithDelegate:(id<STPPaymentCardEntryViewDelegate>)delegate {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _delegate = delegate;
        self.backgroundColor = [UIColor whiteColor];
        STPPaymentCardTextField *textField = [STPPaymentCardTextField new];
        _textField = textField;
        _textField.delegate = self;
        [self addSubview:textField];
        
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicator = activityIndicator;
        [self addSubview:activityIndicator];
        
        UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
        nextButton.enabled = NO;
        [nextButton setTitle:NSLocalizedString(@"Next", nil) forState:UIControlStateNormal];
        [nextButton addTarget:self action:@selector(nextPressed:) forControlEvents:UIControlEventTouchUpInside];
        _nextButton = nextButton;
        [self addSubview:nextButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _activityIndicator.center = self.center;
    _textField.frame = CGRectMake(0, 0, self.bounds.size.width - 40, 44);
    _textField.center = CGPointMake(self.center.x, CGRectGetMinY(_activityIndicator.frame) - 50);
    [_nextButton sizeToFit];
    _nextButton.center = CGPointMake(self.center.x, CGRectGetMaxY(_activityIndicator.frame) + 50);
}

- (void)nextPressed:(__unused id)sender {
    [self.activityIndicator startAnimating];
    [self.delegate paymentCardEntryView:self didEnterCardParams:self.textField.cardParams completion:^(NSError *error) {
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
