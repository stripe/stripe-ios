//
//  MockSTPAddCardViewControllerDelegate.h
//  Stripe
//
//  Created by Ben Guo on 7/5/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAddCardViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MockSTPAddCardViewControllerDelegate : NSObject<STPAddCardViewControllerDelegate>
@property (nonatomic, copy, nullable) void(^onDidCreateToken)(STPToken *token, _Nullable STPErrorBlock completion);
@property (nonatomic, copy, nullable) void(^onDidCancel)();
@end

NS_ASSUME_NONNULL_END
