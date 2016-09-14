//
//  STPShippingAddressViewController+Private.h
//  Stripe
//
//  Created by Ben Guo on 9/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "STPShippingAddressViewController.h"

@interface STPShippingAddressViewController (Private)

/** 
 *  If the view controller was presented as a result of calling `requestPayment`
 *  (i.e. to collect missing shipping info before requesting payment),
 *  this property will be true.
 */
@property(nonatomic) BOOL isMidPaymentRequest;

@end
