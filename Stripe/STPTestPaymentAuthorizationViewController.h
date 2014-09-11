//
//  STPTestPaymentAuthorizationViewController.h
//  StripeExample
//
//  Created by Jack Flintermann on 9/8/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

#import <UIKit/UIKit.h>
#import <PassKit/PassKit.h>

@protocol STPTestPKPaymentDelegate <NSObject>

@required
-(void)testPaymentAuthorizationViewController:(UIViewController *)controller
                          didAuthorizePayment:(PKPayment *)payment
                                   completion:(void (^)(PKPaymentAuthorizationStatus))completion;

-(void)paymentAuthorizationViewControllerDidFinish:(UIViewController *)controller;
@end


@interface STPTestPaymentAuthorizationViewController : UIViewController

@property(nonatomic, assign)id<STPTestPKPaymentDelegate>delegate;

@end

#endif