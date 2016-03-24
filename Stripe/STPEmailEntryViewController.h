//
//  STPPaymentEmailViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPBlocks.h"

@class STPEmailEntryViewController;

@protocol STPEmailEntryViewControllerDelegate

- (void)emailEntryViewController:(STPEmailEntryViewController *)emailViewController didEnterEmailAddress:(NSString *)emailAddress completion:(STPErrorBlock)completion;

@end

@interface STPEmailEntryViewController : UIViewController
- (instancetype)initWithDelegate:(id<STPEmailEntryViewControllerDelegate>)delegate;
@end
