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
#import "UIFont+Stripe.h"
#import "UIColor+Stripe.h"
#import "UIImage+Stripe.h"

@interface STPPaymentCardEntryViewController ()<STPPaymentCardTextFieldDelegate>
@property(nonatomic)STPAPIClient *apiClient;
@property(nonatomic, copy)STPPaymentCardEntryBlock completion;
@property(nonatomic, weak)STPPaymentCardTextField *textField;
@property(nonatomic, weak)UIActivityIndicatorView *activityIndicator;
@property(nonatomic, weak)UIImageView *cardImageView;
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
    self.view.backgroundColor = [UIColor stp_backgroundColor];

    NSDictionary *titleTextAttributes = @{NSFontAttributeName:[UIFont stp_navigationBarFont]};
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed:)];
    [leftBarButtonItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(nextPressed:)];
    [rightBarButtonItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.navigationItem.title = NSLocalizedString(@"Card", nil);

    UIImageView *cardImageView = [[UIImageView alloc] initWithImage:[UIImage stp_largeCardFrontImage]];
    self.cardImageView = cardImageView;
    [self.view addSubview:cardImageView];
    
    STPPaymentCardTextField *textField = [[STPPaymentCardTextField alloc] initWithFrame:CGRectZero];
    textField.backgroundColor = [UIColor whiteColor];
    textField.cornerRadius = 0;
    textField.borderColor = [UIColor colorWithWhite:0.9 alpha:1];
    textField.delegate = self;
    self.textField = textField;
    [self.view addSubview:textField];

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _activityIndicator = activityIndicator;
    [self.view addSubview:activityIndicator];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGSize cardImageSize = CGSizeMake(176, 111);
    self.cardImageView.frame = CGRectMake(0, 0, cardImageSize.width, cardImageSize.height);
    CGFloat navBarMaxY = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    self.cardImageView.center = CGPointMake(self.view.center.x, navBarMaxY + cardImageSize.height/2.0 + 27);

    self.textField.frame = CGRectMake(-1, CGRectGetMaxY(self.cardImageView.frame) + 41,
                                      self.view.bounds.size.width + 2, 44);
    self.activityIndicator.center = self.view.center;
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
