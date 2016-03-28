//
//  STPBaseCoordinator.h
//  Stripe
//
//  Created by Jack Flintermann on 3/28/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPBaseCoordinator, STPAPIClient;
@protocol STPSourceProvider;

@protocol STPCoordinatorDelegate
- (void)coordinatorDidFinish:(STPBaseCoordinator *)coordinator;
@end

@interface STPBaseCoordinator : NSObject

@property(nonatomic, weak, readonly)id<STPCoordinatorDelegate>delegate;
@property(nonatomic, readonly)UINavigationController *navigationController;
@property(nonatomic, readonly)STPAPIClient *apiClient;
@property(nonatomic, readonly)id<STPSourceProvider> sourceProvider;

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
                                   apiClient:(STPAPIClient *)apiClient
                              sourceProvider:(id<STPSourceProvider>)sourceProvider
                                    delegate:(id<STPCoordinatorDelegate>)delegate;

- (void)begin;

@end
