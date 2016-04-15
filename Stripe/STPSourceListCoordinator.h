//
//  STPSourceListCoordinator.h
//  Stripe
//
//  Created by Jack Flintermann on 3/28/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPBaseCoordinator.h"

@interface STPSourceListCoordinator : STPBaseCoordinator

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
                                   apiClient:(STPAPIClient *)apiClient
                              apiAdapter:(id<STPBackendAPIAdapter>)apiAdapter
                                    delegate:(id<STPCoordinatorDelegate>)delegate;

@end
