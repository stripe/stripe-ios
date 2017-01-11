//
//  STPCoreTableViewController.m
//  Stripe
//
//  Created by Brian Dorfman on 1/6/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCoreTableViewController.h"
#import "STPCoreTableViewController+Private.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)

// Note:
// The private class extension for this class is in
// STPCoreTableViewController+Private.h

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
    FAUXPAS_IGNORED_IN_METHOD(UnusedMethod)
    return 0.01f;
}


@end
