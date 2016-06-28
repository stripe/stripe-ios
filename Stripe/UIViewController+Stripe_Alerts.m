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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

@interface STPAlertViewBlockDelegate: NSObject<UIAlertViewDelegate>

@property(nonatomic) NSArray<STPAlertTuple *> *tuples;

@end

@implementation STPAlertViewBlockDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    STPAlertTuple *tuple = [self.tuples stp_boundSafeObjectAtIndex:buttonIndex];
    if (tuple.action) {
        tuple.action();
    }
    alertView.delegate = nil;
}

@end

@interface UIAlertView(Stripe_Blocks)

@property(nonatomic)STPAlertViewBlockDelegate *stp_blockDelegate FAUXPAS_IGNORED_ON_LINE(StrongDelegate);

@end

@implementation UIAlertView(Stripe_Blocks)

@dynamic stp_blockDelegate;

- (void)setStp_blockDelegate:(STPAlertViewBlockDelegate *)stp_blockDelegate {
    objc_setAssociatedObject(self, @selector(stp_blockDelegate), stp_blockDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (STPAlertViewBlockDelegate *)stp_blockDelegate {
    return objc_getAssociatedObject(self, @selector(stp_blockDelegate));
}

@end

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
    if ([UIAlertController class]) {
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
    } else {
        STPAlertViewBlockDelegate *blockDelegate = [STPAlertViewBlockDelegate new];
        blockDelegate.tuples = tuples;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                             message:message
                                                            delegate:blockDelegate
                                                   cancelButtonTitle:nil
                                                   otherButtonTitles:nil];
        for (STPAlertTuple *tuple in tuples) {
            NSInteger index = [alertView addButtonWithTitle:tuple.title];
            if (tuple.style == STPAlertStyleCancel) {
                alertView.cancelButtonIndex = index;
            }
        }
        alertView.stp_blockDelegate = blockDelegate;
        [alertView show];
    }
}

#pragma clang diagnostic pop

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
