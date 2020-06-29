//
//  STPBeta.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/19/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 An enumeration of Stripe betas that are supported by the SDK.
 
 @note These values may change/break between versions, etc.
 */
typedef NS_OPTIONS(NSUInteger, STPBeta) {
    /**
     A value indicating no betas.
     */
    STPBetaNone = 0,

    /**
     Private beta for the Alipay Payment Method
     */
    STPBetaAlipay1 = 1<< 0,
};


NS_ASSUME_NONNULL_END
