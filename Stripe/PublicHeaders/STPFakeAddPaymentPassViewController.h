//
//  STPFakeAddPaymentPassViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 9/28/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PassKit/PassKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface STPFakeAddPaymentPassViewController : UIViewController

+ (BOOL)canAddPaymentPass;

- (nullable instancetype)initWithRequestConfiguration:(PKAddPaymentPassRequestConfiguration *)configuration
                                             delegate:(nullable id<PKAddPaymentPassViewControllerDelegate>)delegate NS_DESIGNATED_INITIALIZER;

@property (nonatomic, weak, nullable) id<PKAddPaymentPassViewControllerDelegate> delegate;

@end



NS_ASSUME_NONNULL_END
