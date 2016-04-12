//
//  MockSTPPaymentCoordinatorDelegate.h
//  Stripe
//
//  Created by Jack Flintermann on 4/11/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPPaymentCoordinator.h"

@interface MockSTPPaymentCoordinatorDelegate : NSObject<STPPaymentCoordinatorDelegate>

@property (nonatomic) BOOL ignoresUnexpectedCallbacks;
@property (nonatomic, copy, nullable) void(^onDidCancel)();
@property (nonatomic, copy, nullable) void(^onDidFailWithError)(NSError * __nonnull);
@property (nonatomic, copy, nullable) void(^onDidSucceed)();
@property (nonatomic, copy, nullable) void(^onDidCreatePaymentResult)(STPPaymentResult * __nonnull, STPErrorBlock __nonnull);

@end
