//
//  SofortExampleViewController.m
//  Stripe iOS Example (Custom)
//
//  Created by Ben Guo on 2/22/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "SofortExampleViewController.h"
#import "BrowseExamplesViewController.h"

/**
 This example demonstrates using Sources to accept payments using SOFORT, a popular payment method in Europe.
 First, we create a Sofort Source object with our payment details. We then redirect the user to the URL
 in the Source object to authorize the payment, and start polling the Source so that we can display the
 appropriate status when the user returns to the app. 

 Because Sofort payments require further action from the user, we don't tell our backend to create a charge
 request in this example. Instead, your backend should listen to the `source.chargeable` webhook event to 
 charge the source. See https://stripe.com/docs/sources#best-practices for more information.
 */
@interface SofortExampleViewController ()
@property (nonatomic, weak) UIButton *payButton;
@property (nonatomic, weak) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) STPSource *source;
@end

@implementation SofortExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Sofort";
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Pay with Sofort" forState:UIControlStateNormal];
    [button sizeToFit];
    [button addTarget:self action:@selector(pay) forControlEvents:UIControlEventTouchUpInside];
    self.payButton = button;
    [self.view addSubview:button];

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator = activityIndicator;
    [self.view addSubview:activityIndicator];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    self.payButton.center = CGPointMake(CGRectGetMidX(bounds), 100);
}

- (void)presentPollingUI {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Waiting for payment authorization"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)dismissPollingUI {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)pay {
    if (![Stripe defaultPublishableKey]) {
        [self.delegate exampleViewController:self didFinishWithMessage:@"Please set a Stripe Publishable Key in Constants.m"];
        return;
    }
    STPSourceParams *sourceParams = [STPSourceParams sofortParamsWithAmount:1099
                                                                  returnURL:@"payments-example://stripe-redirect"
                                                                    country:@"DE"
                                                        statementDescriptor:@"ORDER AT11990"];
    [[STPAPIClient sharedClient] createSourceWithParams:sourceParams completion:^(STPSource *source, NSError *error) {
        if (error) {
            [self.delegate exampleViewController:self didFinishWithError:error];
        } else {
            self.source = source;
            [self presentPollingUI];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
            [[UIApplication sharedApplication] openURL:source.redirect.url];
        }
    }];
}

- (void)handleAppForeground {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[STPAPIClient sharedClient] startPollingSourceWithId:self.source.stripeID
                                             clientSecret:self.source.clientSecret
                                                  timeout:10
                                               completion:^(STPSource *source, NSError *error) {
        [self dismissPollingUI];
        if (error) {
            [self.delegate exampleViewController:self didFinishWithError:error];
        } else {
            if (source.status == STPSourceStatusConsumed) {
                [self.delegate exampleViewController:self didFinishWithMessage:@"Payment successfully created"];
            } else if (source.status == STPSourceStatusFailed) {
                [self.delegate exampleViewController:self didFinishWithMessage:@"Payment failed"];
            } else {
                [self.delegate exampleViewController:self didFinishWithMessage:@"Order received"];
            }
        }
    }];
}

@end
