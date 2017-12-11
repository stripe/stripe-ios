//
//  STPCardIOProxy.m
//  Stripe
//
//  Created by Ben Guo on 5/12/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCardIOProxy.h"

#import "FauxPasAnnotations.h"
#import "STPCardParams.h"
#import "STPAnalyticsClient.h"

@protocol STPClassProxy
+ (Class)proxiedClass;
+ (BOOL)proxiedClassExists;
@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@interface STPCardIOUtilitiesProxy : NSObject <STPClassProxy>
+ (BOOL)canReadCardWithCamera;
@end

@implementation STPCardIOUtilitiesProxy
+ (Class)proxiedClass {
    return NSClassFromString(@"CardIOUtilities");
}
+ (BOOL)proxiedClassExists {
    Class proxiedClass = [self proxiedClass];
    return proxiedClass && [proxiedClass respondsToSelector:@selector(canReadCardWithCamera)];
}
@end

@interface STPCardIOCreditCardInfoProxy : NSObject <STPClassProxy>
@property (nonatomic, strong) NSString *cardNumber;
@property (nonatomic, assign, readwrite) NSUInteger expiryMonth;
@property (nonatomic, assign, readwrite) NSUInteger expiryYear;
@property (nonatomic, copy, readwrite) NSString *cvv;
@end

@implementation STPCardIOCreditCardInfoProxy
+ (Class)proxiedClass {
    return NSClassFromString(@"CardIOCreditCardInfo");
}
+ (BOOL)proxiedClassExists {
    Class proxiedClass = [self proxiedClass];
    return proxiedClass
    && [proxiedClass instancesRespondToSelector:@selector(cardNumber)]
    && [proxiedClass instancesRespondToSelector:@selector(expiryMonth)]
    && [proxiedClass instancesRespondToSelector:@selector(expiryYear)]
    && [proxiedClass instancesRespondToSelector:@selector(cvv)];
}
@end

@interface STPCardIOPaymentViewControllerProxy : UIViewController <STPClassProxy>
+ (id)initWithPaymentDelegate:id;
@property (nonatomic, assign, readwrite) BOOL hideCardIOLogo;
@property (nonatomic, assign, readwrite) BOOL disableManualEntryButtons;
@property (nonatomic, assign, readwrite) CGFloat scannedImageDuration;
@end

@implementation STPCardIOPaymentViewControllerProxy
+ (Class)proxiedClass {
    return NSClassFromString(@"CardIOPaymentViewController");
}
+ (BOOL)proxiedClassExists {
    Class proxiedClass = [self proxiedClass];
    return proxiedClass
    && [proxiedClass instancesRespondToSelector:@selector(initWithPaymentDelegate:)]
    && [proxiedClass instancesRespondToSelector:@selector(setHideCardIOLogo:)]
    && [proxiedClass instancesRespondToSelector:@selector(setDisableManualEntryButtons:)]
    && [proxiedClass instancesRespondToSelector:@selector(setScannedImageDuration:)];
}
@end
#pragma clang diagnostic pop

@interface STPCardIOProxy ()
@property (nonatomic, weak) id<STPCardIOProxyDelegate>delegate;
@end

@implementation STPCardIOProxy

+ (BOOL)isCardIOAvailable {
#if TARGET_OS_SIMULATOR
    return NO;
#else
    if ([STPCardIOPaymentViewControllerProxy proxiedClassExists]
        && [STPCardIOCreditCardInfoProxy proxiedClassExists]
        && [STPCardIOUtilitiesProxy proxiedClassExists]) {
        return [[STPCardIOUtilitiesProxy proxiedClass] canReadCardWithCamera];
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
    STPCardIOPaymentViewControllerProxy *cardIOViewController = [[[STPCardIOPaymentViewControllerProxy proxiedClass] alloc] initWithPaymentDelegate:self];
    cardIOViewController.hideCardIOLogo = YES;
    cardIOViewController.disableManualEntryButtons = YES;
    cardIOViewController.scannedImageDuration = 0;
    [viewController presentViewController:cardIOViewController animated:YES completion:nil];
}

- (void)userDidCancelPaymentViewController:(UIViewController *)scanViewController { FAUXPAS_IGNORED_ON_LINE(UnusedMethod)
    [scanViewController dismissViewControllerAnimated:YES completion:nil];
    [[STPAnalyticsClient sharedClient] addAdditionalInfo:@"cardio_canceled"];
}

- (void)userDidProvideCreditCardInfo:(STPCardIOCreditCardInfoProxy *)info inPaymentViewController:(UIViewController *)scanViewController { FAUXPAS_IGNORED_ON_LINE(UnusedMethod)
    [scanViewController dismissViewControllerAnimated:YES completion:^{
        STPCardParams *cardParams = [STPCardParams new];
        cardParams.number = info.cardNumber;
        cardParams.expMonth = info.expiryMonth;
        cardParams.expYear = info.expiryYear;
        cardParams.cvc = info.cvv;
        [self.delegate cardIOProxy:self didFinishWithCardParams:cardParams];
        [[STPAnalyticsClient sharedClient] addAdditionalInfo:@"cardio_used"];
    }];
}

@end
