//
//  STPCoreTableViewController+Private.h
//  Stripe
//
//  Created by Brian Dorfman on 1/10/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCoreTableViewController.h"
#import "STPCoreScrollViewController+Private.h"

/**
 This class extension contains properties and methods that are intended to
 be for private Stripe usage only, and are here to be hidden from the public
 api in STPCoreTableViewController.h

 All Stripe view controllers which inherit from STPCoreTableViewController
 should also import this file.
 */
@interface STPCoreTableViewController ()

/**
 This points to the same object as `STPCoreScrollViewController`'s `scrollView`
 property but with the type cast to `UITableView`
 */
@property(nonatomic, nullable, readonly) UITableView *tableView;
@end
