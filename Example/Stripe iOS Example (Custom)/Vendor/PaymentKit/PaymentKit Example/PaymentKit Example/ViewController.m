//
//  ViewController.m
//  PTKPayment Example
//
//  Created by Alex MacCaw on 2/5/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "ViewController.h"
#import "PaymentViewController.h"

@implementation ViewController

@synthesize paymentCell;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Settings";
    [self updatePaymentCell];
}

- (void)updatePaymentCell
{
    NSString* last4 = [[NSUserDefaults standardUserDefaults] stringForKey:@"card.last4"];
    self.paymentCell.detailTextLabel.text = last4;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self updatePaymentCell];
}

- (void)changeCard
{
    PaymentViewController *viewController = [[PaymentViewController alloc] initWithNibName:@"PaymentViewController" bundle:nil];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) return self.paymentCell;
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell isEqual:self.paymentCell]) [self changeCard];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
