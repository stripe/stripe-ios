//
//  STPTestDataTableViewController.h
//  StripeExample
//
//  Created by Jack Flintermann on 10/1/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

#import <UIKit/UIKit.h>
#import "STPTestDataStore.h"

typedef void (^STPTestDataTableViewControllerCallback)(id selectedItem);

@interface STPTestDataTableViewController : UITableViewController

- (instancetype)initWithStore:(id<STPTestDataStore>)store;
@property(nonatomic, copy)STPTestDataTableViewControllerCallback callback;

@end

#endif