//
//  STPPaymentContext+Private.h
//  Stripe
//
//  Created by Jack Flintermann on 5/18/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>

#import "STPPaymentMethodTuple.h"
#import "STPPromise.h"
#import "STPShippingAddressViewController.h"

/**
 The current state of the payment context

 - STPPaymentContextStateNone: No view controllers are currently being shown. The payment may or may not have already been completed
 - STPPaymentContextStateShowingRequestedViewController: The view controller that you requested the context show is being shown (via the push or present payment methods or shipping view controller methods)
 - STPPaymentContextStateRequestingPayment: The payment context is in the middle of requesting payment. It may be showing some other UI or view controller if more information is necessary to complete the payment.
 */
typedef NS_ENUM(NSUInteger, STPPaymentContextState) {
    STPPaymentContextStateNone,
    STPPaymentContextStateShowingRequestedViewController,
    STPPaymentContextStateRequestingPayment,
};

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentContext (Private)<STPPaymentMethodsViewControllerDelegate, STPShippingAddressViewControllerDelegate>

@property(nonatomic, readonly)STPPromise<STPPaymentMethodTuple *> *currentValuePromise;

@end

NS_ASSUME_NONNULL_END
