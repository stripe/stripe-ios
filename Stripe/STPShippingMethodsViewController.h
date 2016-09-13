//
//  STPShippingMethodsViewController.h
//  Stripe
//
//  Created by Ben Guo on 8/29/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPShippingMethod.h"
#import "STPTheme.h"

@protocol STPShippingMethodsViewControllerDelegate;

@interface STPShippingMethodsViewController : UIViewController

@property(nonatomic, weak) id<STPShippingMethodsViewControllerDelegate> delegate;

- (instancetype)initWithShippingMethods:(NSArray<STPShippingMethod *>*)methods
                 selectedShippingMethod:(STPShippingMethod *)selectedMethod
                               currency:(NSString *)currency
                                  theme:(STPTheme *)theme;

@end

@protocol STPShippingMethodsViewControllerDelegate <NSObject>

- (void)shippingMethodsViewController:(STPShippingMethodsViewController *)methodsViewController
          didFinishWithShippingMethod:(STPShippingMethod *)method;

@end
