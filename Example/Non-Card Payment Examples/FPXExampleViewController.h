//
//  FPXExampleViewController.h
//  Non-Card Payment Examples
//
//  Created by David Estes on 8/26/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ExampleViewControllerDelegate;

@interface FPXExampleViewController : UIViewController

@property (nonatomic, weak) id<ExampleViewControllerDelegate> delegate;

@end
