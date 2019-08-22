//
//  Constants.m
//  StripeExample
//
//  Created by Jack Flintermann on 8/22/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "Constants.h"

// This can be found at https://dashboard.stripe.com/account/apikeys
NSString *const StripePublishableKey = @"pk_live_L4KL0pF017Jgv9hBaWzk4xoB";

// To set this up, check out https://github.com/stripe/example-ios-backend/tree/v14.0.0
// This should be in the format https://my-shiny-backend.herokuapp.com
NSString *const BackendBaseURL = @"https://yuki-test-wechat-pay.herokuapp.com/"; 

// To learn how to obtain an Apple Merchant ID, head to https://stripe.com/docs/mobile/apple-pay
NSString *const AppleMerchantId = @"whatever"; // TODO: replace nil with your own value
