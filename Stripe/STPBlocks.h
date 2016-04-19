//
//  STPBlocks.h
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPPaymentMethod.h"
#import "STPSource.h"

typedef NS_ENUM(NSUInteger, STPPaymentStatus) {
    STPPaymentStatusSuccess,
    STPPaymentStatusError,
    STPPaymentStatusUserCancellation,
};

typedef void (^STPVoidBlock)();
typedef void (^STPErrorBlock)(NSError * __nullable error);
typedef void (^STPSourceHandlerBlock)(STPPaymentMethodType paymentMethod, id<STPSource> __nonnull source, STPErrorBlock __nonnull completion);
typedef void (^STPPaymentCompletionBlock)(STPPaymentStatus status, NSError * __nullable error);
