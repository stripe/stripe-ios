//
//  STPShippingEntryViewController.h
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PassKit/PassKit.h>
#import "STPBlocks.h"

@class STPShippingEntryViewController, STPAddress;

@protocol STPShippingEntryViewControllerDelegate <NSObject>

- (void)shippingEntryViewControllerDidCancel:(nonnull STPShippingEntryViewController *)paymentCardViewController;
- (void)shippingEntryViewController:(nonnull STPShippingEntryViewController *)paymentCardViewController
            didEnterShippingAddress:(nonnull STPAddress *)address
                         completion:(nonnull STPErrorBlock)completion;

@end

@interface STPShippingEntryViewController : UIViewController

- (nonnull instancetype)initWithAddress:(nullable STPAddress *)address
                               delegate:(nonnull id<STPShippingEntryViewControllerDelegate>)delegate
                  requiredAddressFields:(PKAddressField)requiredAddressFields;

@end
