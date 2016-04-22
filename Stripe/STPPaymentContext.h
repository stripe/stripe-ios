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
#import "STPAddress.h"

NS_ASSUME_NONNULL_BEGIN

@class STPPaymentContext, STPAPIClient;
@protocol STPBackendAPIAdapter, STPPaymentMethod;

typedef void (^STPSourceHandlerBlock)(STPPaymentMethodType paymentMethod, id<STPSource> __nonnull source, STPErrorBlock __nonnull completion);
typedef void (^STPPaymentCompletionBlock)(STPPaymentStatus status, NSError * __nullable error);

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
@property(nonatomic)STPBillingAddressFields requiredBillingAddressFields;

@property(nonatomic, weak, nullable)id<STPPaymentContextDelegate> delegate;
@property(nonatomic, readonly, getter=isLoading)BOOL loading;
@property(nonatomic, readonly)id<STPPaymentMethod> selectedPaymentMethod;
@property(nonatomic, readonly)NSArray<id<STPPaymentMethod>> *paymentMethods;

@property(nonatomic)NSInteger paymentAmount;
@property(nonatomic)NSString *paymentCurrency;
@property(nonatomic)NSString *merchantName;
@property(nonatomic)NSString *appleMerchantIdentifier;

- (void)performInitialLoad;
- (void)requestPaymentFromViewController:(UIViewController *)fromViewController
                           sourceHandler:(STPSourceHandlerBlock)sourceHandler
                              completion:(STPPaymentCompletionBlock)completion;


@end

typedef void (^STPAddTokenBlock)(id<STPPaymentMethod> __nullable paymentMethod, NSError * __nullable error);

@interface STPPaymentContext(Internal)
- (void)onSuccess:(STPVoidBlock)completion;
- (void)addToken:(STPToken *)token completion:(STPAddTokenBlock)completion;
- (void)selectPaymentMethod:(id<STPPaymentMethod>)paymentMethod;
@end

NS_ASSUME_NONNULL_END
