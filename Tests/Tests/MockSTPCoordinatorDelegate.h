//
//  MockSTPCoordinatorDelegate.h
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/29/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPBaseCoordinator.h"

@interface MockSTPCoordinatorDelegate : NSObject <STPCoordinatorDelegate>

@property (nonatomic, copy, nullable) void(^onDidCancel)();
@property (nonatomic, copy, nullable) void(^onWillFinishWithCompletion)(STPErrorBlock __nonnull);

@end
