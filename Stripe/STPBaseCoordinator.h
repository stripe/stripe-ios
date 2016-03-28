//
//  STPBaseCoordinator.h
//  Stripe
//
//  Created by Jack Flintermann on 3/28/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STPBaseCoordinator;

@protocol STPCoordinatorDelegate
- (void)coordinatorDidFinish:(STPBaseCoordinator *)coordinator;
@end

@interface STPBaseCoordinator : NSObject

@property(nonatomic, weak, readonly)id<STPCoordinatorDelegate>delegate;

- (instancetype)initWithDelegate:(id<STPCoordinatorDelegate>)delegate;
- (void)begin;

@end
