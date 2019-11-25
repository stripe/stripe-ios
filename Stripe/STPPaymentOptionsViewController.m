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
#import "STPCustomerContext+Private.h"
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
                NSString *defaultPaymentMethod = self.defaultPaymentMethod;
                if (defaultPaymentMethod == nil && [apiAdapter isKindOfClass:[STPCustomerContext class]]) {
                    // Retrieve the last selected payment method saved by STPCustomerContext
                    [((STPCustomerContext *)apiAdapter) retrieveLastSelectedPaymentMethodIDForCustomerWithCompletion:^(NSString * _Nullable paymentMethodID, NSError * _Nullable __unused _) {
                        STPPaymentOptionTuple *paymentTuple = [STPPaymentOptionTuple tupleFilteredForUIWithPaymentMethods:paymentMethods selectedPaymentMethod:paymentMethodID configuration:configuration];
                        [promise succeed:paymentTuple];
                    }];
                }
                STPPaymentOptionTuple *paymentTuple = [STPPaymentOptionTuple tupleFilteredForUIWithPaymentMethods:paymentMethods selectedPaymentMethod:defaultPaymentMethod configuration:configuration];
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
    
    __weak typeof(self) weakSelf = self;
    [self.loadingPromise onSuccess:^(STPPaymentOptionTuple *tuple) {
        __strong typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        UIViewController *internal;
        if (tuple.paymentOptions.count > 0) {
            STPCustomerContext *customerContext = ([strongSelf.apiAdapter isKindOfClass:[STPCustomerContext class]]) ? (STPCustomerContext *)strongSelf.apiAdapter : nil;
            
            STPPaymentOptionsInternalViewController *payMethodsInternal = [[STPPaymentOptionsInternalViewController alloc] initWithConfiguration:strongSelf.configuration
                                                                                                                                 customerContext:customerContext
                                                                                                                                           theme:strongSelf.theme
                                                                                                                            prefilledInformation:strongSelf.prefilledInformation
                                                                                                                                 shippingAddress:strongSelf.shippingAddress
                                                                                                                              paymentOptionTuple:tuple
                                                                                                                                        delegate:strongSelf];
            if (strongSelf.paymentOptionsViewControllerFooterView) {
                payMethodsInternal.customFooterView = strongSelf.paymentOptionsViewControllerFooterView;
            }
            if (strongSelf.addCardViewControllerFooterView) {
                payMethodsInternal.addCardViewControllerCustomFooterView = strongSelf.addCardViewControllerFooterView;
            }
            internal = payMethodsInternal;
        } else {
            STPAddCardViewController *addCardViewController = [[STPAddCardViewController alloc] initWithConfiguration:strongSelf.configuration theme:self.theme];
            addCardViewController.delegate = strongSelf;
            addCardViewController.prefilledInformation = strongSelf.prefilledInformation;
            addCardViewController.shippingAddress = strongSelf.shippingAddress;
            internal = addCardViewController;
            
            if (strongSelf.addCardViewControllerFooterView) {
                addCardViewController.customFooterView = strongSelf.addCardViewControllerFooterView;
                
            }
        }
        
        internal.stp_navigationItemProxy = strongSelf.navigationItem;
        [strongSelf addChildViewController:internal];
        internal.view.alpha = 0;
        [strongSelf.view insertSubview:internal.view belowSubview:strongSelf.activityIndicator];
        [strongSelf.view addSubview:internal.view];
        internal.view.frame = strongSelf.view.bounds;
        [internal didMoveToParentViewController:strongSelf];
        [UIView animateWithDuration:0.2 animations:^{
            strongSelf.activityIndicator.alpha = 0;
            internal.view.alpha = 1;
        } completion:^(__unused BOOL finished) {
            strongSelf.activityIndicator.animating = NO;
        }];
        [strongSelf.navigationItem setRightBarButtonItem:internal.stp_navigationItemProxy.rightBarButtonItem animated:YES];
        strongSelf.internalViewController = internal;
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
    BOOL isReusablePaymentMethod = [paymentOption isKindOfClass:[STPPaymentMethod class]] && ((STPPaymentMethod *)paymentOption).isReusable;
    
    if ([self.apiAdapter isKindOfClass:[STPCustomerContext class]]) {
        if (isReusablePaymentMethod) {
            // Save the payment method
            STPPaymentMethod *paymentMethod = (STPPaymentMethod *)paymentOption;
            [((STPCustomerContext *)self.apiAdapter) saveLastSelectedPaymentMethodIDForCustomer:paymentMethod.stripeId completion:nil];
        } else {
            // The customer selected something else (like Apple Pay)
            [((STPCustomerContext *)self.apiAdapter) saveLastSelectedPaymentMethodIDForCustomer:nil completion:nil];
        }
    }
    
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

- (void)internalViewControllerDidCreatePaymentOption:(id<STPPaymentOption>)paymentOption completion:(STPErrorBlock)completion {
    if (!paymentOption.reusable) {
        // Don't save a non-reusable payment option
        [self finishWithPaymentOption:paymentOption];
        return;
    }
    STPPaymentMethod *paymentMethod = (STPPaymentMethod *)paymentOption;
    [self.apiAdapter attachPaymentMethodToCustomer:paymentMethod completion:^(NSError *error) {
        stpDispatchToMainThreadIfNecessary(^{
            completion(error);
            if (!error) {
                STPPromise<STPPaymentOptionTuple *> *promise = [self retrievePaymentMethodsWithConfiguration:self.configuration apiAdapter:self.apiAdapter];
                __weak typeof(self) weakSelf = self;
                [promise onSuccess:^(STPPaymentOptionTuple *tuple) {
                    __strong typeof(self) strongSelf = weakSelf;
                    if (!strongSelf) {
                        return;
                    }
                    STPPaymentOptionTuple *paymentTuple = [STPPaymentOptionTuple tupleWithPaymentOptions:tuple.paymentOptions selectedPaymentOption:paymentMethod];
                    if ([strongSelf.internalViewController isKindOfClass:[STPPaymentOptionsInternalViewController class]]) {
                        STPPaymentOptionsInternalViewController *paymentOptionsVC = (STPPaymentOptionsInternalViewController *)strongSelf.internalViewController;
                        [paymentOptionsVC updateWithPaymentOptionTuple:paymentTuple];
                    }
                }];
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
    [self internalViewControllerDidCreatePaymentOption:paymentMethod completion:completion];
}
    
- (void)dismissWithCompletion:(STPVoidBlock)completion {
    if ([self stp_isAtRootOfNavigationController]) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:completion];
    } else {
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
        
        __weak typeof(self) weakSelf = self;
        [[[self.stp_didAppearPromise voidFlatMap:^STPPromise * _Nonnull{
            return loadingPromise;
        }] onSuccess:^(STPPaymentOptionTuple *tuple) {
            __strong typeof(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            
            if (tuple.selectedPaymentOption) {
                if ([strongSelf.delegate respondsToSelector:@selector(paymentOptionsViewController:didSelectPaymentOption:)]) {
                    [strongSelf.delegate paymentOptionsViewController:strongSelf
                                               didSelectPaymentOption:tuple.selectedPaymentOption];
                }
            }
        }] onFailure:^(NSError *error) {
            __strong typeof(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            
            [strongSelf.delegate paymentOptionsViewController:strongSelf didFailToLoadWithError:error];
        }];
    }
    return self;
}
    
    @end
