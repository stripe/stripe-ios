//
//  STPPaymentMethodsViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodsViewController.h"

#import "STPAPIClient.h"
#import "STPAddCardViewController+Private.h"
#import "STPAddSourceViewController+Private.h"
#import "STPCard.h"
#import "STPColorUtils.h"
#import "STPCoreViewController+Private.h"
#import "STPCustomer+Stripe_PaymentMethods.h"
#import "STPDispatchFunctions.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentActivityIndicatorView.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPPaymentContext+Private.h"
#import "STPPaymentContext.h"
#import "STPPaymentMethodTuple.h"
#import "STPPaymentMethodType+Private.h"
#import "STPPaymentMethodsInternalViewController.h"
#import "STPPaymentMethodsViewController+Private.h"
#import "STPTheme.h"
#import "STPToken.h"
#import "STPWeakStrongMacros.h"
#import "UIBarButtonItem+Stripe.h"
#import "UINavigationController+Stripe_Completion.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"
#import "UIViewController+Stripe_ParentViewController.h"
#import "UIViewController+Stripe_Promises.h"

@interface STPPaymentMethodsViewController()<STPPaymentMethodsInternalViewControllerDelegate, STPAddCardViewControllerDelegate, STPAddSourceViewControllerDelegate>

@property(nonatomic)STPPaymentConfiguration *configuration;
@property(nonatomic)STPAddress *shippingAddress;
@property(nonatomic)id<STPBackendAPIAdapter> apiAdapter;
@property(nonatomic)STPAPIClient *apiClient;
@property(nonatomic)STPPromise<STPPaymentMethodTuple *> *loadingPromise;
@property(nonatomic, weak)STPPaymentActivityIndicatorView *activityIndicator;
@property(nonatomic, weak)UIViewController *internalViewController;
@property(nonatomic)BOOL loading;

@end

@implementation STPPaymentMethodsViewController

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
                           apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                             delegate:(id<STPPaymentMethodsViewControllerDelegate>)delegate {
    STPPromise<STPPaymentMethodTuple *> *promise = [self retrieveCustomerWithConfiguration:configuration apiAdapter:apiAdapter];
    return [self initWithConfiguration:configuration
                            apiAdapter:apiAdapter
                        loadingPromise:promise
                                 theme:theme
                       shippingAddress:nil
                              delegate:delegate];
}

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                           apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                       loadingPromise:(STPPromise<STPPaymentMethodTuple *> *)loadingPromise
                                theme:(STPTheme *)theme
                      shippingAddress:(STPAddress *)shippingAddress
                             delegate:(id<STPPaymentMethodsViewControllerDelegate>)delegate NS_EXTENSION_UNAVAILABLE("") {
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
        }] onSuccess:^(STPPaymentMethodTuple *tuple) {
            STRONG(self);
            if (tuple.selectedPaymentMethod) {
                [self.delegate paymentMethodsViewController:self
                                     didSelectPaymentMethod:tuple.selectedPaymentMethod];
            }
        }] onFailure:^(NSError *error) {
            STRONG(self);
            [self.delegate paymentMethodsViewController:self didFailToLoadWithError:error];
        }];
    }
    return self;
}

- (STPPromise<STPPaymentMethodTuple *>*)retrieveCustomerWithConfiguration:(STPPaymentConfiguration *)configuration
                                                               apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter {
    STPPromise<STPPaymentMethodTuple *> *promise = [STPPromise new];
    stpDispatchToMainThreadIfNecessary(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:STPNetworkActivityDidBeginNotification object:self];
    });
    [apiAdapter retrieveCustomer:^(STPCustomer * _Nullable customer, NSError * _Nullable error) {
        stpDispatchToMainThreadIfNecessary(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:STPNetworkActivityDidEndNotification object:self];
            if (error) {
                [promise fail:error];
            } else {
                STPPaymentMethodTuple *tuple = [customer stp_paymentMethodTupleWithConfiguration:configuration];
                [promise succeed:tuple];
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
    [self.loadingPromise onSuccess:^(STPPaymentMethodTuple *tuple) {
        STRONG(self);
        if (!self) {
            return;
        }
        UIViewController *internal;
        if (tuple.savedPaymentMethods.count == 0
            && tuple.availablePaymentTypes.count == 1
            && [tuple.availablePaymentTypes firstObject].convertsToSourceAtSelection) {
            // There's only one option, go straight to it if reasonable

            STPPaymentMethodType *paymentType = [tuple.availablePaymentTypes firstObject];

            if ([paymentType isEqual:[STPPaymentMethodType creditCard]]
                && !self.configuration.useSourcesForCreditCards) {
                STPAddCardViewController *addCardViewController = [[STPAddCardViewController alloc] initWithConfiguration:self.configuration theme:self.theme];
                addCardViewController.delegate = self;
                addCardViewController.prefilledInformation = self.prefilledInformation;
                addCardViewController.shippingAddress = self.shippingAddress;
                internal = addCardViewController;
            }
            else {
                STPAddSourceViewController *addSourceViewController = [[STPAddSourceViewController alloc] initWithSourceType:paymentType.sourceType
                                                                                                               configuration:self.configuration
                                                                                                                       theme:self.theme];
                addSourceViewController.delegate = self;
                addSourceViewController.prefilledInformation = self.prefilledInformation;
                addSourceViewController.shippingAddress = self.shippingAddress;
                internal = addSourceViewController;
            }
        }
        else {
            internal = [[STPPaymentMethodsInternalViewController alloc] initWithConfiguration:self.configuration
                                                                                        theme:self.theme
                                                                         prefilledInformation:self.prefilledInformation
                                                                              shippingAddress:self.shippingAddress
                                                                           paymentMethodTuple:tuple
                                                                                     delegate:self];
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
    self.loading = YES;
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

- (void)finishWithPaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    if ([paymentMethod conformsToProtocol:@protocol(STPSourceProtocol)]
        && paymentMethod.paymentMethodType.canBeDefaultSource) {
        stpDispatchToMainThreadIfNecessary(^{
            [[NSNotificationCenter defaultCenter] postNotificationName:STPNetworkActivityDidBeginNotification object:self];
        });
        [self.apiAdapter selectDefaultCustomerSource:(id<STPSourceProtocol>)paymentMethod completion:^(__unused NSError *error) {
            stpDispatchToMainThreadIfNecessary(^{
                [[NSNotificationCenter defaultCenter] postNotificationName:STPNetworkActivityDidEndNotification object:self];
            });
        }];
    }
    [self.delegate paymentMethodsViewController:self didSelectPaymentMethod:paymentMethod];
    [self.delegate paymentMethodsViewControllerDidFinish:self];
}

- (void)internalViewControllerDidSelectPaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    [self finishWithPaymentMethod:paymentMethod];
}

- (void)internalViewControllerDidCreateTokenOrSource:(id<STPSourceProtocol>)tokenOrSource
                                          completion:(STPErrorBlock)completion {
    stpDispatchToMainThreadIfNecessary(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:STPNetworkActivityDidBeginNotification object:self];
    });
    [self.apiAdapter attachSourceToCustomer:tokenOrSource completion:^(NSError *error) {
        STPPromise<STPPaymentMethodTuple *> *promise = [self retrieveCustomerWithConfiguration:self.configuration apiAdapter:self.apiAdapter];
        [promise onSuccess:^(STPPaymentMethodTuple *tuple) {
            stpDispatchToMainThreadIfNecessary(^{
                if ([self.internalViewController isKindOfClass:[STPPaymentMethodsInternalViewController class]]) {
                    STPPaymentMethodsInternalViewController *paymentMethodsVC = (STPPaymentMethodsInternalViewController *)self.internalViewController;
                    [paymentMethodsVC updateWithPaymentMethodTuple:tuple];
                }
            });
        }];

        stpDispatchToMainThreadIfNecessary(^{
            [[NSNotificationCenter defaultCenter] postNotificationName:STPNetworkActivityDidEndNotification object:self];
            completion(error);
            if (!error) {
                if ([tokenOrSource isKindOfClass:[STPToken class]]) {
                    [self finishWithPaymentMethod:((STPToken *)tokenOrSource).card];
                }
                else {
                    [self finishWithPaymentMethod:(id<STPPaymentMethod>)tokenOrSource];
                }
            }
        });
    }];
}

- (void)internalViewControllerDidCancel {
    [self.delegate paymentMethodsViewControllerDidCancel:self];
}

- (void)addCardViewControllerDidCancel:(__unused STPAddCardViewController *)addCardViewController {
    // Add card is only our direct delegate if there are no other payment methods possible
    // and we skipped directly to this screen. In this case, a cancel from it is the same as a cancel to us.
    [self.delegate paymentMethodsViewControllerDidCancel:self];
}

- (void)addCardViewController:(__unused STPAddCardViewController *)addCardViewController
               didCreateToken:(STPToken *)token
                   completion:(STPErrorBlock)completion {
    [self internalViewControllerDidCreateTokenOrSource:token completion:completion];
}

- (void)addSourceViewControllerDidCancel:(__unused STPAddSourceViewController *)addSourceViewController {
    [self.delegate paymentMethodsViewControllerDidFinish:self];
}

- (void)addSourceViewController:(__unused STPAddSourceViewController *)addSourceViewController
                didCreateSource:(STPSource *)source
                     completion:(STPErrorBlock)completion {
    [self internalViewControllerDidCreateTokenOrSource:source completion:completion];
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
