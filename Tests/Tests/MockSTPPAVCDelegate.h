//
//  MockSTPPAVCDelegate.h
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/29/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Stripe/Stripe.h>

@interface MockSTPPAVCDelegate : NSObject <STPPaymentAuthorizationViewControllerDelegate>

@property (nonatomic, copy, nullable) void(^onDidCancel)();
@property (nonatomic, copy, nullable) void(^onDidFailWithError)(NSError * __nonnull);
@property (nonatomic, copy, nullable) void(^onDidCreatePaymentResult)(STPPaymentResult * __nonnull, STPErrorBlock __nonnull);

@end
