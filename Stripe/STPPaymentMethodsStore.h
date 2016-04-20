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

@protocol STPBackendAPIAdapter;
@class STPPaymentMethodsStore;

@protocol STPPaymentMethodsStoreDelegate <NSObject>

- (void)paymentMethodsStoreDidUpdate:(STPPaymentMethodsStore *)store;

@end

@interface STPPaymentMethodsStore : NSObject

@property(nonatomic, readwrite)id<STPPaymentMethod>selectedPaymentMethod;
@property(nonatomic, readwrite)NSArray<id<STPPaymentMethod>>* paymentMethods;

- (instancetype)initWithSupportedPaymentMethods:(STPPaymentMethodType)supportedPaymentMethods
                                     apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter;
- (void)loadSources:(STPErrorBlock)completion;

@end
