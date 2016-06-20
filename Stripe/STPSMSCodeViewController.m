//
//  STPSMSCodeViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 5/10/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPSMSCodeViewController.h"
#import "STPSMSCodeTextField.h"
#import "STPCheckoutAPIClient.h"
#import "STPTheme.h"
#import "STPPaymentActivityIndicatorView.h"
#import "StripeError.h"
#import "UIBarButtonItem+Stripe.h"
#import "UIViewController+Stripe_KeyboardAvoiding.h"
#import "STPPhoneNumberValidator.h"

@interface STPSMSCodeViewController()<STPSMSCodeTextFieldDelegate>

@property(nonatomic)STPCheckoutAPIClient *checkoutAPIClient;
@property(nonatomic)STPCheckoutAPIVerification *verification;
@property(nonatomic)NSString *redactedPhone;
@property(nonatomic)NSTimer *hideSMSSentLabelTimer;

@property(nonatomic, weak)UIScrollView *scrollView;
@property(nonatomic, weak)UILabel *topLabel;
@property(nonatomic, weak)STPSMSCodeTextField *codeField;
@property(nonatomic, weak)UILabel *bottomLabel;
@property(nonatomic, weak)UIButton *cancelButton;
@property(nonatomic, weak)UILabel *errorLabel;
@property(nonatomic, weak)UILabel *smsSentLabel;
@property(nonatomic, weak)STPPaymentActivityIndicatorView *activityIndicator;
@property(nonatomic)BOOL loading;

@end

@implementation STPSMSCodeViewController

- (instancetype)initWithCheckoutAPIClient:(STPCheckoutAPIClient *)checkoutAPIClient
                             verification:(STPCheckoutAPIVerification *)verification
                            redactedPhone:(NSString *)redactedPhone {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _checkoutAPIClient = checkoutAPIClient;
        _verification = verification;
        _redactedPhone = redactedPhone;
        _theme = [STPTheme new];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    self.navigationItem.title = NSLocalizedString(@"Verification Code", nil);
    
    UIScrollView *scrollView = [UIScrollView new];
    scrollView.scrollEnabled = NO;
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    
    UILabel *topLabel = [UILabel new];
    topLabel.text = NSLocalizedString(@"Enter the verification code to use the payment info you stored with Stripe.", nil);
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.numberOfLines = 0;
    [self.scrollView addSubview:topLabel];
    self.topLabel = topLabel;
    
    STPSMSCodeTextField *codeField = [STPSMSCodeTextField new];
    [self.scrollView addSubview:codeField];
    codeField.delegate = self;
    self.codeField = codeField;
    
    UILabel *bottomLabel = [UILabel new];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    bottomLabel.text = NSLocalizedString(@"Didn't receive the code?", nil);
    bottomLabel.alpha = 0;
    [self.scrollView addSubview:bottomLabel];
    self.bottomLabel = bottomLabel;
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    cancelButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [cancelButton setTitle:NSLocalizedString(@"Fill in your card details manually", nil) forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.alpha = 0;
    [self.scrollView addSubview:cancelButton];
    self.cancelButton = cancelButton;
    
    UILabel *errorLabel = [UILabel new];
    errorLabel.textAlignment = NSTextAlignmentCenter;
    errorLabel.alpha = 0;
    errorLabel.text = NSLocalizedString(@"Invalid Code", nil);
    [self.scrollView addSubview:errorLabel];
    self.errorLabel = errorLabel;

    UILabel *smsSentLabel = [UILabel new];
    smsSentLabel.textAlignment = NSTextAlignmentCenter;
    smsSentLabel.numberOfLines = 2;
    NSString *sentString = NSLocalizedString(@"We just sent a text message to:", nil);
    smsSentLabel.text = [NSString stringWithFormat:@"%@\n%@", sentString, [STPPhoneNumberValidator formattedRedactedPhoneNumberForString:self.redactedPhone]];
    [self.scrollView addSubview:smsSentLabel];
    self.smsSentLabel = smsSentLabel;
    
    STPPaymentActivityIndicatorView *activityIndicator = [STPPaymentActivityIndicatorView new];
    [self.scrollView addSubview:activityIndicator];
    _activityIndicator = activityIndicator;
    [self updateAppearance];
}

- (void)setTheme:(STPTheme *)theme {
    _theme = theme;
    [self updateAppearance];
}

- (void)updateAppearance {
    [self.navigationItem.leftBarButtonItem stp_setTheme:self.theme];
    [self.navigationItem.rightBarButtonItem stp_setTheme:self.theme];
    self.view.backgroundColor = self.theme.primaryBackgroundColor;
    self.topLabel.font = self.theme.smallFont;
    self.topLabel.textColor = self.theme.secondaryForegroundColor;
    self.codeField.theme = self.theme;
    self.bottomLabel.font = self.theme.smallFont;
    self.bottomLabel.textColor = self.theme.secondaryForegroundColor;
    self.cancelButton.tintColor = self.theme.accentColor;
    self.cancelButton.titleLabel.font = self.theme.smallFont;
    self.errorLabel.font = self.theme.smallFont;
    self.errorLabel.textColor = self.theme.errorColor;
    self.smsSentLabel.font = self.theme.smallFont;
    self.smsSentLabel.textColor = self.theme.secondaryForegroundColor;
    self.activityIndicator.tintColor = self.theme.accentColor;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.scrollView.frame = self.view.bounds;
    self.scrollView.contentSize = self.view.bounds.size;
    
    CGFloat padding = 20.0f;
    CGFloat contentWidth = self.view.bounds.size.width - (padding * 2);
    
    CGSize topLabelSize = [self.topLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    self.topLabel.frame = CGRectMake(padding, 40, contentWidth, topLabelSize.height);
    
    self.codeField.frame = CGRectMake(padding, CGRectGetMaxY(self.topLabel.frame) + 20, contentWidth, 76);
    
    CGSize bottomLabelSize = [self.bottomLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    self.bottomLabel.frame = CGRectMake(padding, CGRectGetMaxY(self.codeField.frame) + 20, contentWidth, bottomLabelSize.height);
    self.errorLabel.frame = self.bottomLabel.frame;
    
    self.cancelButton.frame = CGRectOffset(self.errorLabel.frame, 0, self.errorLabel.frame.size.height + 2);

    CGSize smsSentLabelSize = [self.smsSentLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    self.smsSentLabel.frame = CGRectMake(padding, self.bottomLabel.frame.origin.y, contentWidth, smsSentLabelSize.height);
    
    CGFloat activityIndicatorWidth = 30.0f;
    self.activityIndicator.frame = CGRectMake((self.view.bounds.size.width - activityIndicatorWidth) / 2, CGRectGetMaxY(self.cancelButton.frame) + 20, activityIndicatorWidth, activityIndicatorWidth);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    __weak typeof(self) weakself = self;
    [self stp_beginObservingKeyboardWithBlock:^(CGRect keyboardFrame, __unused UIView *currentlyEditedField) {
        CGFloat base = CGRectGetMaxY(weakself.navigationController.navigationBar.frame);
        CGRect codeFrame = weakself.codeField.frame;
        codeFrame.origin.y += base;
        codeFrame.origin.y += 10.0f;
        CGFloat offset = CGRectIntersection(codeFrame, keyboardFrame).size.height;
        CGPoint destination;
        if (offset > 0) {
            destination = CGPointMake(0, -(base - offset));
        } else {
            destination = CGPointMake(0, -base);
        }
        if (!CGPointEqualToPoint(weakself.scrollView.contentOffset, destination)) {
            weakself.scrollView.contentOffset = destination;
        }
    }];
    [self.codeField becomeFirstResponder];
    self.hideSMSSentLabelTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(hideSMSSentLabel) userInfo:nil repeats:NO];
}

- (void)hideSMSSentLabel {
    [UIView animateWithDuration:0.2f delay:0 options:0 animations:^{
        self.bottomLabel.alpha = 1.0f;
        self.cancelButton.alpha = 1.0f;
        self.smsSentLabel.alpha = 0;
    } completion:nil];
}

- (void)codeTextField:(STPSMSCodeTextField *)codeField
         didEnterCode:(NSString *)code {
    __weak typeof(self) weakself = self;
    self.loading = YES;
    [self.codeField resignFirstResponder];
    STPCheckoutAPIClient *client = self.checkoutAPIClient;
    [[[client submitSMSCode:code forVerification:self.verification] onSuccess:^(STPCheckoutAccount *account) {
        [weakself.delegate smsCodeViewController:weakself didAuthenticateAccount:account];
    }] onFailure:^(NSError *error) {
        if (!weakself) {
            return;
        }
        weakself.loading = NO;
        BOOL tooManyTries = error.code == STPCheckoutTooManyAttemptsError;
        if (tooManyTries) {
            weakself.errorLabel.text = NSLocalizedString(@"Too many incorrect attempts", nil);
        }
        [codeField shakeAndClear];
        [weakself.hideSMSSentLabelTimer invalidate];
        [UIView animateWithDuration:0.2f animations:^{
            weakself.smsSentLabel.alpha = 0;
            weakself.bottomLabel.alpha = 0;
            weakself.cancelButton.alpha = 0;
            weakself.errorLabel.alpha = 1.0f;
        }];
        [UIView animateWithDuration:0.2f delay:0.3f options:0 animations:^{
            weakself.bottomLabel.alpha = 1.0f;
            weakself.cancelButton.alpha = 1.0f;
            weakself.errorLabel.alpha = 0;
        } completion:^(__unused BOOL finished) {
            [weakself.codeField becomeFirstResponder];
            if (tooManyTries) {
                [weakself.delegate smsCodeViewControllerDidCancel:weakself];
            }
        }];
    }];
}

- (void)setLoading:(BOOL)loading {
    if (loading == _loading) {
        return;
    }
    _loading = loading;
    [self.activityIndicator setAnimating:loading animated:YES];
    self.navigationItem.leftBarButtonItem.enabled = !loading;
    self.cancelButton.enabled = !loading;
}

- (void)cancel {
    [self.codeField resignFirstResponder];
    [self.delegate smsCodeViewControllerDidCancel:self];
}

@end
