//
//  STPPaymentCoordinator.h
//  Stripe
//
//  Created by Jack Flintermann on 4/6/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "STPBlocks.h"

@class STPAPIClient, STPPaymentRequest;
@protocol STPBackendAPIAdapter;

@interface STPPaymentCoordinator : NSObject

- (instancetype)initWithSupportedPaymentMethods:(STPPaymentMethodType)supportedPaymentMethods
                                      apiClient:(STPAPIClient *)apiClient
                                     apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter;

- (void)performPaymentRequest:(STPPaymentRequest *)request
           fromViewController:(UIViewController *)fromViewController
                sourceHandler:(STPSourceHandlerBlock)sourceHandler
                   completion:(STPPaymentCompletionBlock)completion;

@end
