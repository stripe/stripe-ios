//
//  STPPaymentAuthorizationCoordinator.h
//  Stripe
//
//  Created by Jack Flintermann on 3/28/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPBaseCoordinator.h"
#import "STPPaymentRequest.h"

@interface STPPaymentAuthorizationCoordinator : STPBaseCoordinator

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
                              paymentRequest:(STPPaymentRequest *)paymentRequest
                                   apiClient:(STPAPIClient *)apiClient
                              sourceProvider:(id<STPSourceProvider>)sourceProvider
                                    delegate:(id<STPCoordinatorDelegate>)delegate;

@end
