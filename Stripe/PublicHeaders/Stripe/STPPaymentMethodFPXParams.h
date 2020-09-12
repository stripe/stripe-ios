//
//  STPPaymentMethodFPXParams.h
//  Stripe
//
//  Created by David Estes on 7/30/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPFormEncodable.h"
#import "STPFPXBankBrand.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An object representing parameters used to create an FPX Payment Method
 */
@interface STPPaymentMethodFPXParams : NSObject <STPFormEncodable>

/**
 The customer's bank. Required.
 */
@property (nonatomic, assign) STPFPXBankBrand bank;

/**
 The raw underlying bank string sent to the server.
 
 Generally you should use `bank` instead unless you have a reason not to.
 You can use this if you want to create a param of a bank not yet supported
 by the current version of the SDK's `STPFPXBankBrand` enum.
 
 Setting this to a value not known by the SDK causes `bank` to
 return `STPFPXBankBrandUnknown`
 */
@property (nonatomic, copy, nullable) NSString *rawBankString;

@end

NS_ASSUME_NONNULL_END
