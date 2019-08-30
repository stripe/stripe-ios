//
//  WeChatPayExampleViewController.h
//  Custom Integration
//
//  Created by Yuki Tokuhiro on 8/6/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ExampleViewControllerDelegate;

@interface WeChatPayExampleViewController : UIViewController

@property (nonatomic, weak) id<ExampleViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
