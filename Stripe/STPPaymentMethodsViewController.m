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
#import "STPCard.h"
#import "STPColorUtils.h"
#import "STPCoreViewController+Private.h"
#import "STPDispatchFunctions.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentActivityIndicatorView.h"
#import "STPPaymentConfiguration+Private.h"
#import "STPPaymentContext+Private.h"
#import "STPPaymentContext.h"
#import "STPPaymentMethodTuple.h"
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

@interface STPPaymentMethodsViewController()<STPPaymentMethodsInternalViewControllerDelegate, STPAddCardViewControllerDelegate>

@property(nonatomic)STPPaymentConfiguration *configuration;
@property(nonatomic)STPAddress *shippingAddress;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
@property(nonatomic)id<STPBackendAPIAdapter> apiAdapter;
#pragma clang diagnostic pop
@property(nonatomic)STPAPIClient *apiClient;
@property(nonatomic)STPPromise<STPPaymentMethodTuple *> *loadingPromise;
@property(nonatomic, weak)STPPaymentActivityIndicatorView *activityIndicator;
@property(nonatomic, weak)UIViewController *internalViewController;
@property(nonatomic)BOOL loading;

@end

@implementation STPPaymentMethodsViewController

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
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
                             delegate:(id<STPPaymentMethodsViewControllerDelegate>)delegate {
    return [self initWithConfiguration:configuration theme:theme apiAdapter:customerContext delegate:delegate];
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

- (STPPromise<STPPaymentMethodTuple *>*)retrieveCustomerWithConfiguration:(STPPaymentConfiguration *)configuration
                                                               apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter {
    STPPromise<STPPaymentMethodTuple *> *promise = [STPPromise new];
    [apiAdapter retrieveCustomer:^(STPCustomer * _Nullable customer, NSError * _Nullable error) {
        stpDispatchToMainThreadIfNecessary(^{
            if (error) {
                [promise fail:error];
            } else {
                STPCard *selectedCard;
                NSMutableArray<STPCard *> *cards = [NSMutableArray array];
                for (id<STPSourceProtocol> source in customer.sources) {
                    if ([source isKindOfClass:[STPCard class]]) {
                        STPCard *card = (STPCard *)source;
                        [cards addObject:card];
                        if ([card.stripeID isEqualToString:customer.defaultSource.stripeID]) {
                            selectedCard = card;
                        }
                    }
                }
                STPCardTuple *cardTuple = [STPCardTuple tupleWithSelectedCard:selectedCard cards:cards];
                STPPaymentMethodTuple *tuple = [STPPaymentMethodTuple tupleWithCardTuple:cardTuple
                                                                         applePayEnabled:configuration.applePayEnabled];
                [promise succeed:tuple];
            }
        });
    }];
    return promise;
}
#pragma clang diagnostic pop

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
        if (tuple.paymentMethods.count > 0) {
            STPCustomerContext *customerContext = ([self.apiAdapter isKindOfClass:[STPCustomerContext class]]) ? (STPCustomerContext *)self.apiAdapter : nil;

            internal = [[STPPaymentMethodsInternalViewController alloc] initWithConfiguration:self.configuration
                                                                              customerContext:customerContext
                                                                                        theme:self.theme
                                                                         prefilledInformation:self.prefilledInformation
                                                                              shippingAddress:self.shippingAddress
                                                                           paymentMethodTuple:tuple
                                                                                     delegate:self];
        } else {
            STPAddCardViewController *addCardViewController = [[STPAddCardViewController alloc] initWithConfiguration:self.configuration theme:self.theme];
            addCardViewController.delegate = self;
            addCardViewController.prefilledInformation = self.prefilledInformation;
            addCardViewController.shippingAddress = self.shippingAddress;
            internal = addCardViewController;
            
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
    if ([paymentMethod isKindOfClass:[STPCard class]]) {
        // Make this payment method the default source
        [self.apiAdapter selectDefaultCustomerSource:(STPCard *)paymentMethod completion:^(__unused NSError *error) {
            // Reload the internal payment methods view controller with the updated customer
            STPPromise<STPPaymentMethodTuple *> *promise = [self retrieveCustomerWithConfiguration:self.configuration apiAdapter:self.apiAdapter];
            [promise onSuccess:^(STPPaymentMethodTuple *tuple) {
                stpDispatchToMainThreadIfNecessary(^{
                    if ([self.internalViewController isKindOfClass:[STPPaymentMethodsInternalViewController class]]) {
                        STPPaymentMethodsInternalViewController *paymentMethodsVC = (STPPaymentMethodsInternalViewController *)self.internalViewController;
                        [paymentMethodsVC updateWithPaymentMethodTuple:tuple];
                    }
                });
            }];
        }];
    }
    if ([self.delegate respondsToSelector:@selector(paymentMethodsViewController:didSelectPaymentMethod:)]) {
        [self.delegate paymentMethodsViewController:self didSelectPaymentMethod:paymentMethod];
    }
    [self.delegate paymentMethodsViewControllerDidFinish:self];
}

- (void)internalViewControllerDidSelectPaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    [self finishWithPaymentMethod:paymentMethod];
}

- (void)internalViewControllerDidDeletePaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    if ([self.delegate isKindOfClass:[STPPaymentContext class]]) {
        // Notify payment context to update its copy of payment methods
        STPPaymentContext *paymentContext = (STPPaymentContext *)self.delegate;
        [paymentContext removePaymentMethod:paymentMethod];
    }
}

- (void)internalViewControllerDidCreateToken:(STPToken *)token completion:(STPErrorBlock)completion {
    [self.apiAdapter attachSourceToCustomer:token completion:^(NSError *error) {
        stpDispatchToMainThreadIfNecessary(^{
            completion(error);
            if (!error) {
                [self finishWithPaymentMethod:token.card];
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
    [self internalViewControllerDidCreateToken:token completion:completion];
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

@implementation STPPaymentMethodsViewController (Private)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                           apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                       loadingPromise:(STPPromise<STPPaymentMethodTuple *> *)loadingPromise
                                theme:(STPTheme *)theme
                      shippingAddress:(STPAddress *)shippingAddress
                             delegate:(id<STPPaymentMethodsViewControllerDelegate>)delegate {
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
            if (!self) {
                return;
            }

            if (tuple.selectedPaymentMethod) {
                if ([self.delegate respondsToSelector:@selector(paymentMethodsViewController:didSelectPaymentMethod:)]) {
                    [self.delegate paymentMethodsViewController:self
                                         didSelectPaymentMethod:tuple.selectedPaymentMethod];
                }
            }
        }] onFailure:^(NSError *error) {
            STRONG(self);
            if (!self) {
                return;
            }

            [self.delegate paymentMethodsViewController:self didFailToLoadWithError:error];
        }];
    }
    return self;
}
#pragma clang diagnostic pop

@end
