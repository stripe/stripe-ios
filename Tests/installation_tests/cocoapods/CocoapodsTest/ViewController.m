//
//  ViewController.m
//  CocoapodsTest
//
//  Created by Jack Flintermann on 5/7/15.
//  Copyright (c) 2015 stripe. All rights reserved.
//

#import "ViewController.h"
#import <Stripe/Stripe.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [Stripe setDefaultPublishableKey:@"test"];
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
