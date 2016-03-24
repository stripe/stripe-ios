//
//  STPPaymentCardEntryViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPBlocks.h"
#import "STPCardParams.h"

@class STPPaymentCardEntryViewController;

@protocol STPPaymentCardEntryViewControllerDelegate

- (void)paymentCardEntryViewController:(STPPaymentCardEntryViewController *)emailViewController
                    didEnterCardParams:(STPCardParams *)cardParams
                            completion:(STPErrorBlock)completion;

@end


@interface STPPaymentCardEntryViewController : UIViewController
- (instancetype)initWithDelegate:(id<STPPaymentCardEntryViewControllerDelegate>)delegate;
@end
