//
//  STPPaymentMethodCardWallet+Private.h
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodCardWallet.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentMethodCardWallet (Private)

+ (STPPaymentMethodCardWalletType)typeFromString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
