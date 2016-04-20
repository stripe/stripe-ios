//
//  STPPaymentMethodsStore.h
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPPaymentMethod.h"
#import "STPBlocks.h"
#import "STPAPIClient.h"

@protocol STPBackendAPIAdapter;
@class STPPaymentMethodStore;

@protocol STPPaymentMethodStoreDelegate <NSObject>

- (void)paymentMethodStoreDidUpdate:(STPPaymentMethodStore *)store;

@end

@interface STPPaymentMethodStore : NSObject

@property(nonatomic, readonly)STPAPIClient *apiClient;
@property(nonatomic, readwrite)id<STPPaymentMethod>selectedPaymentMethod;
@property(nonatomic, readwrite)NSArray<id<STPPaymentMethod>>* paymentMethods;

- (instancetype)initWithSupportedPaymentMethods:(STPPaymentMethodType)supportedPaymentMethods
                                      apiClient:(STPAPIClient *)apiClient
                                     apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter;
- (void)loadSources:(STPErrorBlock)completion;

@end
