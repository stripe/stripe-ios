//
//  STPCheckoutDelegate.h
//  Stripe
//
//  Created by Jack Flintermann on 1/7/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPNullabilityMacros.h"

@protocol STPCheckoutWebViewAdapter;
@protocol STPCheckoutDelegate<NSObject>
- (void)checkoutAdapterDidStartLoad:(stp_nonnull id<STPCheckoutWebViewAdapter>)adapter;
- (void)checkoutAdapterDidFinishLoad:(stp_nonnull id<STPCheckoutWebViewAdapter>)adapter;
- (void)checkoutAdapter:(stp_nonnull id<STPCheckoutWebViewAdapter>)adapter
        didTriggerEvent:(stp_nonnull NSString *)event
            withPayload:(stp_nonnull NSDictionary *)payload;
- (void)checkoutAdapter:(stp_nonnull id<STPCheckoutWebViewAdapter>)adapter didError:(stp_nonnull NSError *)error;
@end
