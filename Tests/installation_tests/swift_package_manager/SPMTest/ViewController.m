//
//  ViewController.m
//  CocoapodsTest
//
//  Created by Ben Guo on 3/20/18.
//  Copyright © 2018 Stripe. All rights reserved.
//

#import "ViewController.h"
#import <Stripe/Stripe.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [Stripe setDefaultPublishableKey:@"foo"];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
