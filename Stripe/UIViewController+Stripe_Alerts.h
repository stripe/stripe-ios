//
//  UIViewController+Stripe_Alerts.h
//  Stripe
//
//  Created by Jack Flintermann on 5/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPBlocks.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, STPAlertStyle) {
    STPAlertStyleDefault = 0,
    STPAlertStyleCancel,
    STPAlertStyleDestructive,
};

@interface STPAlertTuple : NSObject

@property(nonatomic, copy)NSString *title;
@property(nonatomic, copy, nullable)STPVoidBlock action;
@property(nonatomic, assign)STPAlertStyle style;

+ (instancetype)tupleWithTitle:(NSString *)title
                         style:(STPAlertStyle)style
                        action:(nullable STPVoidBlock)action;

@end

@interface UIViewController (Stripe_Alerts)

- (void)stp_showAlertWithTitle:(nullable NSString *)title
                       message:(nullable NSString *)message
                        tuples:(nullable NSArray<STPAlertTuple *> *)tuples;
@end

NS_ASSUME_NONNULL_END

void linkUIViewControllerAlertsCategory(void);
