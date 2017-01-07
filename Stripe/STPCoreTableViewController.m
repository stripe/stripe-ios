//
//  STPCoreTableViewController.m
//  Stripe
//
//  Created by Brian Dorfman on 1/6/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCoreTableViewController.h"

@interface STPCoreTableViewController ()
@end

@implementation STPCoreTableViewController

- (UIScrollView *)createScrollView {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    tableView.sectionHeaderHeight = 30;

    return tableView;
}

- (UITableView *)tableView {
    return (UITableView *)self.scrollView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.tableView reloadData];
}

- (void)updateAppearance {
    [super updateAppearance];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone; // handle this with fake separator views for flexibility
}


- (CGFloat)tableView:(__unused UITableView *)tableView heightForHeaderInSection:(__unused NSInteger)section {
    return 0.01f;
}


@end
