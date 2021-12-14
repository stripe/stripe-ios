//
//  ViewController.m
//  CocoapodsTest
//
//  Created by Jack Flintermann on 8/4/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

#import "ViewController.h"
@import Stripe;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [StripeAPI setDefaultPublishableKey:@"test"];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
