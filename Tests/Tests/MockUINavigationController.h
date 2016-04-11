//
//  MockUINavigationController.h
//  Stripe
//
//  Created by Ben Guo on 4/11/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MockUINavigationController : UINavigationController

@property (nonatomic, copy, nullable) void(^onPushViewController)(UIViewController *__nonnull, BOOL animated);
@property (nonatomic, copy, nullable) void(^onPopViewController)(BOOL animated);

@end
