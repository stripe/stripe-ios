//
//  STPBaseCoordinator.m
//  Stripe
//
//  Created by Jack Flintermann on 3/28/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPBaseCoordinator.h"

@interface STPBaseCoordinator()
@property(nonatomic, weak)id<STPCoordinatorDelegate>delegate;
@end

@implementation STPBaseCoordinator

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
                                   apiClient:(STPAPIClient *)apiClient
                              sourceProvider:(id<STPSourceProvider>)sourceProvider
                                    delegate:(id<STPCoordinatorDelegate>)delegate {
    self = [super init];
    if (self) {
        _navigationController = navigationController;
        _apiClient = apiClient;
        _sourceProvider = sourceProvider;
        _delegate = delegate;
    }
    return self;
}


- (void)begin {
    // override me
}

@end
