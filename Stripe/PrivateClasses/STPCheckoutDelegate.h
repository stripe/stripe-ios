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
- (void)checkoutAdapterDidStartLoad:(id<STPCheckoutWebViewAdapter>)adapter;
- (void)checkoutAdapterDidFinishLoad:(id<STPCheckoutWebViewAdapter>)adapter;
- (void)checkoutAdapter:(id<STPCheckoutWebViewAdapter>)adapter didTriggerEvent:(NSString *)event withPayload:(NSDictionary *)payload;
- (void)checkoutAdapter:(id<STPCheckoutWebViewAdapter>)adapter didError:(NSError *)error;
@end
