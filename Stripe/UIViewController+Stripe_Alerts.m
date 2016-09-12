//
//  UIViewController+Stripe_Alerts.m
//  Stripe
//
//  Created by Jack Flintermann on 5/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "UIViewController+Stripe_Alerts.h"
#import "NSArray+Stripe_BoundSafe.h"
#import <objc/runtime.h>

#define FAUXPAS_IGNORED_IN_FILE(...)
#define FAUXPAS_IGNORED_ON_LINE(...)

FAUXPAS_IGNORED_IN_FILE(APIAvailability);

@implementation UIViewController (Stripe_Alerts)

- (UIAlertActionStyle)stp_actionStyleFromStripeStyle:(STPAlertStyle)style {
    switch (style) {
        case STPAlertStyleCancel:
            return UIAlertActionStyleCancel;
        case STPAlertStyleDefault:
            return UIAlertActionStyleDefault;
        case STPAlertStyleDestructive:
            return UIAlertActionStyleDestructive;
    }
}

- (void)stp_showAlertWithTitle:(nullable NSString *)title
                       message:(nullable NSString *)message
                        tuples:(nullable NSArray<STPAlertTuple *> *)tuples {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:title
                                                                        message:message
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    for (STPAlertTuple *tuple in tuples) {
        [controller addAction:[UIAlertAction actionWithTitle:tuple.title style:[self stp_actionStyleFromStripeStyle:tuple.style] handler:^(__unused UIAlertAction *alertAction) {
            if (tuple.action) {
                tuple.action();
            }
        }]];
    }
    [self presentViewController:controller animated:YES completion:nil];
}

@end

@implementation STPAlertTuple

+ (instancetype)tupleWithTitle:(NSString *)title
                         style:(STPAlertStyle)style
                        action:(STPVoidBlock)action {
    STPAlertTuple *tuple = [self.class new];
    tuple.title = title;
    tuple.style = style;
    tuple.action = action;
    return tuple;
}

@end

void linkUIViewControllerAlertsCategory(void){}
