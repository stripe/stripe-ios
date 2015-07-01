//
//  ViewController.h
//  PTKPayment Example
//
//  Created by Alex MacCaw on 2/5/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableViewCell *paymentCell;

@end
