//
//  STPCoreTableViewController.h
//  Stripe
//
//  Created by Brian Dorfman on 1/6/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCoreScrollViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPCoreTableViewController : STPCoreScrollViewController

@property(nonatomic, readonly) UITableView *tableView;

@end

NS_ASSUME_NONNULL_END
