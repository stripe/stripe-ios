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

@class STPPaymentCoordinator, STPAPIClient, STPPaymentResult;

@protocol STPPaymentCoordinatorDelegate

- (void)paymentCoordinator:(STPPaymentCoordinator *)coordinator
    didCreatePaymentResult:(STPPaymentResult *)result
                completion:(STPErrorBlock)completion;

- (void)paymentCoordinator:(STPPaymentCoordinator *)coordinator
          didFailWithError:(NSError *)error;

- (void)paymentCoordinatorDidCancel:(STPPaymentCoordinator *)coordinator;

- (void)paymentCoordinatorDidSucceed:(STPPaymentCoordinator *)coordinator;


@end

@interface STPPaymentCoordinator : NSObject

- (instancetype)initWithPaymentRequest:(PKPaymentRequest *)paymentRequest
                             apiClient:(STPAPIClient *)apiClient
                              delegate:(id<STPPaymentCoordinatorDelegate>)delegate;

@property(nonatomic, readonly)UIViewController *paymentViewController;

@end
