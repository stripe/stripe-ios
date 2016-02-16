//
//  ViewController.h
//  StripeExample
//
//  Created by Jack Flintermann on 8/21/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, STPBackendChargeResult) {
    STPBackendChargeResultSuccess,
    STPBackendChargeResultFailure,
};

typedef void (^STPTokenSubmissionHandler)(STPBackendChargeResult status, NSError *error);

@protocol STPBackendCharging <NSObject>

- (void)createBackendChargeWithToken:(STPToken *)token completion:(STPTokenSubmissionHandler)completion;

@end

@interface ViewController : UIViewController<STPBackendCharging>

@end
