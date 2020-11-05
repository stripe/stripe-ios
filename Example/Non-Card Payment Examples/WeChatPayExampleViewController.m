//
//  WeChatPayExampleViewController.m
//  Non-Card Payment Examples
//
//  Created by Yuki Tokuhiro on 8/6/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "WeChatPayExampleViewController.h"

@import Stripe;

#import "BrowseExamplesViewController.h"

/**
 Note: WeChat Pay is in private beta. For participating users, see https://stripe.com/docs/sources/wechat-pay/ios
 
 WeChat Pay is not currently supported by PaymentMethods, so integration requires the use of Sources.
 ref. https://stripe.com/docs/payments/payment-methods#transitioning
 
 This example demonstrates using Sources and PaymentIntents to accept payments using WeChat Pay, a popular payment method in China.
 1. Create a WeChat Pay Source object with payment details.
 2. We redirect the user to their WeChat app to authorize the payment.

 Because WeChat payments require the user to take action in WeChat Pay, we don't tell our backend to create a charge
 request in this example. Instead, your backend should listen to the `source.chargeable` webhook event to
 charge the source. See https://stripe.com/docs/sources/best-practices for more information.
 */
static NSString *const StripeExampleWeChatAppID = @"wxa0df51ec63e578ce";

@interface WeChatPayExampleViewController ()
@property (nonatomic, weak) UIButton *payButton;
@property (nonatomic, weak) UILabel *waitingLabel;
@property (nonatomic, weak) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) STPRedirectContext *redirectContext;
@end

@implementation WeChatPayExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"WeChat Pay";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Pay with WeChat" forState:UIControlStateNormal];
    [button sizeToFit];
    [button addTarget:self action:@selector(pay) forControlEvents:UIControlEventTouchUpInside];
    self.payButton = button;
    [self.view addSubview:button];
    
    UILabel *label = [UILabel new];
    label.text = @"Waiting for payment authorization";
    [label sizeToFit];
    label.textColor = [UIColor grayColor];
    label.alpha = 0;
    [self.view addSubview:label];
    self.waitingLabel = label;
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator = activityIndicator;
    [self.view addSubview:activityIndicator];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat padding = 15;
    CGRect bounds = self.view.bounds;
    self.payButton.center = CGPointMake(CGRectGetMidX(bounds), 100);
    self.activityIndicator.center = CGPointMake(CGRectGetMidX(bounds),
                                                CGRectGetMaxY(self.payButton.frame) + padding*2);
    self.waitingLabel.center = CGPointMake(CGRectGetMidX(bounds),
                                           CGRectGetMaxY(self.activityIndicator.frame) + padding*2);
}

- (void)updateUIForPaymentInProgress:(BOOL)paymentInProgress {
    self.navigationController.navigationBar.userInteractionEnabled = !paymentInProgress;
    self.payButton.enabled = !paymentInProgress;
    [UIView animateWithDuration:0.2 animations:^{
        self.waitingLabel.alpha = paymentInProgress ? 1 : 0;
    }];
    if (paymentInProgress) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
}

- (void)pay {
    if (![StripeAPI defaultPublishableKey]) {
        [self.delegate exampleViewController:self didFinishWithMessage:@"Please set a Stripe Publishable Key in Constants.m"];
        return;
    }
    // 0. Make sure the user has the WeChat Pay app installed before offering WeChat Pay as a payment option.
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"weixin://"]]) {
        [self.delegate exampleViewController:self didFinishWithMessage:@"WeChat pay only works with the WeChat Pay app installed."];
        return;
    }
    [self updateUIForPaymentInProgress:YES];
    // 1. Create a WeChat Pay Source
    STPSourceParams *sourceParams = [STPSourceParams wechatPayParamsWithAmount:100
                                                                      currency:@"USD"
                                                                         appId:StripeExampleWeChatAppID
                                                           statementDescriptor:@"ORDER AT11990"];
    [[STPAPIClient sharedClient] createSourceWithParams:sourceParams completion:^(STPSource *source, NSError *error) {
        if (error) {
            [self.delegate exampleViewController:self didFinishWithError:error];
        } else {
            // 2. Redirect the user to their WeChat Pay app
            self.redirectContext = [[STPRedirectContext alloc] initWithSource:source completion:^(NSString *sourceID, NSString *clientSecret, NSError *error) {
                if (error) {
                    [self.delegate exampleViewController:self didFinishWithError:error];
                } else {
                    // 3. Poll your backend to show the customer their order status
                    
                    // Our sample backend has no database, so we poll the Source directly.
                    // In a real app, the client can't be relied on to be alive when the Source becomes chargeable; your backend must use webhooks or another mechanism to do this.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
                    [[STPAPIClient sharedClient] startPollingSourceWithId:sourceID
                                                             clientSecret:clientSecret
                                                                  timeout:10
                                                               completion:^(STPSource *source, NSError *error) {
#pragma clang diagnostic pop
                                                                   [self updateUIForPaymentInProgress:NO];
                                                                   if (error) {
                                                                       [self.delegate exampleViewController:self didFinishWithError:error];
                                                                   } else {
                                                                       switch (source.status) {
                                                                           case STPSourceStatusChargeable:
                                                                           case STPSourceStatusConsumed:
                                                                               [self.delegate exampleViewController:self didFinishWithMessage:@"Your order was received and is awaiting payment confirmation."];
                                                                               break;
                                                                           case STPSourceStatusCanceled:
                                                                           case STPSourceStatusFailed:
                                                                               [self.delegate exampleViewController:self didFinishWithMessage:@"Your payment failed and your order couldn't be processed."];
                                                                               break;
                                                                           case STPSourceStatusPending:
                                                                           case STPSourceStatusUnknown:
                                                                               [self.delegate exampleViewController:self didFinishWithMessage:@"Your order was received and is awaiting payment confirmation."];
                                                                               break;
                                                                       }
                                                                   }
                                                                   self.redirectContext = nil;
                                                               }];
                }
            }];
            [self.redirectContext startRedirectFlowFromViewController:self];
        }
    }];
}

@end
