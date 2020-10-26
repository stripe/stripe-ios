//
//  STPCustomerContext+Private.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 11/19/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>

NS_ASSUME_NONNULL_BEGIN

@interface STPCustomerContext ()

- (void)saveLastSelectedPaymentMethodIDForCustomer:(nullable NSString *)paymentMethodID completion:(nullable STPErrorBlock)completion;

- (void)retrieveLastSelectedPaymentMethodIDForCustomerWithCompletion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion;
@end

NS_ASSUME_NONNULL_END
