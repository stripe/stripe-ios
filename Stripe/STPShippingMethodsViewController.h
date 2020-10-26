//
//  STPShippingMethodsViewController.h
//  Stripe
//
//  Created by Ben Guo on 8/29/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PassKit/PassKit.h>
#import "STPCoreTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol STPShippingMethodsViewControllerDelegate;

@interface STPShippingMethodsViewController : STPCoreTableViewController

- (instancetype)initWithShippingMethods:(NSArray<PKShippingMethod *>*)methods
                 selectedShippingMethod:(nullable PKShippingMethod *)selectedMethod
                               currency:(NSString *)currency
                                  theme:(STPTheme *)theme;

@property (nonatomic, weak) id<STPShippingMethodsViewControllerDelegate> delegate;

@end

@protocol STPShippingMethodsViewControllerDelegate <NSObject>

- (void)shippingMethodsViewController:(STPShippingMethodsViewController *)methodsViewController
          didFinishWithShippingMethod:(PKShippingMethod *)method;

@end

NS_ASSUME_NONNULL_END
