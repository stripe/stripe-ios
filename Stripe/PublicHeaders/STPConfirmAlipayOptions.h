//
//  STPConfirmAlipayOptions.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 5/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Alipay options to pass to `STPConfirmPaymentMethodOptions``
 */
@interface STPConfirmAlipayOptions : NSObject <STPFormEncodable>

/**
 The app bundle ID.
 @note This is automatically populated by the SDK.
 */
@property (nonatomic, readonly) NSString *appBundleID;

/**
 The app version.
 @note This is automatically populated by the SDK.
 */
@property (nonatomic, readonly) NSString *appVersionKey;

@end

NS_ASSUME_NONNULL_END
