//
//  STPPaymentMethodCardPresent.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/11/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Details about the Card Present payment method
 */
@interface STPPaymentMethodCardPresent : NSObject <STPAPIResponseDecodable>

@end

NS_ASSUME_NONNULL_END
