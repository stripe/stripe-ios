//
//  PaymentExampleViewController.h
//  Non-Card Payment Examples
//
//  Created by Cameron Sabol on 10/7/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@import Stripe;

#import "BrowseExamplesViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface PaymentExampleViewController : UIViewController <STPAuthenticationContext>

@property (nonatomic, weak) id<ExampleViewControllerDelegate> delegate;

@property (nonatomic, weak) UIButton *payButton;
@property (nonatomic, weak) UILabel *waitingLabel;
@property (nonatomic, weak) UIActivityIndicatorView *activityIndicator;

- (void)payButtonSelected;
- (void)updateUIForPaymentInProgress:(BOOL)paymentInProgress;

@end

NS_ASSUME_NONNULL_END
