//
//  STPCardIOAdapter.h
//  Stripe
//
//  Created by Ben Guo on 5/12/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class STPCardIOProxy, STPPaymentMethodCardParams;

@protocol STPCardIOProxyDelegate <NSObject>
- (void)cardIOProxy:(STPCardIOProxy *)proxy didFinishWithCardParams:(STPPaymentMethodCardParams *)cardParams;
@end

@interface STPCardIOProxy : NSObject

+ (BOOL)isCardIOAvailable;
- (instancetype)init __attribute__((unavailable("Use initWithDelegate")));
- (instancetype)initWithDelegate:(id<STPCardIOProxyDelegate>)delegate;
- (void)presentCardIOFromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
