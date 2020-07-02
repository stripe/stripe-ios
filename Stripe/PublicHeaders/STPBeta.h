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
 
 @warning These values may change/break between versions, etc.
 Since these betas may have bugs, we don't recommend using this in production unless your backend can turn off your app's usage of the beta feature.
 */
typedef NS_OPTIONS(NSUInteger, STPBeta) {
    /**
     A value indicating no betas.
     */
    STPBetaNone = 0,

    /**
     Private beta for the Alipay Payment Method. You will also need to contact support to participate in this beta.
     */
    STPBetaAlipay1 = 1<< 0,
};


NS_ASSUME_NONNULL_END
