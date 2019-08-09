//
//  STPPaymentOptionsViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentOptionsViewController.h"

#import "STPAPIClient.h"
#import "STPAddCardViewController+Private.h"
#import "STPCard.h"
#import "STPColorUtils.h"
#import "STPCoreViewController+Private.h"
#import "STPDispatchFunctions.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentActivityIndicatorView.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPPaymentContext+Private.h"
#import "STPPaymentContext.h"
#import "STPPaymentOptionTuple.h"
#import "STPPaymentOptionsInternalViewController.h"
#import "STPPaymentOptionsViewController+Private.h"
#import "STPTheme.h"
#import "STPWeakStrongMacros.h"
#import "UIBarButtonItem+Stripe.h"
#import "UINavigationController+Stripe_Completion.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"
#import "UIViewController+Stripe_ParentViewController.h"
#import "UIViewController+Stripe_Promises.h"

@interface STPPaymentOptionsViewController()<STPPaymentOptionsInternalViewControllerDelegate, STPAddCardViewControllerDelegate>

@property (nonatomic) STPPaymentConfiguration *configuration;
@property (nonatomic) STPAddress *shippingAddress;
@property (nonatomic) id<STPBackendAPIAdapter> apiAdapter;
@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic) STPPromise<STPPaymentOptionTuple *> *loadingPromise;
@property (nonatomic, weak) STPPaymentActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) UIViewController *internalViewController;

@end

@implementation STPPaymentOptionsViewController

- (instancetype)initWithPaymentContext:(STPPaymentContext *)paymentContext {
    return [self initWithConfiguration:paymentContext.configuration
                            apiAdapter:paymentContext.apiAdapter
                        loadingPromise:paymentContext.currentValuePromise
                                 theme:paymentContext.theme
                       shippingAddress:paymentContext.shippingAddress
                              delegate:paymentContext];
}

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                                theme:(STPTheme *)theme
                      customerContext:(STPCustomerContext *)customerContext
                             delegate:(id<STPPaymentOptionsViewControllerDelegate>)delegate {
    return [self initWithConfiguration:configuration theme:theme apiAdapter:customerContext delegate:delegate];
}

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                                theme:(STPTheme *)theme
                           apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                             delegate:(id<STPPaymentOptionsViewControllerDelegate>)delegate {
    STPPromise<STPPaymentOptionTuple *> *promise = [self retrievePaymentMethodsWithConfiguration:configuration apiAdapter:apiAdapter];
    return [self initWithConfiguration:configuration
                            apiAdapter:apiAdapter
                        loadingPromise:promise
                                 theme:theme
                       shippingAddress:nil
                              delegate:delegate];
}

- (STPPromise<STPPaymentOptionTuple *>*)retrievePaymentMethodsWithConfiguration:(STPPaymentConfiguration *)configuration
                                                                     apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter {
    STPPromise<STPPaymentOptionTuple *> *promise = [STPPromise new];
    [apiAdapter listPaymentMethodsForCustomerWithCompletion:^(NSArray<STPPaymentMethod *> * _Nullable paymentMethods, NSError * _Nullable error) {
        stpDispatchToMainThreadIfNecessary(^{
            if (error) {
                [promise fail:error];
            } else {
                STPPaymentOptionTuple *paymentTuple = [STPPaymentOptionTuple tupleFilteredForUIWithPaymentMethods:paymentMethods selectedPaymentMethod:self.defaultPaymentMethod configuration:configuration];
                [promise succeed:paymentTuple];
            }
        });
    }];
    return promise;
}

- (void)createAndSetupViews {
    [super createAndSetupViews];

    STPPaymentActivityIndicatorView *activityIndicator = [STPPaymentActivityIndicatorView new];
    activityIndicator.animating = YES;
    [self.view addSubview:activityIndicator];
    self.activityIndicator = activityIndicator;

    WEAK(self);
    [self.loadingPromise onSuccess:^(STPPaymentOptionTuple *tuple) {
        STRONG(self);
        if (!self) {
            return;
        }
        UIViewController *internal;
        if (tuple.paymentOptions.count > 0) {
            STPCustomerContext *customerContext = ([self.apiAdapter isKindOfClass:[STPCustomerContext class]]) ? (STPCustomerContext *)self.apiAdapter : nil;

            STPPaymentOptionsInternalViewController *payMethodsInternal = [[STPPaymentOptionsInternalViewController alloc] initWithConfiguration:self.configuration
                                                                                                                                 customerContext:customerContext
                                                                                                                                           theme:self.theme
                                                                                                                            prefilledInformation:self.prefilledInformation
                                                                                                                                 shippingAddress:self.shippingAddress
                                                                                                                              paymentOptionTuple:tuple
                                                                                                                                        delegate:self];
            if (self.paymentOptionsViewControllerFooterView) {
                payMethodsInternal.customFooterView = self.paymentOptionsViewControllerFooterView;
            }
            if (self.addCardViewControllerFooterView) {
                payMethodsInternal.addCardViewControllerCustomFooterView = self.addCardViewControllerFooterView;
            }
            internal = payMethodsInternal;
        }
        else {
            STPAddCardViewController *addCardViewController = [[STPAddCardViewController alloc] initWithConfiguration:self.configuration theme:self.theme];
            addCardViewController.delegate = self;
            addCardViewController.prefilledInformation = self.prefilledInformation;
            addCardViewController.shippingAddress = self.shippingAddress;
            internal = addCardViewController;

            if (self.addCardViewControllerFooterView) {
                addCardViewController.customFooterView = self.addCardViewControllerFooterView;

            }
        }
        
        internal.stp_navigationItemProxy = self.navigationItem;
        [self addChildViewController:internal];
        internal.view.alpha = 0;
        [self.view insertSubview:internal.view belowSubview:self.activityIndicator];
        [self.view addSubview:internal.view];
        internal.view.frame = self.view.bounds;
        [internal didMoveToParentViewController:self];
        [UIView animateWithDuration:0.2 animations:^{
            self.activityIndicator.alpha = 0;
            internal.view.alpha = 1;
        } completion:^(__unused BOOL finished) {
            self.activityIndicator.animating = NO;
        }];
        [self.navigationItem setRightBarButtonItem:internal.stp_navigationItemProxy.rightBarButtonItem animated:YES];
        self.internalViewController = internal;
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat centerX = (self.view.frame.size.width - self.activityIndicator.frame.size.width) / 2;
    CGFloat centerY = (self.view.frame.size.height - self.activityIndicator.frame.size.height) / 2;
    self.activityIndicator.frame = CGRectMake(centerX, centerY, self.activityIndicator.frame.size.width, self.activityIndicator.frame.size.height);
    self.internalViewController.view.frame = self.view.bounds;
}

- (void)updateAppearance {
    [super updateAppearance];

    self.activityIndicator.tintColor = self.theme.accentColor;
}

- (void)finishWithPaymentOption:(id<STPPaymentOption>)paymentOption {
    if ([self.delegate respondsToSelector:@selector(paymentOptionsViewController:didSelectPaymentOption:)]) {
        [self.delegate paymentOptionsViewController:self didSelectPaymentOption:paymentOption];
    }
    [self.delegate paymentOptionsViewControllerDidFinish:self];
}

- (void)internalViewControllerDidSelectPaymentOption:(id<STPPaymentOption>)paymentOption {
    [self finishWithPaymentOption:paymentOption];
}

- (void)internalViewControllerDidDeletePaymentOption:(id<STPPaymentOption>)paymentOption {
    if ([self.delegate isKindOfClass:[STPPaymentContext class]]) {
        // Notify payment context to update its copy of payment methods
        STPPaymentContext *paymentContext = (STPPaymentContext *)self.delegate;
        [paymentContext removePaymentOption:paymentOption];
    }
}

- (void)internalViewControllerDidCreatePaymentMethod:(STPPaymentMethod *)paymentMethod completion:(STPErrorBlock)completion {
    [self.apiAdapter attachPaymentMethodToCustomer:paymentMethod completion:^(NSError *error) {
        stpDispatchToMainThreadIfNecessary(^{
            completion(error);
            if (!error) {
                [self finishWithPaymentOption:(id<STPPaymentOption>)paymentMethod];
            }
        });
    }];
}

- (void)internalViewControllerDidCancel {
    [self.delegate paymentOptionsViewControllerDidCancel:self];
}

- (void)handleCancelTapped:(__unused id)sender {
    [self.delegate paymentOptionsViewControllerDidCancel:self];
}

- (void)addCardViewControllerDidCancel:(__unused STPAddCardViewController *)addCardViewController {
    // Add card is only our direct delegate if there are no other payment methods possible
    // and we skipped directly to this screen. In this case, a cancel from it is the same as a cancel to us.
    [self.delegate paymentOptionsViewControllerDidCancel:self];
}

- (void)addCardViewController:(__unused STPAddCardViewController *)addCardViewController
       didCreatePaymentMethod:(STPPaymentMethod *)paymentMethod
                   completion:(STPErrorBlock)completion {
    [self internalViewControllerDidCreatePaymentMethod:paymentMethod completion:completion];
}

- (void)dismissWithCompletion:(STPVoidBlock)completion {
    if ([self stp_isAtRootOfNavigationController]) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:completion];
    }
    else {
        UIViewController *previous = self.navigationController.viewControllers.firstObject;
        for (UIViewController *viewController in self.navigationController.viewControllers) {
            if (viewController == self) {
                break;
            }
            previous = viewController;
        }
        [self.navigationController stp_popToViewController:previous animated:YES completion:completion];
    }
}

@end

@implementation STPPaymentOptionsViewController (Private)

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                           apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                       loadingPromise:(STPPromise<STPPaymentOptionTuple *> *)loadingPromise
                                theme:(STPTheme *)theme
                      shippingAddress:(STPAddress *)shippingAddress
                             delegate:(id<STPPaymentOptionsViewControllerDelegate>)delegate {
    self = [super initWithTheme:theme];
    if (self) {
        _configuration = configuration;
        _shippingAddress = shippingAddress;
        _apiClient = [[STPAPIClient alloc] initWithPublishableKey:configuration.publishableKey];
        _apiAdapter = apiAdapter;
        _loadingPromise = loadingPromise;
        _delegate = delegate;

        self.navigationItem.title = STPLocalizedString(@"Loading…", @"Title for screen when data is still loading from the network.");

        WEAK(self);
        [[[self.stp_didAppearPromise voidFlatMap:^STPPromise * _Nonnull{
            return loadingPromise;
        }] onSuccess:^(STPPaymentOptionTuple *tuple) {
            STRONG(self);
            if (!self) {
                return;
            }

            if (tuple.selectedPaymentOption) {
                if ([self.delegate respondsToSelector:@selector(paymentOptionsViewController:didSelectPaymentOption:)]) {
                    [self.delegate paymentOptionsViewController:self
                                         didSelectPaymentOption:tuple.selectedPaymentOption];
                }
            }
        }] onFailure:^(NSError *error) {
            STRONG(self);
            if (!self) {
                return;
            }

            [self.delegate paymentOptionsViewController:self didFailToLoadWithError:error];
        }];
    }
    return self;
}

@end
