//
//  STPBaseCoordinator.m
//  Stripe
//
//  Created by Jack Flintermann on 3/28/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPBaseCoordinator.h"

@interface STPBaseCoordinator()
@property(nonatomic) NSMutableArray<STPBaseCoordinator *> *childCoordinators;
@end

@implementation STPBaseCoordinator

- (instancetype)init {
    self = [super init];
    if (self) {
        _childCoordinators = [@[] mutableCopy];
    }
    return self;
}


- (void)begin {
    // override me
}

- (void)addChildCoordinator:(STPBaseCoordinator *)coordinator {
    [self.childCoordinators addObject:coordinator];
}

- (void)removeChildCoordinator:(STPBaseCoordinator *)coordinator {
    [self.childCoordinators removeObject:coordinator];
}

@end
