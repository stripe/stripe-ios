//
//  STPCardIOProxy.m
//  Stripe
//
//  Created by Ben Guo on 5/12/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCardIOProxy.h"
#import "STPCardParams.h"

@interface STPCardIOSelectors : NSObject
+ (id)initWithPaymentDelegate:id;
+ (BOOL)canReadCardWithCamera;
@property (nonatomic, strong) NSString *cardNumber;
@property (nonatomic, assign, readwrite) BOOL collectExpiry;
@property (nonatomic, assign, readwrite) BOOL collectCVV;
@property (nonatomic, assign, readwrite) BOOL hideCardIOLogo;
@end

@interface STPCardIOProxy ()
@property (nonatomic, weak) id<STPCardIOProxyDelegate>delegate;
@end

@implementation STPCardIOProxy

+ (BOOL)isCardIOAvailable {
#if TARGET_OS_SIMULATOR
    return NO;
#else
    Class kCardIOPaymentViewController = NSClassFromString(@"CardIOPaymentViewController");
    Class kCardIOUtilities = NSClassFromString(@"CardIOUtilities");
    Class kCardIOCreditCardInfo = NSClassFromString(@"CardIOCreditCardInfo");
    if (kCardIOPaymentViewController != nil && kCardIOPaymentViewController != nil && kCardIOCreditCardInfo != nil
        && [kCardIOPaymentViewController instancesRespondToSelector:@selector(initWithPaymentDelegate:)]
        && [kCardIOPaymentViewController instancesRespondToSelector:@selector(setHideCardIOLogo:)]
        && [kCardIOPaymentViewController instancesRespondToSelector:@selector(setCollectCVV:)]
        && [kCardIOPaymentViewController instancesRespondToSelector:@selector(setCollectExpiry:)]
        && [kCardIOCreditCardInfo instancesRespondToSelector:@selector(cardNumber)]
        && [kCardIOUtilities respondsToSelector:@selector(canReadCardWithCamera)]) {
        return [kCardIOUtilities canReadCardWithCamera];
    }
    return NO;
#endif
}

- (instancetype)initWithDelegate:(id<STPCardIOProxyDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)presentCardIOFromViewController:(UIViewController *)viewController {
    Class kCardIOPaymentViewController = NSClassFromString(@"CardIOPaymentViewController");
    id cardIOViewController = [[kCardIOPaymentViewController alloc] initWithPaymentDelegate:self];
    [cardIOViewController setHideCardIOLogo:YES];
    [cardIOViewController setCollectCVV:NO];
    [cardIOViewController setCollectExpiry:NO];
    [viewController presentViewController:cardIOViewController animated:YES completion:nil];
}

- (void)userDidCancelPaymentViewController:(UIViewController *)scanViewController {
    [scanViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)userDidProvideCreditCardInfo:(id)info inPaymentViewController:(UIViewController *)scanViewController {
    [scanViewController dismissViewControllerAnimated:YES completion:^{
        STPCardParams *cardParams = [STPCardParams new];
        cardParams.number = [info cardNumber];
        [self.delegate cardIOProxy:self didFinishWithCardParams:cardParams];
    }];
}

@end
