//
//  STPFakeAddPaymentPassViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 9/28/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPFakeAddPaymentPassViewController.h"
#import "PKAddPaymentPassRequest+Stripe_Error.h"
#import "StripeError.h"
#import "STPLocalizationUtils.h"

typedef NS_ENUM(NSUInteger, STPFakeAddPaymentPassViewControllerState) {
    STPFakeAddPaymentPassViewControllerStateInitial,
    STPFakeAddPaymentPassViewControllerStateLoading,
    STPFakeAddPaymentPassViewControllerStateError,
    STPFakeAddPaymentPassViewControllerStateSuccess,
};

@interface STPFakeAddPaymentPassViewController ()
@property(nonatomic)PKAddPaymentPassRequestConfiguration *configuration;
@property(nonatomic)STPFakeAddPaymentPassViewControllerState state;
@property(nonatomic)UILabel *contentLabel;
@property(nonatomic)NSString *errorText;
@end

@implementation STPFakeAddPaymentPassViewController

+ (BOOL)canAddPaymentPass {
    return YES;
}

- (nullable instancetype)initWithRequestConfiguration:(PKAddPaymentPassRequestConfiguration *)configuration
                                             delegate:(nullable id<PKAddPaymentPassViewControllerDelegate>)delegate {
    self = [super initWithNibName:nil bundle:nil];
    NSCParameterAssert(delegate);
    if (self) {
        _state = STPFakeAddPaymentPassViewControllerStateInitial;
        _delegate = delegate;
        _configuration = configuration;
        if (!configuration.primaryAccountSuffix && !configuration.cardholderName) {
            NSCAssert(NO, @"Your PKAddPaymentPassRequestConfiguration must provide either a cardholderName or a primaryAccountSuffix.");
        }
    }
    return self;
}

- (instancetype)initWithNibName:(__unused NSString *)nibNameOrNil bundle:(__unused NSBundle *)nibBundleOrNil {
    return [self initWithRequestConfiguration:[PKAddPaymentPassRequestConfiguration new] delegate:nil];
}

- (instancetype)initWithCoder:(__unused NSCoder *)aDecoder {
    return [self initWithRequestConfiguration:[PKAddPaymentPassRequestConfiguration new] delegate:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UINavigationBar *navBar = [[UINavigationBar alloc] init];
    [self.view addSubview:navBar];
    navBar.translucent = NO;
    navBar.backgroundColor = [UIColor whiteColor];
    navBar.items = @[self.navigationItem];
    navBar.translatesAutoresizingMaskIntoConstraints = NO;
    [navBar.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active  = YES;
    [navBar.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    if (@available(iOS 11.0, *)) {
        [navBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor].active = YES;
    } else {
        [navBar.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    }

    UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.contentLabel = contentLabel;
    contentLabel.textAlignment = NSTextAlignmentCenter;
    contentLabel.textColor = [UIColor blackColor];
    contentLabel.numberOfLines = 0;
    contentLabel.font = [UIFont systemFontOfSize:18];
    contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:contentLabel];
    [contentLabel.topAnchor constraintEqualToAnchor:navBar.bottomAnchor].active = YES;
    [contentLabel.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:10.0f].active  = YES;
    [contentLabel.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-10.0f].active = YES;
    [contentLabel.heightAnchor constraintEqualToConstant:150].active = YES;
    
    NSMutableArray *pairs = [NSMutableArray array];
    if (self.configuration.cardholderName) {
        [pairs addObject:@[@"Name", self.configuration.cardholderName]];
    }
    if (self.configuration.primaryAccountSuffix) {
        [pairs addObject:@[@"Card Number", [NSString stringWithFormat:@"···· %@", self.configuration.primaryAccountSuffix]]];
    }
    NSMutableArray *rows = [NSMutableArray array];
    for (NSArray *pair in pairs) {
        UILabel *left = [[UILabel alloc] init];
        left.text = pair[0];
        left.textAlignment = NSTextAlignmentLeft;
        [left setFont:[UIFont boldSystemFontOfSize:16]];
        UILabel *right = [[UILabel alloc] init];
        right.text = pair[1];
        right.textAlignment = NSTextAlignmentLeft;
        right.textColor = [UIColor lightGrayColor];
        UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[left, right]];
        row.axis = UILayoutConstraintAxisHorizontal;
        row.distribution = UIStackViewDistributionFillEqually;
        row.alignment = UIStackViewAlignmentFill;
        row.translatesAutoresizingMaskIntoConstraints = NO;
        [rows addObject:row];
    }
    UIStackView *pairsTable = [[UIStackView alloc] initWithArrangedSubviews:rows];
    pairsTable.layoutMarginsRelativeArrangement = YES;
    pairsTable.layoutMargins = UIEdgeInsetsMake(20, 20, 20, 20);
    pairsTable.axis = UILayoutConstraintAxisVertical;
    pairsTable.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:pairsTable];

    [pairsTable.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active  = YES;
    [pairsTable.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    [pairsTable.topAnchor constraintEqualToAnchor:contentLabel.bottomAnchor].active = YES;
    [pairsTable.heightAnchor constraintEqualToConstant:(rows.count * 50)].active = YES;
    [self setState:STPFakeAddPaymentPassViewControllerStateInitial];
}

- (void)setState:(STPFakeAddPaymentPassViewControllerState)state {
    _state = state;
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [nextButton addTarget:self action:@selector(next:) forControlEvents:UIControlEventTouchUpInside];
    UIActivityIndicatorView *indicatorView = nil;
    #ifdef __IPHONE_13_0
            if (@available(iOS 13.0, *)) {
                indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
            } else {
    #endif
    #if !(defined(TARGET_OS_MACCATALYST) && (TARGET_OS_MACCATALYST != 0))
                indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    #endif
    #ifdef __IPHONE_13_0
            }
    #endif
    [indicatorView startAnimating];
    UIBarButtonItem *loadingItem = [[UIBarButtonItem alloc] initWithCustomView:indicatorView];
    [nextButton setTitle:STPNonLocalizedString(@"Next") forState:UIControlStateNormal];
    UIBarButtonItem *nextItem = [[UIBarButtonItem alloc] initWithCustomView:nextButton];
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    
    switch (state) {
        case STPFakeAddPaymentPassViewControllerStateInitial:
            self.contentLabel.text = STPNonLocalizedString(@"This class simulates the delegate methods that PKAddPaymentPassViewController will call in your app. Press next to continue.");
            self.navigationItem.leftBarButtonItem = cancelItem;
            self.navigationItem.rightBarButtonItem = nextItem;
            break;
        case STPFakeAddPaymentPassViewControllerStateLoading:
            self.contentLabel.text = STPNonLocalizedString(@"Fetching encrypted card details...");
            cancelItem.enabled = NO;
            self.navigationItem.leftBarButtonItem = cancelItem;
            self.navigationItem.rightBarButtonItem = loadingItem;
            break;
        case STPFakeAddPaymentPassViewControllerStateError:
            self.contentLabel.text = STPNonLocalizedString([@"Error: " stringByAppendingString:self.errorText]);
            doneItem.enabled = NO;
            self.navigationItem.leftBarButtonItem = cancelItem;
            self.navigationItem.rightBarButtonItem = doneItem;
            break;
        case STPFakeAddPaymentPassViewControllerStateSuccess:
            self.contentLabel.text = STPNonLocalizedString(@"Success! In production, your card would now have been added to your Apple Pay wallet. Your app's success callback will be triggered when the user presses 'Done'.");
            cancelItem.enabled = NO;
            self.navigationItem.leftBarButtonItem = cancelItem;
            self.navigationItem.rightBarButtonItem = doneItem;
    }
}

- (void)cancel:(__unused id)sender {
    [self.delegate addPaymentPassViewController:(PKAddPaymentPassViewController *)self didFinishAddingPaymentPass:nil error:[NSError errorWithDomain:PKPassKitErrorDomain code:PKAddPaymentPassErrorUserCancelled userInfo:nil]];
}

- (void)next:(__unused id)sender {
    [self setState:STPFakeAddPaymentPassViewControllerStateLoading];
    NSArray *certificates = @[
                     [@"cert1" dataUsingEncoding:NSUTF8StringEncoding],
                     [@"cert2" dataUsingEncoding:NSUTF8StringEncoding],
                     ];
    NSData *nonce = [@"nonce" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *nonceSignature = [@"nonceSignature" dataUsingEncoding:NSUTF8StringEncoding];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.state == STPFakeAddPaymentPassViewControllerStateLoading) {
            self.errorText = @"You exceeded the timeout of 10 seconds to call the request completion handler. Please check your PKAddPaymentPassViewControllerDelegate implementation, and make sure you are calling the `completionHandler` in `addPaymentPassViewController:generateRequestWithCertificateChain:nonce:nonceSignature:completionHandler`.";
            [self setState:STPFakeAddPaymentPassViewControllerStateError];
        }
    });
    [self.delegate addPaymentPassViewController:(PKAddPaymentPassViewController *)self
            generateRequestWithCertificateChain:certificates
                                          nonce:nonce
                                 nonceSignature:nonceSignature
                              completionHandler:^(PKAddPaymentPassRequest * _Nonnull request) {
                                  if (self.state == STPFakeAddPaymentPassViewControllerStateLoading) {
                                      NSString *contents;
                                      if (request.encryptedPassData) {
                                          contents = [[NSString alloc] initWithData:request.encryptedPassData encoding:NSUTF8StringEncoding];
                                      }
                                      if (request.stp_error) {
                                          NSString *error = request.stp_error.userInfo[STPErrorMessageKey];
                                          if (!error) {
                                              error = request.stp_error.userInfo[NSLocalizedDescriptionKey];
                                          }
                                          self.errorText = error;
                                          [self setState:STPFakeAddPaymentPassViewControllerStateError];
                                      }
                                      // This specific string is returned by the Stripe API in testmode.
                                      else if ([contents isEqualToString:@"TESTMODE_CONTENTS"]){
                                              [self setState:STPFakeAddPaymentPassViewControllerStateSuccess];
                                      } else {
                                          self.errorText = @"Your server response contained the wrong encrypted card details. Please ensure that you are not modifying the response from the Stripe API in any way, and that your request is in testmode.";
                                          [self setState:STPFakeAddPaymentPassViewControllerStateError];
                                      }
                                  }
}];
}

- (void)done:(__unused id)sender {
    PKPaymentPass *pass = [PKPaymentPass new];
    [self.delegate addPaymentPassViewController:(PKAddPaymentPassViewController *)self didFinishAddingPaymentPass:pass error:nil];
}

@end
