//
//  CardSetupIntentExampleViewController.h
//  Custom Integration
//
//  Created by Yuki Tokuhiro on 7/1/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ExampleViewControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface CardSetupIntentExampleViewController : UIViewController

@property (nonatomic, weak) id<ExampleViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
