//
//  CardSetupIntentBackendExampleViewController.h
//  Custom Integration
//
//  Created by Cameron Sabol on 7/17/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ExampleViewControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface CardSetupIntentBackendExampleViewController : UIViewController

@property (nonatomic, weak) id<ExampleViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
