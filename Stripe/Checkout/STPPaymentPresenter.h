//
//  STPPaymentPresenter.h
//  Stripe
//
//  Created by Jack Flintermann on 11/25/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPCheckoutOptions.h"
#import "STPCheckoutViewController.h"
#import "STPToken.h"

typedef NS_ENUM(NSInteger, STPPaymentStatus) {
    STPPaymentStatusSuccess,      // The transaction was a success.
    STPPaymentStatusError,        // The transaction failed.
    STPPaymentStatusUserCanceled, // User canceled the payment sheet.
};

@class PKPaymentRequest, STPPaymentPresenter;

@protocol STPPaymentPresenterDelegate<NSObject>

- (void)paymentPresenter:(STPPaymentPresenter *)presenter didCreateStripeToken:(STPToken *)token completion:(STPTokenSubmissionHandler)completion;

- (void)paymentPresenter:(STPPaymentPresenter *)presenter didFinishWithStatus:(STPPaymentStatus)status error:(NSError *)error;

@optional

@end

@interface STPPaymentPresenter : NSObject

@property (nonatomic, weak) id<STPPaymentPresenterDelegate> delegate;
@property (nonatomic) STPCheckoutOptions *checkoutOptions;

#ifdef STRIPE_ENABLE_APPLEPAY
@property (nonatomic) PKPaymentRequest *paymentRequest;
#endif

- (void)requestPaymentFromPresentingViewController:(UIViewController *)presentingViewController;

@end
