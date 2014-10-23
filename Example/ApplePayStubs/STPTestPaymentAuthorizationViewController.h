//
//  STPTestPaymentAuthorizationViewController.h
//  StripeExample
//
//  Created by Jack Flintermann on 9/30/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

#import <UIKit/UIKit.h>
#import <PassKit/PassKit.h>

@interface STPTestPaymentAuthorizationViewController : UIViewController

- (instancetype)initWithPaymentRequest:(PKPaymentRequest *)paymentRequest;
@property(nonatomic, assign)id<PKPaymentAuthorizationViewControllerDelegate>delegate;

@end

#endif
