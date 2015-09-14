//
//  STPCheckoutDelegate.h
//  Stripe
//
//  Created by Jack Flintermann on 1/7/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol STPCheckoutWebViewAdapter;
@protocol STPCheckoutDelegate<NSObject>
- (void)checkoutAdapterDidStartLoad:(nonnull id<STPCheckoutWebViewAdapter>)adapter;
- (void)checkoutAdapterDidFinishLoad:(nonnull id<STPCheckoutWebViewAdapter>)adapter;
- (void)checkoutAdapter:(nonnull id<STPCheckoutWebViewAdapter>)adapter
        didTriggerEvent:(nonnull NSString *)event
            withPayload:(nonnull NSDictionary *)payload;
- (void)checkoutAdapter:(nonnull id<STPCheckoutWebViewAdapter>)adapter didError:(nonnull NSError *)error;
@end
