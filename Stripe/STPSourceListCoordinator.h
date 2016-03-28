//
//  STPSourceListCoordinator.h
//  Stripe
//
//  Created by Jack Flintermann on 3/28/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPAPIClient, STPSourceListCoordinator;
@protocol STPSourceProvider;

@protocol STPSourceListCoordinatorDelegate
- (void)sourceListCoordinatorDidFinish:(STPSourceListCoordinator *)coordinator;
@end

@interface STPSourceListCoordinator : NSObject

@property(nonatomic, readonly)UINavigationController *navigationController;
@property(nonatomic, readonly)STPAPIClient *apiClient;
@property(nonatomic, readonly)id<STPSourceProvider> sourceProvider;
@property(nonatomic, weak, readonly)id<STPSourceListCoordinatorDelegate> delegate;

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
                                   apiClient:(STPAPIClient *)apiClient
                              sourceProvider:(id<STPSourceProvider>)sourceProvider
                                    delegate:(id<STPSourceListCoordinatorDelegate>)delegate;

- (void)showSourceList;

@end
