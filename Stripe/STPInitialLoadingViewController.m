//
//  STPInitialLoadingViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 4/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPInitialLoadingViewController.h"

@interface STPInitialLoadingViewController ()
@property(nonatomic, weak)UIActivityIndicatorView *activityIndicator;
@end

@implementation STPInitialLoadingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.backBarButtonItem = nil;
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:activityIndicator];
    self.activityIndicator = activityIndicator;
    [self.activityIndicator startAnimating];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.activityIndicator.center = self.view.center;
}

@end
