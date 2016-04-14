//
//  STPBaseCoordinator.h
//  Stripe
//
//  Created by Jack Flintermann on 3/28/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPBlocks.h"

@class STPBaseCoordinator, STPAPIClient;
@protocol STPSourceProvider;

@protocol STPCoordinatorDelegate
- (void)coordinatorDidCancel:(STPBaseCoordinator *)coordinator;
- (void)coordinator:(STPBaseCoordinator *)coordinator willFinishWithCompletion:(STPErrorBlock)completion;
@end

@interface STPBaseCoordinator : NSObject

- (void)addChildCoordinator:(STPBaseCoordinator *)coordinator;
- (void)removeChildCoordinator:(STPBaseCoordinator *)coordinator;
- (void)begin;

@end
