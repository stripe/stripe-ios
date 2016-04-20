//
//  STPPaymentContext.h
//  Stripe
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "STPPaymentMethod.h"
#import "STPBlocks.h"

NS_ASSUME_NONNULL_BEGIN

@class STPPaymentContext, STPAPIClient;
@protocol STPBackendAPIAdapter, STPPaymentMethod;

@protocol STPPaymentContextDelegate <NSObject>

- (void)paymentContextDidBeginLoading:(STPPaymentContext *)paymentContext;
- (void)paymentContext:(STPPaymentContext *)paymentContext selectedPaymentMethodDidChange:(id<STPPaymentMethod>)paymentMethod;
- (void)paymentContextDidEndLoading:(STPPaymentContext *)paymentContext;

@end

@interface STPPaymentContext : NSObject

- (instancetype)initWithAPIAdapter:(id<STPBackendAPIAdapter>)apiAdapter
           supportedPaymentMethods:(STPPaymentMethodType)supportedPaymentMethods;

@property(nonatomic)STPAPIClient *apiClient;
@property(nonatomic, readonly)id<STPBackendAPIAdapter> apiAdapter;
@property(nonatomic, readonly)STPPaymentMethodType supportedPaymentMethods;

@property(nonatomic, weak, nullable)id<STPPaymentContextDelegate> delegate;
@property(nonatomic, readonly, getter=isLoading)BOOL loading;
@property(nonatomic)id<STPPaymentMethod> selectedPaymentMethod;
@property(nonatomic)NSArray<id<STPPaymentMethod>> *paymentMethods;

@property(nonatomic)NSInteger paymentAmount;
@property(nonatomic)NSString *paymentCurrency;
@property(nonatomic)NSString *merchantName;
@property(nonatomic)NSString *appleMerchantIdentifier;

- (void)performInitialLoad;
- (void)requestPaymentFromViewController:(UIViewController *)fromViewController
                           sourceHandler:(STPSourceHandlerBlock)sourceHandler
                              completion:(STPPaymentCompletionBlock)completion;


@end

NS_ASSUME_NONNULL_END
