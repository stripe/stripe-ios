//
//  SettingsViewController.m
//  Stripe
//
//  Created by Alex MacCaw on 3/4/13.
//
//

#import "SettingsViewController.h"
#import "PaymentViewController.h"

@implementation SettingsViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Settings";
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
